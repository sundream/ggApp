gg = gg or {}

function gg.init()
    gg.profile = gg.class.cprofile.new()
    gg.timer = gg.class.ctimer.new()
    gg.sync = gg.class.csync.new()
    gg.savemgr = gg.class.csavemgr.new()

    gg.thistemp = gg.class.cthistemp.new()
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

-- 收集字段
gg.collect_attrs  = {"linkid","linktype","fd","pid","id","name","sid","warid",
    "pos","flag","state","uid","account","proto","cmd","addr"}

function gg.__tostring(obj)
    local list = {}
    for i,attr in ipairs(gg.collect_attrs) do
        if obj[attr] then
            table.insert(list,string.format("%s=%s",attr,obj[attr]))
        end
    end
    return tostring(obj) .. "@{" .. table.concat(list,",") .. "}"
end

return gg
