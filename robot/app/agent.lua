local skynet = require "skynet"
local socket = require "skynet.socket"
local socket_proxy = require "socket_proxy"
local tcp = require "app.client.tcp"

local tcpobj
local handler

local function onconnect()
	if not tcpobj then
		return
	end
	if handler.onconnect then
		handler.onconnect(tcpobj)
	end
	while true do
		local ok,msg,sz = pcall(socket_proxy.read,tcpobj.linkid)
		if not ok then
			if handler.onclose then
				handler.onclose(tcpobj)
			end
			break
		end
		msg = skynet.tostring(msg,sz)
		xpcall(tcpobj.recv_message,skynet.error,tcpobj,msg)
	end
end

local CMD = {}

function CMD.connect(conf)
	local ip = assert(conf.ip)
	local port = assert(conf.port)
	tcpobj = tcp.new()
	tcpobj:connect(ip,port)
	skynet.timeout(0,onconnect)
end

function CMD.close()
	if not tcpobj then
		return
	end
	tcpobj:close()
	tcpobj = nil
	skynet.exit()
end

local agent = {}

function agent.start(h)
	handler = h
	skynet.start(function ()
		skynet.dispatch("lua",function (session,source,cmd,...)
			local func = CMD[cmd]
			skynet.retpack(func(...))
		end)
	end)
end

return agent
