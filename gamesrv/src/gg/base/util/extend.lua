local traceback = require "gg.base.traceback"
function onerror(errmsg)
	local stack = traceback.getfulltrace()
	if errmsg then
		errmsg = string.format("%s\n%s",errmsg,stack)
	else
		errmsg = stack
	end
	print(errmsg)
	logger.logf("error","error",errmsg)
end

-- 扩展skynet
local skynet_getenv = skynet.getenv
function skynet.getenv(key)
	if not skynet.env then
		skynet.env = {}
		local ok,custom = pcall(require,"app.config.custom")
		for k,v in pairs(custom) do
			skynet.env[k] = v
		end
	end
	if not skynet.env[key] then
		skynet.env[key] = skynet_getenv(key)
	end
	return skynet.env[key]
end
