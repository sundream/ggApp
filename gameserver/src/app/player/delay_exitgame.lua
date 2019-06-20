--- 延迟下线
--@script app.player.tuoguan
--@author sundream
--@release 2019/06/18 17:30:00
--@usage
--function cplayer:try_set_exitgame_time()
--    local now = os.time()
--    if self:getWar() then
--        -- 战斗中延迟60s下线
--        local exitgame_time = self:get_exitgame_time()
--        if not exitgame_time or exitgame_time <= now then
--            self:set_exitgame_time(now+60)
--        end
--    end
--    -- 其他玩法需要延迟下线,自行设置时间
--end
--
--function cplayer:entergame(replace)
--    self:del_delay_exitgame()
--    -- 以下为进入游戏流程
--    self:onlogin(replace)
--end
--
--function cplayer:exitgame(reason)
--    -- 这里根据设计,设置延迟下线时间点
--    if not self.force_exitgame then
--        self:try_set_exitgame_time()
--        local ok,delay_time = self:need_delay_exitgame()
--        if ok then
--            self:delay_exitgame(delay_time)
--            return
--        end
--    end
--    -- keep before onlogout!
--    self:del_delay_exitgame()
--    -- 以下为下线流程
--    self.force_exitgame = nil
--    xpcall(self.onlogout,gg.onerror,self,reason)
--    -- will call savetodatabase
--    playermgr.delplayer(self.pid)
--end

local cplayer = gg.class.cplayer

--- 是否需要延迟下线(比如战斗中/或者玩法设计需要延迟下线时)
--@return [type=bool] 是否需要延迟下线
--@return [type=int] 如果需要延迟下线,需要延迟的时间
function cplayer:need_delay_exitgame()
    if not self.exitgame_time then
        return false
    else
        local now = os.time()
        local delay_time = self.exitgame_time - now
        return delay_time > 0,delay_time
    end
end

--- 获得退出游戏时间
--@return [type=int] 退出游戏时间点
function cplayer:get_exitgame_time()
    return self.exitgame_time
end

--- 设置退出游戏时间点(秒为单位),如果玩家已延迟下线,只有新设置的时间大于玩家已延迟下线时间点才有效
--@param [type=int] time 时间点
--@return [type=int] 之前设置的延迟时间点(没有则为nil)
function cplayer:set_exitgame_time(time)
    if not self.exitgame_time or self.exitgame_time < time then
        self.exitgame_time = time
    end
    return self.exitgame_time
end

function cplayer.__exitgame(pid)
    local player = playermgr.getplayer(pid)
    if player then
        player:exitgame("delay_exitgame")
    end
end

--- 延迟下线
--@param [type=int,opt=60] delay_time 延迟下线时间
--@return [type=int] 新开启的定时器ID
function cplayer:delay_exitgame(delay_time)
    if self.delay_exitgame_timerid then
        gg.timer:deltimer(self.delay_exitgame_timerid)
    end
    self.delay_exitgame_timerid = gg.timer:timeout("timer.delay_exitgame",delay_time,gg.functor(cplayer.__exitgame,self.pid))
    return self.delay_exitgame_timerid
end

--- 删除延迟下限定时器
function cplayer:del_delay_exitgame()
    self.exitgame_time = nil
    if self.delay_exitgame_timerid then
        local timerid = self.delay_exitgame_timerid
        self.delay_exitgame_timerid = nil
        gg.timer:deltimer(timerid)
        return timerid
    end
end

return cplayer
