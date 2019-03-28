local socket = require "socket"
local crypt = require "crypt"
local handshake = require "app.client.handshake"

local tcp = {}
local mt = {__index = tcp}

function tcp.new()
	local sock = socket.tcp()
	local timeout = 0.05
	local self = {
		linktype = "tcp",
		timeout = timeout,
		sock = sock,
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

function tcp:connect(host,port)
	local ok,errmsg = self.sock:connect(host,port)
	assert(ok,errmsg)
	self:say("connect")
	if self.timeout > 0 then
		self.sock:settimeout(self.timeout) -- noblock mode
	end
	app:attach(self.sock,self)
	app:ctl("add","read",self.sock)
	--app:ctl("add","write",self.sock)
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
	local bin = app.codec:pack_message(message)
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
	local bin = app.codec:pack_message(message)
	if self.secret then
		bin = crypt.xor_str(bin,self.secret)
	end
	return self:send(bin)
end

function tcp:send(bin)
	local size = #bin
	assert(size <= 65535,"package too long")
	-- len field encode in big-endian
	local package = string.char(math.floor(size/256)) ..
		string.char(size%256) ..
		bin
	return self.sock:send(package)
end

function tcp:_unpack_message(text)
	local size = #text
	if size < 2 then
		return nil,text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s + 2 then
		return nil,text
	end
	return text:sub(3,s+2),text:sub(s+3)
end

function tcp:dispatch_message()
	local r,err,part = self.sock:receive("*a")
	if not r then
		if err == "closed" then
			self:close()
			return
		else
			assert(err == "timeout")
			r = part or ""
		end
	end
	self.last_recv = self.last_recv .. r
	local message
	while true do
		message,self.last_recv = self:_unpack_message(self.last_recv)
		if message then
			local ok,err = xpcall(function ()
				self:onmessage(message)
			end,debug.traceback)
			if not ok then
				self:say(err)
			end
		else
			break
		end
	end
end

function tcp:close()
	self:say("close")
	self.sock:close()
	app:unattach(self.sock,self)
	app:ctl("del","read",self.sock)
	--app:ctl("del","write",self.sock)
end

function tcp:quite()
	self.verbose = not self.verbose
end

function tcp:say(...)
	print(string.format("[linktype=%s]",self.linktype),...)
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
