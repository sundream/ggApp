-- 玩家基本属性存盘/载入逻辑
-- 考虑效率,基本属性如金币,没有用player.data来管理,而是直接放在玩家身上
cattr = class("cattr")

function cattr:init(player)
	self.player = player
	self.player.lv = 1
	self.player.name = nil
	self.player.lang = "zh_CN"
	self.player.gold = 0
end

function cattr:load(data)
	assert(not table.isempty(data),"role no attr:" .. tostring(self.player.pid))
	for k,v in pairs(data) do
		self.player[k] = v
	end
end

function cattr:save()
	local data = {}
	data.lv = self.player.lv
	data.name = self.player.name
	data.lang = self.player.lang
	data.gold = self.player.gold
	data.account = self.player.account
	return data
end

function cattr:pack()
	return self:save()
end

return cattr
