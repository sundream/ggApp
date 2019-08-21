local cplayer = class("cplayer")

function cplayer:init(pid)
    self.pid = assert(pid)
    self.attr = gg.class.cattr.new(self)
    self.data = gg.class.cdatabaseable.new()
    self.today = gg.class.ctoday.new()
    self.thistemp = gg.class.cthistemp.new()
    self.thisweek = gg.class.cthisweek.new()
    self.thisweek2 = gg.class.cthisweek2.new()
    self.thismonth = gg.class.cthismonth.new()
    self.today.onclear = gg.functor(self.oncleartoday,self)
    self.thisweek.onclear = gg.functor(self.onclearthisweek,self)
    self.time = gg.class.cattrcontainer.new({
        today = self.today,
        thistemp = self.thistemp,
        thisweek = self.thisweek,
        thisweek2 = self.thisweek2,
        thismonth = self.thismonth,
    })
    self.component = {}
    self.ordered_component = {}
    self:add_component("attr",self.attr)
    self:add_component("data",self.data)
    self:add_component("time",self.time)
    self.loadstate = "unload"
end

function cplayer:unserialize(toload)
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

function cplayer:serialize()
    local data = {}
    for name,obj in pairs(self.component) do
        if obj.serialize then
            data[name] = obj:serialize()
        end
    end
    return data
end

function cplayer:isloaded()
    return self.loadstate == "loaded"
end

function cplayer:onload()
    for i=1,#self.ordered_component do
        local obj = self.ordered_component[i]
        if obj.onload then
            obj:onload(self)
        elseif obj.exec then
            obj:exec("onload",self)
        end
    end
end

function cplayer.deletefromdatabase(pid)
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local key = string.format("role:%s",pid)
        db:del(key)
    else
        db.player:delete({pid=pid})
    end
end

function cplayer:savetodatabase()
    -- 保活token用以作快速重连
    if (not self.debuglogin) and self.token then
        gg.playermgr.tokens:expire(self.token,302)
    end
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local key = string.format("role:%s",self.pid)
        local data = self:serialize()
        for name,objdata in pairs(data) do
            objdata = cjson.encode(objdata)
            db:hset(key,name,objdata)
        end
    else
        local data = self:serialize()
        data.pid = self.pid
        db.player:update({pid=self.pid},data,true,false)
    end
end

function cplayer:loadfromdatabase()
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local data = {}
        local key = string.format("role:%s",self.pid)
        local list = db:hgetall(key)
        for i=1,#list,2 do
            local name,objdata = list[i],list[i+1]
            data[name] = cjson.decode(objdata)
        end
        self:unserialize(data)
    else
        local data = db.player:findOne({pid=self.pid})
        self:unserialize(data)
    end
    self:onload()
end

function cplayer:add_component(name,component)
    assert(self.component[name] == nil)
    self.component[name] = component
    table.insert(self.ordered_component,component)
end

function cplayer:create(conf)
    self.name = assert(conf.name)
    self.account = assert(conf.account)
    self.raw_account = self:get_raw_account()
    self.sex = assert(conf.sex)
    self.shapeid = conf.shapeid
    self.headPhoto = self.shapeid or "-1"
    self.createtime = conf.createtime or os.time()
end

function cplayer:entergame(replace)
    -- oncreate 放到首次登录时执行,create调用时player未纳入playermgr管理
    local logincnt = self:get("logincnt") or 0
    if logincnt == 0 then
        self:add("logincnt",1)
        self:oncreate()
    end
    self:del_delay_exitgame()
    self:onlogin(replace)
end

--- 主动掉线
--@breif 主动掉线会触发退出游戏流程
--@param[type=string] reason 原因
function cplayer:disconnect(reason)
    if self:isdisconnect() then
        return
    end
    self:ondisconnect(reason)
    local linkobj = self.linkobj
    gg.playermgr:unbind_linkobj(self)
    gg.actor.client:dellinkobj(linkobj.linkid)
    -- 顶号不退出游戏
    if reason ~= "replace" then
        self:exitgame(reason)
    end
end

function cplayer:exitgame(reason)
    if not self.force_exitgame then
        self:try_set_exitgame_time()
        local ok,delay_time = self:need_delay_exitgame()
        if ok then
            self:delay_exitgame(delay_time)
            return
        end
    end
    -- keep before onlogout!
    self:del_delay_exitgame()
    self.force_exitgame = nil
    xpcall(self.onlogout,gg.onerror,self,reason)
    -- will call savetodatabase
    gg.playermgr:delplayer(self.pid)
end

function cplayer:isdisconnect()
    if not self.linkobj then
        return true
    end
    return false
end

-- 跨服前处理流程
function cplayer:on_go_server(go_serverid)
end

function cplayer:synctoac(online)
    skynet.fork(self._synctoac,self,online)
end

function cplayer:_synctoac(online)
    local role = {
        roleid = self.pid,
        name = self.name,
        lv = self.lv,
        gold = self.gold,
        diamond = self.diamond,
        now_serverid = gg.server.id,
        online = online,

        job = self.job,
        shapeid = self.shapeid,
    }
    gg.loginserver:updaterole(self.pid,role)
end

function cplayer:oncreate()
    local my_serverid = gg.server.id
    logger.logf("info","login","op=oncreate,serverid=%s,account=%s,pid=%s,name=%s,linktype=%s,linkid=%s,ip=%s,port=%s,version=%s,name=%s",
        my_serverid,self.account,self.pid,self.name,self.linktype,self.linkid,self.ip,self.port,self.version,self.name)
    for i=1,#self.ordered_component do
        local obj = self.ordered_component[i]
        obj.loadstate = "loaded"
        if obj.oncreate then
            obj:oncreate(self)
        elseif obj.exec then
            obj:exec("oncreate",self)
        end
    end
end

-- 兼容处理
function cplayer:compat(replace)
    -- TODO: something
    self:compat_todo_delete(replace)
end

-- 开发阶段数据兼容的代码，正式上线后删除
function cplayer:compat_todo_delete(replace)
end

function cplayer:onlogin(replace)
    self.logintime = os.time()
    local my_serverid = gg.server.id
    local from_serverid = self.kuafu_forward and self.kuafu_forward.from_serverid
    logger.logf("info","login","op=onlogin,serverid=%s,from_serverid=%s,account=%s,pid=%s,name=%s,linktype=%s,linkid=%s,ip=%s,port=%s,replace=%s,version=%s",
        my_serverid,from_serverid,self.account,self.pid,self.name,self.linktype,self.linkid,self.ip,self.port,replace,self.version)
    self:compat(replace)
    -- 上线立即检查过期数据
    self.today:checkvalid()
    self.thisweek:checkvalid()
    self.thisweek2:checkvalid()
    self.thismonth:checkvalid()
    for i=1,#self.ordered_component do
        local obj = self.ordered_component[i]
        if obj.onlogin then
            obj:onlogin(self,replace)
        elseif obj.exec then
            obj:exec("onlogin",self,replace)
        end
    end
    if self.kuafu_forward then
        local kuafu_forward = self.kuafu_forward
        self.kuafu_forward = nil
        if kuafu_forward.onlogin then
            local onlogin = gg.unpack_function(kuafu_forward.onlogin)
            xpcall(onlogin,gg.onerror)
        end
    end
    self:synctoac(true)
end

function cplayer:onlogout(reason)
    local my_serverid = gg.server.id
    local from_serverid = self.kuafu_forward and self.kuafu_forward.from_serverid
    logger.logf("info","login","op=onlogout,serverid=%s,from_serverid=%s,account=%s,pid=%s,name=%s,linktype=%s,linkid=%s,ip=%s,port=%s,version=%s,reason=%s",
        my_serverid,from_serverid,self.account,self.pid,self.name,self.linktype,self.linkid,self.ip,self.port,self.version,reason)
    for i=#self.ordered_component,1,-1 do
        local obj = self.ordered_component[i]
        if obj.onlogout then
            obj:onlogout(self,reason)
        elseif obj.exec then
            obj:exec("onlogout",self,reason)
        end
    end
    self:synctoac(false)
end

function cplayer:ondisconnect(reason)
    logger.logf("info","login","op=ondisconnect,pid=%s,name=%s,linktype=%s,linkid=%s,ip=%s,port=%s,reason=%s",
        self.pid,self.name,self.linktype,self.linkid,self.ip,self.port,reason)
    for i=#self.ordered_component,1,-1 do
        local obj = self.ordered_component[i]
        if obj.ondisconnect then
            obj:ondisconnect(self,reason)
        elseif obj.exec then
            obj:exec("ondisconnect",self,reason)
        end
    end
end

function cplayer:ondayupdate()
    -- 天更新时立即检查过期数据
    self.today:checkvalid()
    self.thisweek:checkvalid()
    self.thisweek2:checkvalid()
    self.thismonth:checkvalid()
    for i=1,#self.ordered_component do
        local obj = self.ordered_component[i]
        if obj.ondayupdate then
            obj:ondayupdate()
        elseif obj.exec then
            obj:exec("ondayupdate")
        end
    end
end

function cplayer:onmondayupdate()
    for i=1,#self.ordered_component do
        local obj = self.ordered_component[i]
        if obj.onmondayupdate then
            obj:onmondayupdate()
        elseif obj.exec then
            obj:exec("onmondayupdate")
        end
    end
end

function cplayer:onmonthupdate()
end

function cplayer:onhourupdate()
end

function cplayer:oncleartoday(data,dayno)
end

function cplayer:onclearthisweek(data,dayno)
end

function cplayer:genid()
    return self:add("id",1)
end

function cplayer:get(key,default)
    return self.data:get(key,default)
end

function cplayer:set(key,val)
    return self.data:set(key,val)
end

function cplayer:add(key,val)
    return self.data:add(key,val)
end

function cplayer:del(key)
    return self.data:del(key)
end

function cplayer:get_raw_account()
    if not self.raw_account then
        local pos = string.find(self.account,"@")
        if pos then
            self.raw_account = string.sub(self.account,1,pos-1)
        else
            self.raw_account = self.account
        end
    end
    return self.raw_account
end

function cplayer:try_set_exitgame_time()
    local now = os.time()
    if self.getWar and self:getWar() then
        -- 战斗中延迟60s下线
        local exitgame_time = self:get_exitgame_time()
        if not exitgame_time or exitgame_time <= now then
            self:set_exitgame_time(now+60)
        end
    end
    -- 其他玩法需要延迟下线,自行设置时间
end

return cplayer
