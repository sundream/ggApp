package.path = "client/?.lua;client/lualib/?.lua;" .. package.path
package.cpath = "client/luaclib/?.so;client/luaclib/?.dll;" .. package.cpath

require "app.util"
require "app.cmd"
require "app.codec.init"
local socket = require "socket"
local config = require "app.config"

app = {}
app._VERSION = "0.0.1"

local parse_cmd
-- comptiable with lua51
if _VERSION == "Lua 5.1" then
	unpack = unpack or table.unpack
	table.unpack = unpack
	if table.pack == nil then
		function table.pack(...)
			return {n=select("#",...),...}
		end
	end
	parse_cmd = function (cmd)
		return loadstring(cmd)
	end
else
	parse_cmd = function (cmd)
		return load(cmd)
	end
end

local raw_print = print
print = function (...)
	if not app.os_is_windows then
		raw_print(...)
		return
	end
	if not app.stdin then
		raw_print(...)
	else
		local t = {...}
		for i,v in ipairs(t) do
			t[i] = tostring(v)
		end
		local msg
		-- empty table means parameter is nil!
		if #t == 0 then
			msg = "nil\n"
		else
			msg = table.concat(t," ") .. "\n"
		end
		app.stdin:send(msg)
	end
end

function app:init()
	self.timeout = 0.05
	self.wait_readables = {}
	self.wait_writables = {}
	self.sock_client = {}
	self.ticks = {}
	self.codec = codec.new(config.proto)
	self.config = config
	self.os_is_windows = os.getenv("HOME") == nil
	if self.os_is_windows then
		-- stdin cann't select in window,so use a socket to replace it!
		local host = "127.0.0.1"
		local port = 6667
		print(string.format("detect os is window\nuse telnet %s %s to control it",host,port))
		self.listen_stdin = socket.bind(host,port)
		self:ctl("add","read",self.listen_stdin)
	else
		-- linux
		self.stdin = socket.tcp()
		self.stdin:close()
		self.stdin:setfd(0)
		self:ctl("add","read",self.stdin)
	end
end


function app:run()
	self:usage()
	self:mainloop()
end

function app:usage()
	print(string.format("Game Client %s Welcome!",self._VERSION))
	print("exit() -> exit app")
	print("help() -> show help doc")
end

function app:dispatch_message()
	local readable,writable,err = socket.select(self.wait_readables,self.writables,self.timeout)
	for i,sock in ipairs(readable) do
		if sock == self.listen_stdin then
			if self.stdin then
				self:ctl("del","read",self.stdin)
				self.stdin:close()
			end
			self.stdin = self.listen_stdin:accept()
			self:ctl("add","read",self.stdin)
			self:usage()
		elseif sock == self.stdin then
			local cmd
			if self.os_is_windows then
				local r,err,part = self.stdin:receive("*l")
				if err then
					raw_print("stdin ",err)
					self:ctl("del","read",self.stdin)
					self.stdin:close()
					self.stdin = nil
				end
				cmd = r or part
			else
				cmd = io.read("*l")
			end
			local func = parse_cmd(cmd)
			if func then
				local result = table.pack(xpcall(func,debug.traceback))
				local ok = table.remove(result,1)
				if #result > 0 then
					print(table.unpack(result))
				end
			else
				print(nil)
			end
		else
			local clientobj = self.sock_client[sock]
			clientobj:dispatch_message()
		end
	end
end

function app:mainloop()
	while true do
		self:dispatch_message()
		self:on_tick(os.time()*1000)
	end
end

function app:on_tick(time)
	for sock,clientobj in pairs(self.sock_client) do
		if clientobj.on_tick then
			clientobj:on_tick(time)
		end
	end
end

function app:attach(sock,clientobj)
	self.sock_client[sock] = clientobj
end

function app:unattach(sock,clientobj)
	self.sock_client[sock] = nil
end

function app:ctl(cmd,readable,sock)
	if cmd == "add"  then
		if readable == "read" then
			local found = table.find(self.wait_readables,sock)
			if not found then
				table.insert(self.wait_readables,sock)
			end
		else
			assert(readable == "write")
			local found = table.find(self.wait_writables,sock)
			if not found then
				table.insert(self.wait_writables,sock)
			end
		end
	else
		assert(cmd == "del")
		if readable == "read" then
			local pos = table.find(self.wait_readables,sock)
			if pos then
				table.remove(self.wait_readables,pos)
			end
		else
			assert(readable == "write")
			local pos = table.find(self.wait_writables,sock)
			if pos then
				table.remove(self.wait_writables,pos)
			end
		end

	end
end

app:init()
app:run()
