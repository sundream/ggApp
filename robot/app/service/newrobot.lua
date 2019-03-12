local skynet = require "skynet"

local num,startpid = ...
num = assert(tonumber(num))
startpid = assert(tonumber(startpid))

skynet.start(function ()
	local ip = skynet.getenv("ip")
	local port = tonumber(skynet.getenv("port"))
	local gate_type = skynet.getenv("gate_type")
	for i=0,num-1 do
		local pid = startpid + i
		local robot = skynet.newservice("app/service/robot",pid)
		skynet.call(robot,"lua","connect",{
			ip = ip,
			port = port,
			gate_type = gate_type,
		})
	end
	skynet.exit()
end)
