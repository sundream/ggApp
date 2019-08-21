--- 匹配管理器
--@script gg.base.container
--@author sundream
--@release 2019/06/17 10:30:00
--@usage
--创建一个以id字段为关键字,k1降序,k2降序,expire_time升序排名的匹配管理器
--local matchmgr = gg.class.cmatchmgr.new(
-- timeout = 30,        -- 匹配超时值
-- tick = 5,            -- 每隔多少秒匹配一次
-- step = 2,            -- xx人匹配成一组
-- on_timeout = function (rank) end,    -- 匹配超时回调
-- on_success = function (rank) end,    -- 匹配成功回调
-- ids = {"id"},
-- sortids = {
--  {key="score",desc=true,}
--  {key="lv",desc=true,},
--  {key="expire_time"},
-- }
--})
local cmatchmgr = class("cmatchmgr")

function cmatchmgr:init(conf)
    self.timeout = assert(conf.timeout)    -- 多久过后匹配超时
    self.tick = assert(conf.tick)          -- 每隔多少秒匹配一次
    self.tick = self.tick * 100
    self.step = assert(conf.step)          -- 多少人一组进行匹配

    self.on_timeout = conf.on_timeout   -- 匹配超时回调
    self.on_success = conf.on_success   -- 匹配成功回调

    self.ids = assert(conf.ids)
    self.sortids = assert(conf.sortids)
    self.ranks = gg.class.cranks.new("cmatchmgr",self.ids,self.sortids)
end

--- 正在匹配中
function cmatchmgr:is_matching(...)
    if self.ranks:get(...) then
        return true
    end
    return false
end

--- 加入匹配
--@param[type=table] rank 匹配对象,必须包含ids和sortids中指定的字段
function cmatchmgr:match(rank)
    local ids = self.ranks:get_ids(rank)
    if self:is_matching(ids) then
        return
    end
    local now = os.time()
    rank.expire_time = now + self.timeout
    self.ranks:add(rank)
end

--- 取消匹配
function cmatchmgr:unmatch(...)
    self.ranks:del(...)
end

--- 开启匹配定时器
function cmatchmgr:start_timer()
    skynet.timeout(self.tick,function ()
        if self.cancel_timer then
            return
        end
        self:start_timer()
    end)
    while self.ranks.length >= self.step do
        local ranks = {}
        for i = 1, self.step do
            table.insert(ranks,self.ranks:delbypos(1))
        end
        if self.on_success then
            self.on_success(ranks)
        end
    end
    local now = os.time()
    for i=self.ranks.length,1,-1 do
        local rank = self.ranks:getbypos(i)
        if now >= rank.expire_time then
            self.ranks:delbypos(i)
            if self.on_timeout then
                self.on_timeout(rank)
            end
        end
    end
end

--- 关闭匹配定时器
function cmatchmgr:stop_timer()
    self.cancel_timer = true
end

return cmatchmgr
