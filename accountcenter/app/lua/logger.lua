local cjson = require "cjson"
-- comptiable with lua51
unpack = unpack or table.unpack
table.unpack = unpack
if table.pack == nil then
	function table.pack(...)
		return {n=select("#",...),...}
	end
end

logger = logger or {}
function logger.write(filename,msg)
	ngx.log(ngx.INFO,string.format("%s|%s",filename,msg))
end

function logger.debug(filename,...)
	logger.log("debug",filename,...)
end

function logger.info(filename,...)
	logger.log("info",filename,...)
end

function logger.warn(filename,...)
	logger.log("warn",filename,...)
end

function logger.error(filename,...)
	logger.log("error",filename,...)
end

function logger.fatal(filename,...)
	logger.log("fatal",filename,...)
end

function logger.log(loglevel,filename,fmt,...)
	local loglevel_name
	loglevel,loglevel_name = logger.check_loglevel(loglevel)
	if logger.loglevel > loglevel then
		return
	end
	assert(fmt)
	local msg
	if select("#",...) == 0 then
		msg = fmt
	else
		local args = table.pack(...)
		local len = math.max(#args,args.n or 0)
		for i = 1, len do
			local typ = type(args[i])
			if typ == "table" then
				args[i] = cjson.encode(args[i])
			elseif typ ~= "number" then
				args[i] = tostring(args[i])
			end
		end
		msg = string.format(fmt,table.unpack(args))
	end
	msg = string.format("[%s] %s\n",loglevel_name,msg)
	ngx.log(ngx.INFO,string.format("%s|%s",filename,msg))
	return msg
end

-- console/print
function logger.print(...)
	if logger.loglevel > logger.DEBUG then
		return
	end
	print(string.format("[%s]",os.date("%Y-%m-%d %H:%M:%S")),...)
end

function logger.setloglevel(loglevel)
	loglevel = logger.check_loglevel(loglevel)
	logger.loglevel = loglevel
end

function logger.check_loglevel(loglevel)
	if type(loglevel) == "string" then
		loglevel = logger.NAME_LEVEL[string.lower(loglevel)]
	end
	assert(logger.LEVEL_NAME[loglevel],string.format("invalid loglvel:%s",loglevel))
	local name = logger.LEVEL_NAME[loglevel]
	return loglevel,name
end

logger.DEBUG = 1
logger.INFO = 2
logger.WARN = 3
logger.ERROR = 4
logger.FATAL = 5
logger.NAME_LEVEL = {
	debug = logger.DEBUG,
	info = logger.INFO,
	warn = logger.WARN,
	["error"] = logger.ERROR,
	fatal = logger.FATAL,
}
logger.LEVEL_NAME = {
	[logger.DEBUG] = "debug",
	[logger.INFO] = "info",
	[logger.WARN] = "warn",
	[logger.ERROR] = "error",
	[logger.FATAL] = "fatal",
}


function logger.init(config)
	logger.setloglevel(config.loglevel)
end

function logger.shutdown()
end

return logger
