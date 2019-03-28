skynet = require "skynet.manager"

logger = logger or {}

local function fullname(name)
	-- 约定: 不指定后缀，默认在logger.path下生成*.log日志，否则为完整路径
	local filename
	local extname = name:match(".+%.(%w+)$")
	if not extname then
		filename = string.format("%s/%s.log",logger.path,name)
	else
		filename = name
	end
	return filename
end

-- logger.log传的filename不带后缀
function logger.log(filename,msg)
	--assert(string.match(filename,"^[a-z_]+[a-z_0-9/]*$"),"invalid log filename:" .. tostring(filename))
	local now = os.time()
	local yesterday = os.date("%Y-%m-%d",now-24*3600)
	local today = os.date("%Y-%m-%d",now)
	local time = os.date("%H:%M:%S",now)
	local date = string.format("%s %s",today,time)
	if logger.time.sec ~= now then
		logger.time.sec = now
		logger.time.usec = 0
	end
	logger.time.usec = logger.time.usec + 1
	msg = string.format("[%s %06d] %s",date,logger.time.usec,msg)
	if logger.dailyrotate then
		local yesterday_filename
		local dirname,basename = string.match(filename,"(.*)/(.*)")
		if dirname and basename then
			filename = string.format("%s/%s/%s%s",dirname,basename,basename,today)
			yesterday_filename = string.format("%s/%s/%s%s",dirname,basename,basename,yesterday)
		else
			basename = filename
			filename = string.format("%s/%s%s",basename,basename,today)
			yesterday_filename = string.format("%s/%s%s",basename,basename,yesterday)
		end
		yesterday_filename = fullname(yesterday_filename)
		if logger.handles[yesterday_filename] then
			logger.close(yesterday_filename)
		end
	end
	logger.write(filename,msg)
	return msg
end

function logger.write(filename,msg)
	local fd = logger.gethandle(filename)
	fd:write(msg)
	fd:flush()
end

function logger.sendmail(to_list,subject,content,mail_smtp,mail_user,mail_password)
	local function escape(str)
		local str = string.gsub(str,"\"","\\\"")
		return str
	end

	--local sh = string.format("cd ../shell && python sendmail.py %s \"%s\" \"%s\" %s %s %s",to_list,escape(subject),escape(content),mail_smtp,mail_user,mail_password)
	local sh = string.format("cd ../shell && sh sendmail.sh %s \"%s\" \"%s\" %s %s %s",to_list,escape(subject),escape(content),mail_smtp,mail_user,mail_password)
	--os.execute会等待命令执行完毕才返回!
	--os.execute(sh)
	io.popen(sh)
end


function logger.gethandle(filename)
	filename = fullname(filename)
	if not logger.handles[filename] then
		local parent_path = string.match(filename,"(.*)/.*")
		if parent_path then
			os.execute("mkdir -p " .. parent_path)
		end
		local fd  = io.open(filename,"a+b")
		assert(fd,"logfile open failed:" .. tostring(filename))
		fd:setvbuf("line")
		logger.handles[filename] = fd
	end
	return logger.handles[filename]
end

function logger.close(filename)
	filename = fullname(filename)
	local fd = logger.handles[filename]
	if not fd then
		return
	end
	fd:close()
	logger.handles[filename] = nil
	return fd
end

function logger.freopen(filename)
	filename = fullname(filename)
	if logger.close(filename) then
		logger.gethandle(filename)
	end
end

function logger.init()
	if logger.binit then
		return
	end
	logger.binit = true
	print("logger init")
	logger.handles = {}
	logger.time = {
		sec = 0,
		usec = 0,
	}
	logger.path = skynet.getenv("logpath")
	logger.dailyrotate = skynet.getenv("log_dailyrotate") and true or false
	print(string.format("logger.path: %s,dailyrotate: %s",logger.path,logger.dailyrotate))
	os.execute(string.format("mkdir -p %s",logger.path))
end

function logger.shutdown()
	print("logger shutdown")
	for name,fd in pairs(logger.handles) do
		logger.close(name)
	end
	logger.handles = {}
	skynet.exit()
end

skynet.init(function ()
	logger.init()
end)

skynet.start(function ()
	skynet.dispatch("lua",function (session,source,cmd,...)
		local func = logger[cmd]
		if not func then
			error("invalid cmd:" .. tostring(cmd))
		end
		func(...)
	end)
end)

return logger
