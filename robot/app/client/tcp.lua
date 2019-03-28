local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local socket_proxy = require "socket_proxy"
local config = require "app.config.custom"
local handshake = require "app.client.handshake"
require "app.codec.init"

local tcp = {}
local mt = {__index = tcp}

function tcp.new(opts)
	local codecobj = codec.new(config.proto)
	local self = {
		linkid = nil,
		linktype = "tcp",
		session = 0,
		sessions = {},
		wait_proto = {},
		secret = nil,	-- 密钥

		codec = codecobj,
		handler = opts.handler,
	}
	if config.no_handshake then
		self.handshake_result = "OK"
	end
	return setmetatable(self,mt)
end

function tcp:connect(host,port)
	local linkid = socket.open(host,port)
	self.linkid = linkid
	socket_proxy.subscribe(linkid,0)
	if self.handler.onconnect then
		self.handler.onconnect(self)
	end
	skynet.timeout(0,function ()
		self:dispatch_message()
	end)
end

function tcp:dispatch_message()
	while true do
		local ok,msg,sz = pcall(socket_proxy.read,self.linkid)
		if not ok then
			if self.handler.onclose then
				self.handler.onclose(self)
			end
			break
		end
		msg = skynet.tostring(msg,sz)
		xpcall(self.recv_message,skynet.error,self,msg)
	end
end
function tcp:recv_message(msg)
	self:onmessage(msg)
end

function tcp:close()
	socket_proxy.close(self.linkid)
end

function tcp:quite()
	self.verbose = not self.verbose
end

function tcp:say(...)
	skynet.error(string.format("[linktype=%s,linkid=%s]",self.linktype,self.linkid),...)
end

function tcp:onmessage(msg)
	if not self.handshake_result then
		local ok,errmsg = handshake.do_handshake(self,msg)
		if not ok then
			self:close()
			self:say("handshake fail:",errmsg)
		end
		if self.handshake_result == "OK" then
			self:say("handshake success,secret:",self.secret)
		end
		return
	end
	if self.secret then
		msg = crypt.xor_str(msg,self.secret)
	end
	local message = self.codec:unpack_message(msg)
	if self.handler.onmessage then
		self.handler.onmessage(self,message)
	end
	local protoname = message.proto
	local callback = self:wakeup(protoname)
	if callback then
		callback(self,message)
	end
end

function tcp:send_request(protoname,request,callback)
	local session
	if callback then
		self.session = self.session + 1
		session = self.session
		self.sessions[session] = callback
	end
	local message = {
		type = "REQUEST",
		proto = protoname,
		session = session,
		request = request,
	}
	local bin = self.codec:pack_message(message)
	if self.secret then
		bin = crypt.xor_str(bin,self.secret)
	end
	return self:send(bin)
end

function tcp:send_response(protoname,response,session)
	local message = {
		type = "RESPONSE",
		proto = protoname,
		session = session,
		response = response,
	}
	local bin = self.codec:pack_message(message)
	if self.secret then
		bin = crypt.xor_str(bin,self.secret)
	end
	return self:send(bin)
end

function tcp:send(bin)
	local size = #bin
	assert(size <= 65535,"package too long")
	socket_proxy.write(self.linkid,bin)
end

function tcp:wait(protoname,callback)
	if not self.wait_proto[protoname] then
		self.wait_proto[protoname] = {}
	end
	table.insert(self.wait_proto[protoname],callback)
end

function tcp:wakeup(protoname)
	if not self.wait_proto[protoname] then
		return nil
	end
	return table.remove(self.wait_proto[protoname],1)
end

tcp.ignore_one = tcp.wakeup

return tcp
