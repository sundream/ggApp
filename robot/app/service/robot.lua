require "app.util"
local skynet = require "skynet"
local agent = require "app.agent"
local login = require "app.login"
local config = require "app.config.custom"
local roleid = tonumber(...)
assert(roleid)

local robot = {}

function robot.onconnect(linkobj)
    skynet.error(string.format("op=onconnect,linktype=%s,linkid=%s,roleid=%s",linkobj.linktype,linkobj.linkid,roleid))
    local account = string.format("#%d",roleid)
    robot.linkobj = linkobj
    robot.account = account
    if config.debuglogin then
        login.entergame(linkobj,account,roleid,nil,robot.onlogin)
    else
        login.quicklogin(linkobj,account,roleid,robot.onlogin)
    end
end

function robot.onclose(linkobj)
    skynet.error(string.format("op=onclose,linktype=%s,linkid=%s,roleid=%s",linkobj.linktype,linkobj.linkid,roleid))
    robot.linkobj.closed = true
end

function robot.onlogin()
    local linkobj = robot.linkobj
    skynet.error(string.format("op=onlogin,linktype=%s,linkid=%s,roleid=%s",linkobj.linktype,linkobj.linkid,roleid))
    robot.heartbeat()
    -- todo something
    robot.linkobj:send_request("C2GS_GM",{
        cmd = "setGold 1000",
    })
    robot.linkobj:send_request("C2GS_DDZGame_EnterHall",{hallId = 1})
    robot.linkobj:wait("GS2C_DDZGame_EnterHallSucc",function (linkobj,message)
        robot.linkobj:send_request("C2GS_DDZGame_Match",{})
        robot.waitGameOver()
    end)
end

function robot.waitGameOver()
    robot.linkobj:wait("GS2C_DDZGame_GameOver",function (linkobj,message)
        robot.linkobj:send_request("C2GS_GM",{
            cmd = "setGold 1000",
        })
        robot.linkobj:send_request("C2GS_DDZGame_ReadyGame",{})
        robot.waitGameOver()
    end)
end

function robot.heartbeat()
    if robot.linkobj.closed then
        return
    end
    local interval = 1000
    skynet.timeout(interval,robot.heartbeat)
    robot.linkobj:send_request("C2GS_Ping",{
        str = "heartbeat",
    })
    robot.linkobj:wait("GS2C_Pong",function (linkobj,message)
        local args = message.args
        local time = args.time
        local delay
        if not robot.linkobj.time then
            delay = 0
        else
            delay = time - robot.linkobj.time - interval * 10
        end
        robot.linkobj.time = time
        if delay > 50 then
            skynet.error(string.format("op=heartbeat,linktype=%s,linkid=%s,roleid=%s,delay=%sms",linkobj.linktype,linkobj.linkid,roleid,delay))
        end
    end)
end

agent.start(robot)
return robot
