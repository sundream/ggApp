local skynet = require "skynet.manager"
local config = require "app.config.custom"

local usage = [[

Welcome,I'am a robot(version: 0.0.1)
usage:
    telnet 127.0.0.1 %s to control it
    #从1000001角色ID开始启动100个机器人
    start app/service/newrobot 100 1000000
config:
    loginserver: %s:%s
    gameserver: %s:%s[%s]
]]


skynet.start(function ()
    local port = skynet.getenv("debug_port") or 6666
    usage = string.format(usage,port,config.loginserver.ip,config.loginserver.port,skynet.getenv("ip"),skynet.getenv("port"),skynet.getenv("gate_type"))
    print(usage)
    skynet.newservice("debug_console",port)
end)
