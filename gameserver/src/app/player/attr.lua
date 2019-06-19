-- 玩家基本属性存盘/载入逻辑
-- 考虑效率,基本属性如金币,没有用player.data来管理,而是直接放在玩家身上
local cattr = class("cattr")

function cattr:init(player)
    self.player = player
    self.player.lv = 1
    self.player.name = nil
    self.player.lang = "zh_CN"
    self.player.gold = 0
    self.player.sex = 1
    self.player.account = nil
    self.player.raw_account = nil
    self.player.createtime = 0
    self.player.logintime = 0
end

function cattr:unserialize(data)
    assert(not table.isempty(data),"role no attr:" .. tostring(self.player.pid))
    for k,v in pairs(data) do
        self.player[k] = v
    end
end

function cattr:serialize()
    local data = {}
    data.lv = self.player.lv
    data.name = self.player.name
    data.lang = self.player.lang
    data.gold = self.player.gold
    data.account = self.player.account
    data.raw_account = self.player.raw_account
    data.createtime = self.player.createtime
    data.logintime = self.player.logintime
    return data
end

function cattr:pack()
    return self:serialize()
end


return cattr
