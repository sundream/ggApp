local cplayermgr = class("cplayermgr")

--/*
-- 管理在线玩家
--*/
function cplayermgr:init()
    self.onlinenum = 0
    self.onlinelimit = tonumber(skynet.getenv("onlinelimit")) or 10240
    self.players = gg.class.ccontainer.new()
    -- token
    self.tokens = gg.class.cthistemp.new()
end

function cplayermgr:getplayer(pid)
    return self.players:get(pid)
end

function cplayermgr:addplayer(player)
    local pid = assert(player.pid)
    self.players:add(player,pid)
    if player.linkobj then
        player.is_temp_load = nil
        player._is_online = true
        self.onlinenum = self.onlinenum + 1
    end
    player.savename = string.format("player.%s",pid)
    gg.savemgr:autosave(player)
end

-- 在线玩家删除不能调用该接口,用self.kick代替
function cplayermgr:delplayer(pid)
    local player = self:getplayer(pid)
    if player then
        if player._is_online then
            self.onlinenum = self.onlinenum - 1
        end
        --player:savetodatabase()
        gg.savemgr:nowsave(player)
        gg.savemgr:closesave(player)
        self.players:del(pid)
    end
    return player
end

-- 返回在线玩家对象(不包括托管对象)
function cplayermgr:getonlineplayer(pid)
    local player = self:getplayer(pid)
    if player then
        if player.linkobj then
            return player
        end
    end
end

function cplayermgr:bind_linkobj(player,linkobj)
    --logger.logf("info","playermgr","op=bind_linkobj,pid=%s,linkid=%s,linktype=%s,ip=%s,port=%s",
    --  player.pid,linkobj.linkid,linkobj.linktype,linkobj.ip,linkobj.port)
    linkobj:bind(player.pid)
    player.linkobj = linkobj
    player.is_temp_load = nil
    self:transfer_mark(player,linkobj)
end

function cplayermgr:unbind_linkobj(player)
    local linkobj = assert(player.linkobj)
    --logger.logf("info","playermgr","op=unbind_linkobj,pid=%s,linkid=%s,linktype=%s,ip=%s,port=%s",
    --  player.pid,linkobj.linkid,linkobj.linktype,linkobj.ip,linkobj.port)
    player.linkobj:unbind()
    player.linkobj = nil
end

function cplayermgr:allplayer()
    return table.keys(self.players.objs)
end

function cplayermgr:kick(pid,reason)
    reason = reason or "kick"
    local player = self:getplayer(pid)
    if not player then
        return
    end
    player.force_exitgame = true
    if player:isdisconnect() then
        -- 托管玩家掉线后还会维持玩家对象
        -- 踢出托管对象让其退出游戏即可
        player:exitgame(reason)
    else
        player:disconnect(reason)
    end
end

function cplayermgr:kickall(reason)
    --loginqueue.clear()
    for _,pid in ipairs(self:allplayer()) do
        self:kick(pid,reason)
    end
end

function cplayermgr:createplayer(pid,conf)
    --logger.logf("info","playermgr","op=createplayer,pid=%d,player=%s",pid,conf)
    local player = gg.class.cplayer.new(pid)
    player:create(conf)
    --player:savetodatabase()
    player.savename = string.format("player.%s",pid)
    gg.savemgr:oncesave(player)
    gg.savemgr:nowsave(player)
    gg.savemgr:closesave(player)
    return player
end

function cplayermgr:_loadplayer(pid)
    local player = gg.class.cplayer.new(pid)
    player:loadfromdatabase()
    return player
end

-- 角色不存在返回nil
function cplayermgr:recoverplayer(pid)
    assert(tonumber(pid),"invalid pid:" .. tostring(pid))
    assert(self:getplayer(pid) == nil,"try recover a loaded player:" .. tostring(pid))
    local id = string.format("player.%s",pid)
    local ok,player = gg.sync:once_do(id,self._loadplayer,self,pid)
    assert(ok,player)
    if player:isloaded() then
        return player
    else
        return nil
    end
end

function cplayermgr:isloading(pid)
    local id = string.format("player.%s",pid)
    if gg.sync.tasks[id] then
        return true
    end
    return false
end

---临时载入玩家(通常在需要载入离线玩家时使用)
--@usage
--必须和unloadplayer成对出现
--local player = self.loadplayer(pid)
--pcall(function ()
--  -- do something
--end)
--self.unloadplayer(pid)
function cplayermgr:loadplayer(pid)
    local player = self:getplayer(pid)
    if player then
        return player
    end
    player = self:recoverplayer(pid)
    if not player then
        return
    end
    player.is_temp_load = true
    if not self:getplayer(pid) then
        self:addplayer(player)
    end
    return player
end

--- 卸载玩家(和loadplayer成对出现)
function cplayermgr:unloadplayer(pid)
    local player = self:getplayer(pid)
    if not player then
        return
    end
    if not player.is_temp_load then
        return
    end
    player.is_temp_load = nil
    self:delplayer(pid)
end

--/*
-- 转移标记
--*/
function cplayermgr:transfer_mark(player,linkobj)
    player.linktype = linkobj.linktype
    player.linkid = linkobj.linkid
    player.ip = linkobj.ip
    player.port = linkobj.port
    player.version = linkobj.version
    player.token = linkobj.token
    player.debuglogin = linkobj.debuglogin
    -- 跨服传递的数据
    player.kuafu_forward = linkobj.kuafu_forward
end

function cplayermgr:broadcast(func)
    for i,pid in ipairs(self:allplayer()) do
        local player = self:getplayer(pid)
        if player then
            xpcall(func,gg.onerror,player)
        end
    end
end

-- 托管玩家数
function cplayermgr:tuoguannum()
    local tuoguannum = 0
    for pid,player in pairs(self.players.objs) do
        if not player.linkobj then
            tuoguannum = tuoguannum + 1
        end
    end
    return tuoguannum
end

return cplayermgr