--- 日志模块
--@script gg.logger.logger
--@author sundream
--@release 2018/12/25 10:30:00

local cjson = require "cjson"

logger = logger or {}

--- 写日志(msg是什么就写什么,不经过任何修饰)
--@param[type=string] filename 文件名
--@param[type=string] msg 消息
function logger.write(filename,msg)
	skynet.send(logger.service,"lua","write",filename,msg)
end

--- 写日志,日志级别:debug
--@param[type=string] filename 文件名
--@param[type=string] fmt 格式化串
--@param ... 用于格式化的参数
--@usage
--	logger.debug("test","name=%s,age=%s","lgl",28)
--	logger.debug("t1/t2/t3","hello,world")
function logger.debug(filename,fmt,...)
	logger.logf("debug",filename,fmt,...)
end

--- 写日志,日志级别:trace,trace日志会记录调用该函数的文件和行号
--@param[type=string] filename 文件名
--@param[type=string] fmt 格式化串
--@param ... 用于格式化的参数
--@usage
--	logger.debug("test","name=%s,age=%s","lgl",28)
--	logger.debug("t1/t2/t3","hello,world")
function logger.trace(filename,fmt,...)
	logger.logf("trace",filename,fmt,...)
end

--- 写日志,日志级别:info
--@param[type=string] filename 文件名
--@param[type=string] fmt 格式化串
--@param ... 用于格式化的参数
--@usage
--	logger.info("test","name=%s,age=%s","lgl",28)
--	logger.info("t1/t2/t3","hello,world")
function logger.info(filename,fmt,...)
	logger.logf("info",filename,fmt,...)
end

--- 写日志,日志级别:warn
--@param[type=string] filename 文件名
--@param[type=string] fmt 格式化串
--@param ... 用于格式化的参数
--@usage
--	logger.warn("test","name=%s,age=%s","lgl",28)
--	logger.warn("t1/t2/t3","hello,world")
function logger.warn(filename,fmt,...)
	logger.logf("warn",filename,fmt,...)
end

--- 写日志,日志级别:error
--@param[type=string] filename 文件名
--@param[type=string] fmt 格式化串
--@param ... 用于格式化的参数
--@usage
--	logger.error("test","name=%s,age=%s","lgl",28)
--	logger.error("t1/t2/t3","hello,world")
function logger.error(filename,fmt,...)
	logger.logf("error",filename,fmt,...)
end

--- 写日志,日志级别:fatal
--@param[type=string] filename 文件名
--@param[type=string] fmt 格式化串
--@param ... 用于格式化的参数
--@usage
--	logger.fatal("test","name=%s,age=%s","lgl",28)
--	logger.fatal("t1/t2/t3","hello,world")
function logger.fatal(filename,fmt,...)
	logger.logf("fatal",filename,fmt,...)
end

--- 写日志,写入的消息会加上时间前缀,并且会自动换行
--@param[type=string] loglevel 日志级别
--@param[type=string] filename 文件名
--@param ... 参数(传table会用json编码)
--@usage
--	logger.log("info","test","lgl",28)
--	logger.log("debug","t1/t2/t3","hello,world")
function logger.log(loglevel,filename,...)
	local loglevel_name
	loglevel,loglevel_name = logger.check_loglevel(loglevel)
	if logger.loglevel > loglevel then
		return
	end
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
	local msg = table.concat(args,logger.seperator)
	logger.logf(loglevel,filename,msg)
end

--- 写日志,写入的消息会加上时间前缀,并且会自动换行
--@param[type=string] loglevel 日志级别
--@param[type=string] filename 文件名
--@param[type=string] fmt 格式化串
--@param ... 用于格式化的参数(传table会用json编码)
--@usage
--	logger.logf("info","test","name=%s,age=%s","lgl",28)
--	logger.logf("debug","t1/t2/t3","hello,world")
function logger.logf(loglevel,filename,fmt,...)
	local loglevel_name
	loglevel,loglevel_name = logger.check_loglevel(loglevel)
	if logger.loglevel > loglevel then
		return
	end
	assert(fmt)
	if loglevel == logger.TRACE then
		local info = debug.getinfo(2,"Sl")
		fmt = info.short_src .. ":" .. info.currentline .. " " .. fmt
	end
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
	skynet.send(logger.service,"lua","log",filename,msg)
	if loglevel >= logger.ERROR then
		local bugreport_mails = skynet.getenv("bugreport_mails")
		if bugreport_mails then
			local pos = string.find(msg,"\n")
			local tag = msg:sub(1,pos-1)
			if not logger.bugreport_mails then
				logger.bugreport_mails = {}
			end
			-- 控制类似bug发送间隔
			local now = os.time()
			local last_sendtime = logger.bugreport_mails[tag]
			if not last_sendtime or (now - last_sendtime > 60) then
				local subject = string.format("name=%s,id=%s,index=%s,appid=%s,area=%s,zoneid=%s,filename=%s",
					skynet.getenv("name"),skynet.getenv("id"),skynet.getenv("index"),skynet.getenv("appid"),skynet.getenv("area"),skynet.getenv("zoneid"),filename)
				logger.sendmail(bugreport_mails,subject,msg)
			end
			logger.bugreport_mails[tag] = now
		end
	end
	return msg
end

--- 重新打开日志文件(logrotate时可能有用)
--@param[type=string] filename 文件名
function logger.freopen(filename)
	skynet.send(logger.service,"lua","freopen",filename)
end


function logger.sendmail(to_list,subject,content,mail_smtp,mail_user,mail_password)
	mail_smtp = mail_smtp or skynet.getenv("mail_smtp")
	mail_user = mail_user or skynet.getenv("mail_user")
	mail_password = mail_password or skynet.getenv("mail_password")
	skynet.send(logger.service,"lua","sendmail",to_list,subject,content,mail_smtp,mail_user,mail_password)
end

--- 控制台输出消息,日志级别可以控制是否输出
--@param ... 输出参数
function logger.print(...)
	if logger.loglevel > logger.DEBUG then
		return
	end
	print(...)
end

--- 设置日志级别
--@param[type=string] loglevel 日志级别
--@usage
--	logger.setloglevel("info")	-- 日志级别低于info的日志将不会记录,如debug
function logger.setloglevel(loglevel)
	loglevel = logger.check_loglevel(loglevel)
	logger.loglevel = loglevel
end

function logger.check_loglevel(loglevel)
	if type(loglevel) == "string" then
		loglevel = string.lower(loglevel)
		loglevel = assert(logger.NAME_LEVEL[loglevel],string.format("invalid loglvel: %s",loglevel))
	else
		assert(logger.LEVEL_NAME[loglevel],string.format("invalid loglvel: %s",loglevel))
	end
	local name = logger.LEVEL_NAME[loglevel]
	return loglevel,name
end

logger.DEBUG = 1
logger.TRACE = 2
logger.INFO = 3
logger.WARN = 4
logger.ERROR = 5
logger.FATAL = 6
logger.NAME_LEVEL = {
	debug = logger.DEBUG,
	trace = logger.TRACE,
	info = logger.INFO,
	warn = logger.WARN,
	["error"] = logger.ERROR,
	fatal = logger.FATAL,
}
logger.LEVEL_NAME = {
	[logger.DEBUG] = "debug",
	[logger.TRACE] = "trace",
	[logger.INFO] = "info",
	[logger.WARN] = "warn",
	[logger.ERROR] = "error",
	[logger.FATAL] = "fatal",
}


--- 启动日志服务
--@usage
--	有3个配置参数可以影响日志服务行为
--	1. loglevel: 控制日志级别(debug<trace<info<warn<error<fatal)
--	2. logpath: 日志文件目录
--	3. log_dailyrotate: 是否每天自动分割日志
function logger.init()
	logger.seperator = skynet.getenv("log_seperator") or " "
	logger.setloglevel(skynet.getenv("loglevel"))
	if not logger.service then
		logger.service = skynet.uniqueservice("gg/service/loggerd")
	end
end

--- 关闭日志服务
function logger.shutdown()
	skynet.send(logger.service,"lua","shutdown")
end

return logger
