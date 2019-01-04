local skynet = require "skynet.manager"

local usage = [[
Welcome,I'am a robot(version: 0.0.1)
use: telnet 127.0.0.1 %s to control it
e.g:
	//从1000001角色ID开始启动100个机器人
	start app/service/newrobot 100 1000000
]]


skynet.start(function ()
	local port = skynet.getenv("debug_port") or 6666
	usage = string.format(usage,port)
	print(usage)
	skynet.newservice("debug_console",port)
end)
