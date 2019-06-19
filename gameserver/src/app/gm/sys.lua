---功能: 安全停服
---@usage
---用法: stop
function gm.stop(args)
    local reason = args[1] or "gm"
    game.stop(reason)
end

function gm.saveall(args)
    game.saveall()
end

---功能: 将某玩家踢下线
---@usage
---用法: kick 玩家ID [玩家ID]
function gm.kick(args)
    local isok,args = gg.checkargs(args,"int","*")
    if not isok then
        return gm.say("用法: kick pid1 pid2 ...")
    end
    for i,v in ipairs(args) do
        local pid = tonumber(v)
        playermgr.kick(pid,"gm")
    end
end

---功能: 将所有玩家踢下线
---@usage
---用法: kickall
function gm.kickall(args)
    playermgr.kickall("gm")
end

---功能: 执行一段lua脚本
---@usage
---用法: exec lua脚本
function gm.exec(args)
    local cmdline = table.concat(args," ")
    local chunk = load(cmdline,"=(load)","bt")
    return chunk()
end

gm.runcmd = gm.exec

---功能: 执行一个文件
---@usage
---用法: dofile lua文件 ...
---举例: dofile /tmp/run.lua
function gm.dofile(args)
    local isok,args = gg.checkargs(args,"string","*")
    if not isok then
        return gm.say("用法: dofile lua文件")
    end
    local filename = args[1]
    -- loadfile need execute skynet.cache.clear to reload
    --local chunk = loadfile(filename,"bt")
    local fd = io.open(filename,"rb")
    local script = fd:read("*all")
    fd:close()
    return gg.execcode(script,nil,table.unpack(args,2))
end

---功能: 获取服务器状态
---@usage
---用法: status
function gm.status(args)
    return gm.say(table.dump(gg.server:status()))
end

---功能: 查看服务器协议,定时器等消耗统计信息
---@usage
---用法: info
function gm.info(args)
    return gm.say(table.dump(gg.profile.cost))
end

---功能: 热更新某模块
---@usage
---用法: hotfix 模块名 ...
function gm.hotfix(args)
    local  hasCfg = false
    local fails = {}
    for i,path in ipairs(args) do
        local isok,errmsg = gg.hotfix(path)
        if not isok then
            table.insert(fails,{path=path,errmsg=errmsg})
        elseif string.find(path,"app.cfg.") then
            hasCfg = true
        end
    end
    if next(fails) then
        return gm.say("热更失败:\n" .. table.dump(fails))
    end
    if hasCfg then
        gg.hotfix("app.cfg.init")
    end
end

gm.reload = gm.hotfix

---功能: 设置/获取日志等级
---@usage
---用法: loglevel [日志等级]
---举例:
---loglevel     <=> 查看日志等级
---loglevel debug/trace/info/warn/error/fatal  <=> 设置对应日志等级
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

---功能: 设置/获取日期
---@usage
---用法: date [日期]
---举例: date        <=> 获取当前日期
---举例: date 2019/11/28 10:10:10        <=> 将时间设置成2019/11/28 10:10:10
function gm.date(args)
    local date
    if #args > 0 then
        if not skynet.getenv("allow_modify_date") then
            return gm.say("本服务器不允许修改时间")
        end
        date = table.concat(args," ")
        if not pcall(string.totime,date) then
            return gm.say(string.format("非法日期格式:%s",date))
        end
        local cmd = string.format("date -s '%s'",date)
        local isok,errmsg,errno = os.execute(cmd)
        if not isok then
            return gm.say(string.format("修改时间失败,errmsg=%s,errno=%s",errmsg,errno))
        else
            date = os.date("%Y/%m/%d %H:%M:%S")
        end
    else
        date = os.date("%Y/%m/%d %H:%M:%S")
    end
    gm.say(string.format("当前日期:%s",date))
    gm.say("恢复当前时间可用指令ntpdate")
    return date
end

---功能: 恢复当前时间
---@usage
---用法: ntpdate
---举例: ntpdate <=> 校正服务器时间，恢复为当前时区自然时间
function gm.ntpdate(args)
    if not skynet.getenv("allow_modify_date") then
        return gm.say("本服务器不允许修改时间")
    end
    local cmd = string.format("/usr/sbin/ntpdate -u cn.ntp.org.cn")
    gm.say("系统时间恢复中...")
    local isok,errmsg,errno = os.execute(cmd)
    if isok then
        local date = os.date("%Y/%m/%d %H:%M:%S")
        return gm.say(string.format("当前日期:%s",date))
    else
        return gm.say(string.format("恢复时间失败,errmsg=%s,errno=%s",errmsg,errno))
    end
end

return gm
