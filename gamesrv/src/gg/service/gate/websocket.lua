--- websocket网关
--@script gg.service.gate.websocket
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
--	local websocket_port = skynet.getenv("websocket_port")
--	gate_conf.port = websocket_port
--	-- 启动websocket_gate服务
--	local websocket_gate = skynet.uniqueservice("gg/service/gate/websocket")
--
--	通信
--	websocket_gate -> watchdog
--	1. 新建连接
--		skynet.send(watchdog,"lua","client","onconnect","websocket",linkid,addr)
--	2. 关闭连接
--		skynet.send(watchdog,"lua","client","onclose",linkid)
--	3. 收到消息时转发给watchdog
--		skynet.send(watchdog,"lua","client","onmessage",linkid,message)
--	4. 告知watchdog成为某个连接的辅助连接
--		skynet.send(watchdog,"lua","client","saveof",master_linkid,slave_linkid)
--
--	watchdog -> websocket_gate
----1. 监听端口
--		skynet.call(websocket_gate,"lua","open",gate_conf)
--	2. 向某连接发送数据
--		skynet.send(websocket_gate,"lua","write",linkid,message)
--	3. 关闭连接
--		skynet.send(websocket_gate,"lua","close",linkid)
--	4. 热更协议
--		skynet.send(websocket_gate,"lua","reload")
----5. 转发协议到其他服务(默认是发到watchdog)
--		skynet.send(tcp_gate,"lua","forward",proto,address)
--
--	备注: linkid: websocket连接ID,addr: 客户端地址,message: 消息

local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local websocket = require "websocket.server"
local codec = require "gg.codec.codec"
local handshake = require "gg.service.gate.handshake"

local connection = {}
local client_number = 0
local maxclient
local msg_max_len
local watchdog
local timeout		-- 1/100s为单位
local encrypt_key
local send_binary
local codecobj
local forward_protos = {}
local handler = {}

local function send_message(ws,data)
	if send_binary then
		return ws:send_binary(data)
	else
		return ws:send_text(data)
	end
end

function handler.check_timeout(linkid)
	local ws = connection[linkid]
	if not ws then
		return
	end
	skynet.timeout(500,function ()
		handler.check_timeout(linkid)
	end)
	local now = skynet.now()
	if now - ws.active >= timeout then
		ws:close(1000,"timeout close")
	end
end

function handler.on_open(ws)
	local linkid = ws.linkid
	local addr = ws.addr
	if client_number >= maxclient then
		skynet.error(string.format("op=overlimit,linktype=websocket,linkid=%s,addr=%s:%s,client_number=%s,maxclient=%s",
		linkid,addr,client_number,maxclient))
		ws:close(1000,"overlimit")
		return
	end
	client_number = client_number + 1
	connection[linkid] = ws
	skynet.error(string.format("op=onconnect,linktype=websocket,linkid=%s,addr=%s",linkid,addr))
	skynet.send(watchdog,"lua","client","onconnect","websocket",linkid,addr)
	if timeout > 0 then
		ws.active = skynet.now()
		handler.check_timeout(linkid)
	end
	if encrypt_key then
		send_message(ws,handshake.pack_challenge(ws,encrypt_key))
	else
		ws.handshake_result = "OK"
	end
end

function handler._on_message(ws,msg)
	local linkid = ws.linkid
	if not ws.handshake_result then
		local ok,errmsg = handshake.do_handshake(ws,msg)
		if ws.handshake_result then
			send_message(ws,handshake.pack_result(ws,ws.handshake_result))
			if ws.handshake_result == "OK" and ws.master_linkid then
				skynet.error(string.format("op=slaveof,linktype=websocket,master=%s,slave=%s",ws.master_linkid,ws.linkid))
				skynet.send(watchdog,"lua","client","slaveof",ws.master_linkid,ws.linkid)
			end
		end
		if not ok then
			skynet.error(string.format("op=handshake,linktype=websocket,linkid=%s,addr=%s,errmsg=%s",linkid,ws.addr,errmsg))
			-- 1000  "normal closure" status code
			ws:close(1000,"handshake fail")
		end
		return
	end
	ws.active = skynet.now()
	local secret = ws.secret
	if secret then
		msg = crypt.xor_str(msg,secret)
	end
	local message = codecobj:unpack_message(msg)
	local address = forward_protos[message.proto] or watchdog
	skynet.send(address,"lua","client","onmessage",linkid,message)
end

function handler.on_message(ws,msg)
	xpcall(handler._on_message,skynet.error,ws,msg)
end

function handler.on_close(ws,code,reason)
	local linkid = ws.linkid
	if not connection[linkid] then
		return
	end
	client_number = client_number - 1
	connection[linkid] = nil
	skynet.error(string.format("op=onclose,linktype=websocket,linkid=%s,code=%s,reason=%s",linkid,code,reason))
	skynet.send(watchdog,"lua","client","onclose",linkid)
end

function handler.on_ping(ws,message)
	--print("on_ping",ws.linkid,message)
	ws.active = skynet.now()
	ws:send_pong(message)
end

function handler.on_pong(ws,message)
	--print("on_pong",ws.linkid,message)
	ws.active = skynet.now()
end

local CMD = {}

function CMD.open(conf)
	-- 多长时间(单位:1/100秒)未收到客户端协议,则主动断开该客户端连接
	timeout = conf.timeout or 0
	watchdog = assert(conf.watchdog)
	encrypt_key = conf.encrypt_key
	send_binary = conf.send_binary and true or false
	codecobj = codec.new(conf.proto)
	msg_max_len = assert(conf.msg_max_len)
	maxclient = assert(conf.maxclient)
	local port = assert(conf.port)
	local ip = conf.ip or "0.0.0.0"
	local id = assert(socket.listen(ip,port))
	skynet.error("Websocket listen on",ip,port)
	socket.start(id,function (linkid,addr)
		socket.start(linkid)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(linkid), 8192)
		if code == 200 then
			if header.upgrade == "websocket" then
				local ws,err = websocket:new({
					sock = linkid,
					headers = header,
					max_payload_len = msg_max_len,
					send_masked = false,
				})
				if ws then
					ws.linkid = linkid
					ws.addr = addr
					ws:start(handler)
				else
					httpd.write_response(sockethelper.writefunc(linkid),400,err)
					socket.close(linkid)
				end
			end
		else
			socket.close(linkid)
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
	local ws = connection[linkid]
	if not ws then
		return
	end
	local msg = codecobj:pack_message(message)
	local secret = ws.secret
	if secret then
		msg = crypt.xor_str(msg,secret)
	end
	send_message(ws,msg)
end

function CMD.close(linkid)
	local ws = connection[linkid]
	if not ws then
		return
	end
    -- 1000  "normal closure" status code
	ws:close(1000,"server close")
end

skynet.start(function ()
	skynet.dispatch("lua",function (session,source,cmd,...)
		local func = CMD[cmd]
		func(...)
	end)
end)

