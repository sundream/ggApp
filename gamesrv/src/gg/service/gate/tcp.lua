--- tcp网关
--@script gg.service.gate.tcp
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
--	local tcp_port = skynet.getenv("tcp_port")
--	gate_conf.port = tcp_port
--	-- 启动tcp_gate服务
--	local tcp_gate = skynet.uniqueservice("gg/service/gate/tcp")
--
--	通信
--	tcp_gate -> watchdog
--	1. 新建连接
--		skynet.send(watchdog,"lua","client","onconnect","tcp",linkid,addr)
--	2. 关闭连接
--		skynet.send(watchdog,"lua","client","onclose",linkid)
--	3. 收到消息时转发给watchdog
--		skynet.send(watchdog,"lua","client","onmessage",linkid,message)
--	4. 告知watchdog成为某个连接的辅助连接
--		skynet.send(watchdog,"lua","client","saveof",master_linkid,slave_linkid)
--
--	watchdog -> tcp_gate
----1. 监听端口
--		skynet.call(tcp_gate,"lua","open",gate_conf)
--	2. 向某连接发送数据
--		skynet.send(tcp_gate,"lua","write",linkid,message)
--	3. 关闭连接
--		skynet.send(tcp_gate,"lua","close",linkid)
--	4. 热更协议
--		skynet.send(tcp_gate,"lua","reload")
----5. 转发协议到其他服务(默认是发到watchdog)
--		skynet.send(tcp_gate,"lua","forward",proto,address)
--
--	备注: linkid: 连接ID,addr: 客户端地址,message: 消息
--	包格式: 2字节长度(大端)+消息体(消息体编码由配置决定,如protobuf/sproto等,
--	另外加密也只对消息体加密)
--	分包用到了skynet_package,see https://github.com/cloudwu/skynet_package

local skynet = require "skynet"
local socket = require "skynet.socket"
local socket_proxy = require "socket_proxy"
local crypt = require "skynet.crypt"
local codec = require "gg.codec.codec"
local handshake = require "gg.service.gate.handshake"

local connection = {}
local client_number = 0
local maxclient
local msg_max_len
local watchdog
local timeout		-- 1/100s为单位
local encrypt_key
local codecobj
local forward_protos = {}
local handler = {}

local socket_start = socket_proxy.subscribe
local socket_read = function (linkid)
	local ok,msg,sz = pcall(socket_proxy.read,linkid)
	if not ok then
		return false
	end
	return true,skynet.tostring(msg,sz)
end
local socket_write = socket_proxy.write
local socket_close = socket_proxy.close

function handler.onconnect(linkid,addr)
	if client_number >= maxclient then
		skynet.error(string.format("op=overlimit,linktype=tcp,linkid=%s,addr=%s,client_number=%s,maxclient=%s",
		linkid,addr,client_number,maxclient))
		socket_close(linkid)
		return
	end
	client_number = client_number + 1
	local agent = {
		addr = addr,
		linkid = linkid,
	}
	connection[linkid] = agent
	skynet.error(string.format("op=onconnect,linktype=tcp,linkid=%s,addr=%s",linkid,addr))
	skynet.send(watchdog,"lua","client","onconnect","tcp",linkid,addr)
	if encrypt_key then
		socket_write(linkid,handshake.pack_challenge(agent,encrypt_key))
	else
		agent.handshake_result = "OK"
	end
end

function handler.onclose(linkid)
	if not connection[linkid] then
		return
	end
	client_number = client_number - 1
	connection[linkid] = nil
	skynet.error(string.format("op=onclose,linktype=tcp,linkid=%s",linkid))
	skynet.send(watchdog,"lua","client","onclose",linkid)
end

function handler.onmessage(linkid,msg)
	local agent = connection[linkid]
	if not agent then
		return
	end
	if not agent.handshake_result then
		local ok,errmsg = handshake.do_handshake(agent,msg)
		if agent.handshake_result then
			socket_write(linkid,handshake.pack_result(agent,agent.handshake_result))
			if agent.handshake_result == "OK" and agent.master_linkid then
				skynet.error(string.format("op=slaveof,linktype=tcp,master=%s,slave=%s",agent.master_linkid,agent.linkid))
				skynet.send(watchdog,"lua","client","slaveof",agent.master_linkid,agent.linkid)
			end
		end
		if not ok then
			skynet.error(string.format("op=handshake,linktype=tcp,linkid=%s,addr=%s,errmsg=%s",linkid,agent.addr,errmsg))
			socket_close(linkid)
		end
		return
	end
	local secret = agent.secret
	if secret then
		msg = crypt.xor_str(msg,secret)
	end
	local message = codecobj:unpack_message(msg)
	local address = forward_protos[message.proto] or watchdog
	skynet.send(address,"lua","client","onmessage",linkid,message)
end

local CMD = {}

function CMD.open(conf)
	-- 多长时间(单位:1/100秒)未收到客户端协议,则主动断开该客户端连接
	timeout = conf.timeout or 0
	watchdog = assert(conf.watchdog)
	encrypt_key = conf.encrypt_key
	codecobj = codec.new(conf.proto)
	msg_max_len = assert(conf.msg_max_len)
	maxclient = assert(conf.maxclient)
	local port = assert(conf.port)
	local ip = conf.ip or "0.0.0.0"
	local id = assert(socket.listen(ip,port))
	skynet.error("Tcp listen on",ip,port)
	socket.start(id,function (linkid,addr)
		socket_start(linkid,timeout)
		handler.onconnect(linkid,addr)
		if not connection[linkid] then
			return
		end
		while true do
			local ok,msg = socket_read(linkid)
			if not ok then
				handler.onclose(linkid)
				break
			end
			xpcall(handler.onmessage,skynet.error,linkid,msg)
		end
	end)
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
	socket_write(linkid,msg)
end

function CMD.close(linkid)
	if not connection[linkid] then
		return
	end
	socket_close(linkid)
end

skynet.start(function ()
	skynet.dispatch("lua",function (session,source,cmd,...)
		local func = CMD[cmd]
		func(...)
	end)
end)
