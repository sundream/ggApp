gg = gg or {}

function gg.init()
    gg.profile = gg.class.cprofile.new()
    gg.timer = gg.class.ctimer.new()
    gg.sync = gg.class.csync.new()
    gg.actor = gg.class.cactor.new()

    gg.savemgr = gg.class.csavemgr.new()
    gg.dbmgr = gg.class.cdbmgr.new()

    gg.thistemp = gg.class.cthistemp.new()
end

function gg.start()
end

-- 获取游戏服http接口代理对象
function gg.gameserver(ip,port,appkey)
    if not gg.gameservers then
        gg.gameservers = {}
    end
    local host = string.format("%s:%s",ip,port)
    if not gg.gameservers[host] then
        local gameserver = gg.class.cgameserver.new({
            host = host,
            appkey = appkey,
        })
        gg.gameservers[host] = gameserver
    end
    return gg.gameservers[host]
end

return gg
