--- 定时器模块
--@script gg.base.timer
--@author sundream
--@release 2019/3/29 14:00:00

local ctimer = class("ctimer")

function ctimer:init()
    self.timers = {}
    self.id = 0
end

--- 开启定时器
--@param[type=string] name 定时器名
--@param[type=int|string|table] interval 定时器超时值(单位为秒),如果类型是string|table时，则表示超时值为crontab表达式
--@param[type=func] callback 超时回调函数
--@return[type=int] 定时器ID
--@usage
--gg.timer = gg.class.ctimer.new()
--gg.timer:timeout(name,10,callback) <=> 10s后执行一次callback
--gg.timer:timeout(name,"*/5 * * * * *",callback) <=> 每隔5s执行一次callback
function ctimer:timeout(name,interval,callback)
    local typ = type(interval)
    if typ == "string" or typ == "table" then  -- cronexpr
        return self:cron_timeout(name,interval,callback)
    end
    interval = interval * 100
    return self:timeout2(name,interval,callback)
end

--- 开启定时器
--@param[type=string] name 定时器名
--@param[type=int] interval 定时器超时值(单位为1/100秒)
--@param[type=func] callback 超时回调函数
--@return[type=int] 定时器ID
function ctimer:timeout2(name,interval,callback)
    interval = interval < 0 and 0 or interval
    local id = self:addtimer(name,callback)
    skynet.timeout(interval,function ()
        self:ontimeout(id)
    end)
    return id
end

--- 取消定时器
--@param[type=string] name 定时器名
--@usage gg.timer:untimeout(name) <=> 删除所有名为name的定时器
function ctimer:untimeout(name)
    local ids = self.timers[name]
    for id in pairs(ids) do
        self:deltimer(id)
    end
end

--- 用crontab表达式开启定时器
--@param[type=string] name 定时器名
--@param[type=string|table] cron crontab表达式
--@param[type=func] callback 超时回调函数
--@return[type=int] 定时器ID
--@usage gg.timer:cron_timer(name,"*/5 * * * * *",callback) <=> 每隔5s执行一次callback
function ctimer:cron_timeout(name,cron,callback,callit)
    if type(cron) == "string" then
        cron = gg.cronexpr.new(cron)
    end
    assert(type(cron) == "table")
    local now = os.time()
    local nexttime = gg.cronexpr.nexttime(cron,now)
    local interval = nexttime - now
    assert(interval > 0)
    if callit then
        callback()
    end
    local timerid = self:timeout(name,interval,function () self:cron_timeout(name,cron,callback,true) end)
    return timerid
end


-- private method
function ctimer:genid()
    repeat
        self.id = self.id + 1
    until self.timers[self.id] == nil
    return self.id
end

function ctimer:addtimer(name,callback)
    local id = self:genid()
    local timer_obj = {
        id = id,
        name = name,
        callback = callback,
    }
    self.timers[id] = timer_obj
    if not self.timers[name] then
        self.timers[name] = {}
    end
    self.timers[name][id] = timer_obj
    return id
end

function ctimer:gettimer(id)
    return self.timers[id]
end

--- 根据ID取消定时器
--@param[type=int] id 定时器ID
function ctimer:deltimer(id)
    local timer_obj = self:gettimer(id)
    if not timer_obj then
        return
    end
    self.timers[id] = nil
    local name = timer_obj.name
    local ids = self.timers[name]
    if ids then
        ids[id] = nil
    end
end

function ctimer:ontimeout(id)
    local timer_obj = self:gettimer(id)
    if not timer_obj then
        return
    end
    self:deltimer(id)
    local name = timer_obj.name
    local callback = timer_obj.callback
    if callback then
        --xpcall(callback,gg.onerror or debug.traceback)
        gg.profile.cost.timer = gg.profile.cost.timer or {__tostring=tostring,}
        gg.profile:stat(gg.profile.cost.timer,name,
            gg.onerror or debug.traceback,
            callback)
    end
end

return ctimer
