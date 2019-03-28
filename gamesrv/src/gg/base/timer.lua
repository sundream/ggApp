--- 定时器模块
--@script gg.base.timer
--@author sundream
--@release 2018/12/25 10:30:00
timer = timer or {
	timers = {},
	id = 0,
}

--- 开启定时器
--@param[type=string] name 定时器名
--@param[type=int|string|table] interval 定时器超时值(单位为秒),如果类型是string|table时，则表示超时值为crontab表达式
--@param[type=func] callback 超时回调函数
--@return[type=int] 定时器ID
--@usage timer.timeout(name,10,callback) <=> 10s后执行一次callback
--@usage timer.timeout(name,"*/5 * * * * *",callback) <=> 每隔5s执行一次callback
function timer.timeout(name,interval,callback)
	local typ = type(interval)
	if typ == "string" or typ == "table" then  -- cronexpr
		return timer.cron_timeout(name,interval,callback)
	end
	interval = interval * 100
	return timer.timeout2(name,interval,callback)
end

--- 开启定时器
--@param[type=string] name 定时器名
--@param[type=int] interval 定时器超时值(单位为1/100秒)
--@param[type=func] callback 超时回调函数
--@return[type=int] 定时器ID
function timer.timeout2(name,interval,callback)
	interval = interval < 0 and 0 or interval
	local id = timer.addtimer(name,callback)
	skynet.timeout(interval,function ()
		timer.ontimeout(id)
	end)
	return id
end

--- 取消定时器
--@param[type=string] name 定时器名
--@usage timer.untimeout(name) <=> 删除所有名为name的定时器
function timer.untimeout(name)
	local ids = timer.timers[name]
	for id in pairs(ids) do
		timer.deltimer(id)
	end
end

--- 用crontab表达式开启定时器
--@param[type=string] name 定时器名
--@param[type=string|table] cron crontab表达式
--@param[type=func] callback 超时回调函数
--@return[type=int] 定时器ID
--@usage timer.cron_timer(name,"*/5 * * * * *",callback) <=> 每隔5s执行一次callback
function timer.cron_timeout(name,cron,callback,callit)
	if type(cron) == "string" then
		cron = cronexpr.new(cron)
	end
	assert(type(cron) == "table")
	local now = os.time()
	local nexttime = cronexpr.nexttime(cron,now)
	local interval = nexttime - now
	assert(interval > 0)
	if callit then
		callback()
	end
	local timerid = timer.timeout(name,interval,function () timer.cron_timeout(name,cron,callback,true) end)
	return timerid
end


-- private method
function timer.genid()
	repeat
		timer.id = timer.id + 1
	until timer.timers[timer.id] == nil
	return timer.id
end

function timer.addtimer(name,callback)
	local id = timer.genid()
	local timer_obj = {
		id = id,
		name = name,
		callback = callback,
	}
	timer.timers[id] = timer_obj
	if not timer.timers[name] then
		timer.timers[name] = {}
	end
	timer.timers[name][id] = timer_obj
	return id
end

function timer.gettimer(id)
	return timer.timers[id]
end

--- 根据ID取消定时器
--@param[type=int] id 定时器ID
function timer.deltimer(id)
	local timer_obj = timer.timers[id]
	if not timer_obj then
		return
	end
	timer.timers[id] = nil
	local name = timer_obj.name
	local ids = timer.timers[name]
	if ids then
		ids[id] = nil
	end
end

function timer.ontimeout(id)
	local timer_obj = timer.gettimer(id)
	if not timer_obj then
		return
	end
	timer.deltimer(id)
	local name = timer_obj.name
	local callback = timer_obj.callback
	if callback then
		--xpcall(callback,onerror or debug.traceback)
		profile.cost.timer = profile.cost.timer or {__tostring=tostring,}
		profile.stat(profile.cost.timer,name,
			onerror or debug.traceback,
			callback)
	end
end

return timer
