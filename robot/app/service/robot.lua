require "app.util"
local skynet = require "skynet"
local agent = require "app.agent"
local login = require "app.login"
local config = require "app.config.custom"
local roleid = tonumber(...)
assert(roleid)

local robot = {}

function robot.onconnect(tcpobj)
	local linkid = tcpobj.linkid
	skynet.error(string.format("op=onconnect,linkid=%s,roleid=%s",linkid,roleid))
	local account = string.format("#%d",roleid)
	robot.tcpobj = tcpobj
	robot.account = account
	if config.debuglogin then
		login.entergame(tcpobj,account,roleid,nil,robot.onlogin)
	else
		login.quicklogin(tcpobj,account,roleid,robot.onlogin)
	end
end

function robot.onclose(tcpobj)
	local linkid = tcpobj.linkid
	skynet.error(string.format("op=onclose,linkid=%s,roleid=%s",linkid,roleid))
end

function robot.onlogin()
	local linkid = robot.tcpobj.linkid
	skynet.error(string.format("op=onlogin,linkid=%s,roleid=%s",linkid,roleid))
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
