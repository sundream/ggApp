local ltrace = require "gg.base.ltrace"
function onerror(errmsg)
	local stack = ltrace.getfulltrace()
	if errmsg then
		errmsg = string.format("%s\n%s",errmsg,stack)
	else
		errmsg = stack
	end
	print(errmsg)
	logger.log("error","error",errmsg)
end

-- 扩展skynet
local skynet_getenv = skynet.getenv
function skynet.getenv(key)
	if not skynet.env then
		skynet.env = {}
	end
	if not skynet.env[key] then
		skynet.env[key] = skynet_getenv(key)
	end
	return skynet.env[key]
end
