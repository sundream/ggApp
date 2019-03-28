--- kcp网关
--@script gg.service.gate.kcp
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--	-- sproto
--	local proto = {
--		type = "sproto",
--		c2s = "../src/proto/sproto/all.spb",
--		s2c = "../src/proto/sproto/all.spb",
--		binary = true,
--	}
--	-- protobuf
--	local proto = {
--		type = "protobuf",
--		pbfile = "../src/proto/protobuf/all.pb",
--		idfile = "../src/proto/protobuf/message_define.lua",
--	}
--	-- json
--	local proto = {
--		type = "json"
--	}
--	local gate_conf = {
--		watchdog = address,		-- 主服地址
--		proto = proto,			-- 使用的编码协议
--		encrypt_key = encrypt_key, -- 协议加解密密钥
--		timeout = timeout,			-- 多长时间(1/100秒为单位),自动关闭不活跃的连接
--		msg_max_len = msg_max_len,	-- 最大消息长度
--		maxclient = maxclient,		-- 最大连接个数
--	}
--	local kcp_port = skynet.getenv("kcp_port")
--	gate_conf.port = kcp_port
--	-- 启动kcp_gate服务,监听kcp_port端口
--	local kcp_gate = skynet.uniqueservice("gg/service/gate/kcp")
--
--	通信
--	kcp_gate -> watchdog
----1. 新建连接
--		skynet.send(watchdog,"lua","client","onconnect","kcp",linkid,addr)
--	2. 关闭连接(绑定关系也会自动解除)
--		skynet.send(watchdog,"lua","client","onclose",linkid)
--	3. 收到消息时转发给watchdog
--		skynet.send(watchdog,"lua","client","onmessage",linkid,message)
----4. 告知watchdog成为某个连接的辅助连接
--		skynet.send(watchdog,"lua","client","saveof",master_linkid,slave_linkid)
--
--	watchdog -> kcp_gate
----1. 监听端口(底层用udp通信)
--		skynet.call(kcp_gate,"lua","open",gate_conf)
--	2. 向某连接发送数据
--		skynet.send(kcp_gate,"lua","write",linkid,message)
--	3. 关闭连接
--		skynet.send(kcp_gate,"lua","close",linkid)
--	4. 热更协议
--		skynet.send(kcp_gate,"lua","reload")
----5. 转发协议到其他服务(默认是发到watchdog)
--		skynet.send(kcp_gate,"lua","forward",proto,address)
--
--	备注: linkid: 连接ID,addr: 客户端地址,message: 消息

--	kcp会话管理,格式: 1byte协议类别+具体协议参数
--	协议类别:
--	SYN = 1		// 连接(connect)
--		4byte 主动连接方连接ID
--	ACK = 2		// 接受连接(accept)
--		4byte 接受连接方ID
--		4byte 被接受方连接ID
--	FIN = 3		// 断开连接(disconnect)
--		4byte 主动断开方连接ID
--		4byte 被动断开方连接ID
--		4byte errcode
--	MSG = 4		// 消息包(send/recv)
--		4byte 发消息方连接ID
--		kcp_msg

local skynet = require "skynet"
local socket = require "skynet.socket"
local lkcp = require "lkcp"
local crypt = require "skynet.crypt"
local lutil = require "lutil"
local codec = require "gg.codec.codec"
local handshake = require "gg.service.gate.handshake"

local bind_socket
local connection = {}
local client_number = 0
local maxclient
local msg_max_len
local watchdog
local timeout		-- 1/100s为单位
local encrypt_key
local codecobj
local kcp_linkid = 0
local forward_protos = {}

local function getms()
	--return math.floor(skynet.time() * 1000) & 0xffffffff
	return lutil.getms()
end

local KcpProtoType = {
	SYN = 1,
	ACK = 2,
	FIN = 3,
	MSG = 4,
}

local function udp_send_ack(from,my_linkid,endpoint_linkid)
	local buffer = string.pack("<Bi4i4",KcpProtoType.ACK,my_linkid,endpoint_linkid)
	socket.sendto(bind_socket,from,buffer)
end

local function udp_send_close(from,my_linkid,endpoint_linkid,cnt)
	cnt = cnt or 1
	local errcode = 0
	local buffer = string.pack("<Bi4i4i4",KcpProtoType.FIN,my_linkid,endpoint_linkid,errcode)
	socket.sendto(bind_socket,from,buffer)
	cnt = cnt - 1
	if cnt > 0 then
		skynet.timeout(50,function ()
			udp_send_close(from,my_linkid,endpoint_linkid,cnt)
		end)
	end
end

local function udp_send_kcpmsg(from,my_linkid,buffer)
	local buffer = string.pack("<Bi4",KcpProtoType.MSG,my_linkid) .. buffer
	socket.sendto(bind_socket,from,buffer)
end

local function udp_send_ack_until_confirm(from,my_linkid,endpoint_linkid)
	local agent = connection[my_linkid]
	if not agent then
		return
	end
	if not agent.unconfirm or (skynet.now() - agent.unconfirm > 500) then
		return
	end
	udp_send_ack(from,my_linkid,endpoint_linkid)
	skynet.timeout(50,function ()
		udp_send_ack_until_confirm(from,my_linkid,endpoint_linkid)
	end)
end

local function socket_close(my_linkid,reason)
	local agent = connection[my_linkid]
	if not agent then
		return
	end
	local from = agent.addr
	local endpoint_linkid = agent.endpoint_linkid
	local kcp = agent.kcp
	kcp:lkcp_flush()
	client_number = client_number - 1
	connection[from] = nil
	connection[my_linkid] = nil
	local ip,port = socket.udp_address(from)
	skynet.error(string.format("op=onclose,linktype=kcp,linkid=%s,endpoint_linkid=%s,addr=%s:%s,reason=%s",my_linkid,endpoint_linkid,ip,port,reason))
	skynet.send(watchdog,"lua","client","onclose",agent.linkid)
	udp_send_close(from,my_linkid,endpoint_linkid,3)
end

local handler = {}

function handler.recv_message(agent)
	local kcp = agent.kcp
	local len,msg = kcp:lkcp_recv()
	if len > 0 then
		if not agent.handshake_result then
			local ok,errmsg = handshake.do_handshake(agent,msg)
			if agent.handshake_result then
				kcp:lkcp_send(handshake.pack_result(agent,agent.handshake_result))
				if agent.handshake_result == "OK" and agent.master_linkid then
					skynet.error(string.format("op=slaveof,linktype=kcp,master=%s,slave=%s",agent.master_linkid,agent.linkid))
					skynet.send(watchdog,"lua","client","slaveof",agent.master_linkid,agent.linkid)
				end
			end
			if not ok then
				skynet.error(string.format("op=handshake,linktype=kcp,linkid=%s,addr=%s:%s,errmsg=%s",agent.linkid,agent.ip,agent.port,errmsg))
				socket_close(agent.linkid,"handshake fail")
			end
		else
			local secret = agent.secret
			if secret then
				msg = crypt.xor_str(msg,secret)
			end
			local message = codecobj:unpack_message(msg)
			local address = forward_protos[message.proto] or watchdog
			skynet.send(address,"lua","client","onmessage",agent.linkid,message)
		end
	end
	return len
end

function handler.tick(now)
	local skynet_now = skynet.now()
	for linkid,agent in pairs(connection) do
		if type(linkid) == "number" then
			local kcp = agent.kcp
			if timeout > 0 and (skynet_now - agent.active >= timeout) then
				socket_close(linkid,"timeout close")
			else
				local nexttime = kcp:lkcp_check(now)
				if nexttime <= now then
					kcp:lkcp_update(now)
				end
				while true do
					local ok,len = xpcall(handler.recv_message,skynet.error,agent)
					if not ok then
						break
					end
					if len <= 0 then
						break
					end
				end
			end
		end
	end
end

function handler.dispatch_connection()
	skynet.fork(function ()
		while true do
			skynet.sleep(1)
			handler.tick(getms())
		end
	end)
end

function handler.dispatch_message(from,msg)
	local ctrl = string.unpack("<B",msg,1)
	if ctrl == KcpProtoType.SYN then
		handler.onconnect(from,msg)
	elseif ctrl == KcpProtoType.FIN then
		handler.onclose(from,msg)
	elseif ctrl == KcpProtoType.MSG then
		handler.onmessage(from,msg)
	end
end

function handler.onconnect(from,msg)
	if connection[from] then
		return
	end
	local len = #msg
	if len ~= 5 then
		return
	end
	local ip,port = socket.udp_address(from)
	local endpoint_linkid = string.unpack("<i4",msg,2)
	if client_number >= maxclient then
		skynet.error(string.format("op=overlimit,linktype=kcp,addr=%s:%s,client_number=%s,maxclient=%s",ip,port,client_number,maxclient))
		udp_send_close(from,0,endpoint_linkid,3)
		return
	end
	local kcp_log = nil --function (log) print(log) end
	if kcp_linkid == -2^31 then
		kcp_linkid = 0
	end
	kcp_linkid = kcp_linkid - 1
	local linkid = kcp_linkid
	local kcp = lkcp.lkcp_create(linkid,function (buffer)
		local agent = connection[linkid]
		if not agent then
			return
		end
		udp_send_kcpmsg(from,agent.linkid,buffer)
	end,kcp_log)
	--kcp:lkcp_logmask(0xffffffff)
	kcp:lkcp_nodelay(1,10,2,1)
	kcp:lkcp_wndsize(256,256)
	kcp:lkcp_setmtu(470)
	client_number = client_number + 1
	skynet.error(string.format("op=onconnect,linktype=kcp,linkid=%s,endpoint_linkid=%s,addr=%s:%s",linkid,endpoint_linkid,ip,port))
	local agent = {
		endpoint_linkid = endpoint_linkid,
		linkid = linkid,
		kcp = kcp,
		active = skynet.now(),
		unconfirm = skynet.now(),
		addr = from,
		ip = ip,
		port = port,
	}
	connection[from] = agent
	connection[linkid] = agent
	udp_send_ack_until_confirm(from,linkid,endpoint_linkid)
	skynet.send(watchdog,"lua","client","onconnect","kcp",agent.linkid,from)
	if encrypt_key then
		kcp:lkcp_send(handshake.pack_challenge(agent,encrypt_key))
	else
		agent.handshake_result = "OK"
	end
end

function handler.onclose(from,msg)
	local len = #msg
	if len < 9 then
		return
	end
	local endpoint_linkid = string.unpack("<i4",msg,2)
	local my_linkid = string.unpack("<i4",msg,6)
	--local errcode = string.unpack("<i4",msg,10)
	local agent = connection[my_linkid]
	if not agent then
		return
	end
	if agent.linkid ~= my_linkid or
		agent.endpoint_linkid ~= endpoint_linkid then
		return
	end
	socket_close(my_linkid,"client close")
end

function handler.onmessage(from,msg)
	local len = #msg
	if len < 9 then
		return
	end
	local endpoint_linkid = string.unpack("<i4",msg,2)
	local my_linkid = string.unpack("<i4",msg,6)
	local agent = connection[my_linkid]
	if not agent then
		-- 可能原因: 1. 未建立连接就收到消息 2. 服务端关闭连接后,通知客户端关闭包丢失了
		udp_send_close(from,my_linkid,endpoint_linkid)
		return
	end
	if agent.linkid ~= my_linkid or
		agent.endpoint_linkid ~= endpoint_linkid then
		return
	end
	msg = string.sub(msg,6)
	agent.unconfirm = nil
	agent.active = skynet.now()
	local kcp = agent.kcp
	kcp:lkcp_input(msg)
end

local CMD = {}

function CMD.open(conf)
	timeout = conf.timeout or 60
	watchdog = assert(conf.watchdog)
	encrypt_key = conf.encrypt_key
	codecobj = codec.new(conf.proto)
	msg_max_len = assert(conf.msg_max_len)
	maxclient = assert(conf.maxclient)
	local port = assert(conf.port)
	local ip = conf.ip or "0.0.0.0"
	bind_socket = assert(socket.udp(function (msg,from)
		handler.dispatch_message(from,msg)
	end,ip,port))
	skynet.error("Kcp bind",ip,port)
	handler.dispatch_connection()
	skynet.retpack()
end

function CMD.reload()
	codecobj:reload()
end

function CMD.forward(proto,address)
	forward_protos[proto] = address
end

function CMD.write(linkid,message)
	local agent = connection[linkid]
	if not agent then
		return
	end
	local msg = codecobj:pack_message(message)
	local secret = agent.secret
	if secret then
		msg = crypt.xor_str(msg,secret)
	end
	assert(#msg <= msg_max_len)
	local kcp = agent.kcp
	kcp:lkcp_send(msg)
end

function CMD.close(linkid)
	socket_close(linkid,"server close")
end

skynet.start(function ()
	skynet.dispatch("lua",function (session,source,cmd,...)
		local func = CMD[cmd]
		func(...)
	end)
end)

