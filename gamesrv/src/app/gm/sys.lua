--- 功能: 安全停服
--- 用法: stop
function gm.stop(args)
	local reason = args[1] or "gm"
	game.stop(reason)
end

function gm.saveall(args)
	game.saveall()
end

--- 功能: 将某玩家踢下线
--- 用法: kick 玩家ID [玩家ID]
function gm.kick(args)
	local isok,args = checkargs(args,"int","*")
	if not isok then
		return gm.say("用法: kick pid1 pid2 ...")
	end
	for i,v in ipairs(args) do
		local pid = tonumber(v)
		playermgr.kick(pid,"gm")
	end
end

--- 功能: 将所有玩家踢下线
--- 用法: kickall
function gm.kickall(args)
	playermgr.kickall("gm")
end

--- 功能: 执行一段lua脚本
--- 用法: exec lua脚本
function gm.exec(args)
	local cmdline = table.concat(args," ")
	local chunk = load(cmdline,"=(load)","bt")
	return chunk()
end

gm.runcmd = gm.exec

--- 功能: 执行一个文件
--- 用法: dofile lua文件
function gm.dofile(args)
	local isok,args = checkargs(args,"string")
	if not isok then
		return gm.say("用法: dofile lua文件")
	end
	local filename = args[1]
	-- loadfile need execute skynet.cache.clear to reload
	--local chunk = loadfile(filename,"bt")
	local fd = io.open(filename,"rb")
	local script = fd:read("*all")
	fd:close()
	return exec(script)
end
--- 功能: 获取服务器状态
--- 用法: status
function gm.status(args)
	local info = {
		time = os.date("%Y-%m-%d %H:%M:%S",os.time()),
		id = skynet.getenv("id"),
		index = skynet.getenv("index"),
		area = skynet.getenv("area"),
		mqlen = skynet.mqlen(),
		task = skynet.task(),
	}
	local data = table.dump(info)
	return gm.say(data)
end

--- 功能: 热更新某模块
--- 用法: hotfix 模块名 ...
function gm.hotfix(args)
	local fails = {}
	for i,path in ipairs(args) do
		local isok,errmsg = hotfix.hotfix(path)
		if not isok then
			table.insert(fails,{path=path,errmsg=errmsg})
		end
	end
	for i,path in ipairs(fails) do
		gm.say(string.format("热更失败:%s",path))
	end
	if next(fails) then
		return gm.say("update fail:\n" .. table.dump(fails))
	end
end

gm.reload = gm.hotfix

--- 用法: loglevel [日志等级]
--- 举例: loglevel		<=> 查看日志等级
--- 举例: loglevel debug/trace/info/warn/error/fatal  <=> 设置对应日志等级
function gm.loglevel(args)
	local loglevel = args[1]
	if not loglevel then
		local loglevel,name = logger.check_loglevel(logger.loglevel)
		return gm.say(name)
	else
		local ok,loglevel,name = pcall(logger.check_loglevel,loglevel)
		if not ok then
			local errmsg = loglevel
			return gm.say(errmsg)
		end
		logger.setloglevel(loglevel)
		return name
	end
end

return gm
