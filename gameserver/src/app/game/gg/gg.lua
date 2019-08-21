function gg.init()
    gg.profile = gg.class.cprofile.new()
    gg.timer = gg.class.ctimer.new()
    gg.sync = gg.class.csync.new()
    gg.actor = gg.class.cactor.new()

    gg.dbmgr = gg.class.cdbmgr.new()
    gg.savemgr = gg.class.csavemgr.new()
    gg.timectrl = gg.class.ctimectrl.new()

    gg.playermgr = gg.class.cplayermgr.new()
    gg.loginserver = gg.class.cloginserver.new({
        host = skynet.getenv("loginserver"),
        appid = skynet.getenv("appid"),
        appkey = skynet.getenv("appkey"),
        loginserver_appkey = skynet.getenv("loginserver_appkey"),
    })
    local index = skynet.getenv("index")
    local nodes = skynet.getenv("nodes")
    local node_index = {}
    for node_name,conf in pairs(nodes) do
        node_index[node_name] = conf.index
    end
    snowflake.init(index,node_index)

    gg.data = gg.class.cdatabaseable.new()
    gg.today = gg.class.ctoday.new()
    gg.thistemp = gg.class.cthistemp.new()
    gg.thisweek = gg.class.cthisweek.new()
    gg.thisweek2 = gg.class.cthisweek2.new()
    gg.thismonth = gg.class.cthismonth.new()
    local time = gg.class.cattrcontainer.new({
        today = gg.today,
        thistemp = gg.thistemp,
        thisweek = gg.thisweek,
        thisweek2 = gg.thisweek2,
        thismonth = gg.thismonth,
    })

    gg.server = gg.class.cserver.new()

    gg.component = {}
    gg.ordered_component = {}
    gg:add_component("data",gg.data)
    gg:add_component("time",time)

    gg:loadfromdatabase()
    gg.savename = "gg"
    gg.savemgr:autosave(gg)
end

function gg.start()
end

function gg:unserialize(toload)
    if table.isempty(toload) then
        return
    end
    for name,data in pairs(toload) do
        local obj = self.component[name]
        if obj then
            obj:unserialize(data)
        end
    end
    self.loadstate = "loaded"
end

function gg:serialize()
    local data = {}
    for name,obj in pairs(self.component) do
        if not obj.nosavetodatabase then
            if obj.serialize then
                data[name] = obj:serialize()
            end
        end
    end
    return data
end

function gg:onload()
    for i=1,#self.ordered_component do
        local obj = self.ordered_component[i]
        if obj.onload then
            obj:onload(self)
        elseif obj.exec then
            obj:exec("onload",self)
        end
    end
end

function gg:loadfromdatabase()
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local data = {}
        local key = "gg"
        local list = db:hgetall(key)
        for i=1,#list,2 do
            local name,objdata = list[i],list[i+1]
            data[name] = cjson.decode(objdata)
        end
        self:unserialize(data)
    else
        local data = db.gg:findOne({_id="gg"})
        self:unserialize(data)
    end
    self:onload()
end

function gg:savetodatabase()
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local key = "gg"
        local data = self:serialize()
        for name,objdata in pairs(data) do
            objdata = cjson.encode(objdata)
            db:hset(key,name,objdata)
        end
    else
        local data = self:serialize()
        db.gg:update({_id="gg"},data,true,false)
    end
end

function gg:add_component(name,component)
    assert(self.component[name] == nil)
    self.component[name] = component
    table.insert(self.ordered_component,component)
end

-- 是否禁止注册角色?
function gg.is_close_createrole(account,ip)
    return false
end

-- 是否禁止进入游戏
function gg.is_close_entergame(account,ip)
    return false
end


-- 是否禁止该角色进入游戏
function gg.is_ban_entergame(player)
    return false
end
