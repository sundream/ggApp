require "app.util"
local skynet = require "skynet"
local agent = require "app.agent"
local login = require "app.login"
local config = require "app.config.user"
local pid = tonumber(...)
assert(pid)

local robot = {}

function robot.onconnect(tcpobj)
	local linkid = tcpobj.linkid
	print(string.format("op=onconnect,pid=%s,linkid=%s",pid,linkid))
	local account = string.format("#%d",pid)
	robot.tcpobj = tcpobj
	robot.account = account
	if config.debuglogin then
		login.entergame(tcpobj,account,pid,nil,robot.onlogin)
	else
		login.quicklogin(tcpobj,account,pid,robot.onlogin)
	end
end

function robot.onclose(tcpobj)
	local linkid = tcpobj.linkid
	print(string.format("op=onclose,linkid=%s",linkid))
end

function robot.onlogin()
	print(string.format("op=onlogin,pid=%s",pid))
	robot.heartbeat()
	-- todo something
end

function robot.heartbeat()
	local time = 1000
	skynet.timeout(time,robot.heartbeat)
	robot.tcpobj:send_request("C2GS_Ping",{
		str = "heartbeat",
	})
end

agent.start(robot)
return robot
