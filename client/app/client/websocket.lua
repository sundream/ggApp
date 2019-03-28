local websocket_client = require "app.client.websocket.client"
local crypt = require "crypt"
local handshake = require "app.client.handshake"

local websocket = {}
local mt = {__index = websocket}

function websocket.new(opts)
	opts = opts or {}
	opts.timeout = opts.timeout or 0.05
	local sock = websocket_client:new(opts)
	local self = {
		linktype = "websocket",
		sock = sock,
		send_binary = opts.send_binary and true or false,
		session = 0,
		sessions = {},
		verbose = true,  -- default: print recv message
		last_recv = "",
		wait_proto = {},
		secret = nil	-- 密钥
	}
	if app.config.no_handshake then
		self.handshake_result = "OK"
	end
	return setmetatable(self,mt)
end

function websocket:connect(host,port)
	local uri = host
	if port then
		uri = string.format("ws://%s:%s",host,port)
	end
	local ok,errmsg = self.sock:connect(uri)
	assert(ok,errmsg)
	self:say("connect")
	app:attach(self.sock.sock,self)
	app:ctl("add","read",self.sock.sock)
	--app:ctl("add","write",self.sock.sock)
end

function websocket:send_request(protoname,request,callback)
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
	local bin = app.codec:pack_message(message)
	if self.secret then
		bin = crypt.xor_str(bin,self.secret)
	end
	return assert(self:send(bin))
end

function websocket:send_response(protoname,response,session)
	local message = {
		type = "RESPONSE",
		proto = protoname,
		session = session,
		response = response,
	}
	local bin = app.codec:pack_message(message)
	if self.secret then
		bin = crypt.xor_str(bin,self.secret)
	end
	return assert(self:send(bin))
end

function websocket:send(bin)
	if self.send_binary then
		return self.sock:send_binary(bin)
	else
		return self.sock:send_text(bin)
	end
end

function websocket:dispatch_message()
	local data,typ,err = self.sock:recv_frame()
	if not data then
		self:close()
		return
	end
	local message
	if typ == "ping" then
		self.sock:send_pong(data)
	elseif typ == "pong" then
	elseif typ == "close" then
		self:close()
	elseif typ == "text" then
		self.last_recv = self.last_recv .. data
		-- fin
		if err ~= "again" then
			message = self.last_recv
			self.last_recv = ""
		end
	elseif typ == "binary" then
		self.last_recv = self.last_recv .. data
		-- fin
		if err ~= "again" then
			message = self.last_recv
			self.last_recv = ""
		end
	end
	if message then
		local ok,err = xpcall(function ()
			self:onmessage(message)
		end,debug.traceback)
		if not ok then
			self:say(err)
		end
	end
end

function websocket:close(code,msg)
	self:say("close")
	self.sock:close(code,msg)
	app:unattach(self.sock.sock,self)
	app:ctl("del","read",self.sock.sock)
	--app:ctl("del","write",self.sock.sock)
end

function websocket:quite()
	self.verbose = not self.verbose
end

function websocket:say(...)
	print(string.format("[linktype=%s]",self.linktype),...)
end

function websocket:onmessage(msg)
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
	local message = app.codec:unpack_message(msg)
	if self.verbose then
		self:say("\n"..table.dump(message))
	end
	local protoname = message.proto
	local callback = self:wakeup(protoname)
	if callback then
		callback(self,message)
	end
end

function websocket:wait(protoname,callback)
	if not self.wait_proto[protoname] then
		self.wait_proto[protoname] = {}
	end
	table.insert(self.wait_proto[protoname],callback)
end

function websocket:wakeup(protoname)
	if not self.wait_proto[protoname] then
		return nil
	end
	return table.remove(self.wait_proto[protoname],1)
end

websocket.ignore_one = websocket.wakeup

return websocket
