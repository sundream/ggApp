---今日数据: ctoday
--@script gg.base.time.today
--@author sundream
--@release 2019/3/29 14:00:00

local DAY_START_HOUR = 0    -- 作为一天开始的小时
local WEEK_START_DAY = 1    -- 作为一周开始的天数
local WEEK_START_DAY2 = 0   -- 作为一周开始的天数(thisweek2)
local MONTH_START_DAY = 1   -- 作为每月开始的天数


--- ctoday类: 保存生命期为今日的数据
local cdatabaseable = gg.class.cdatabaseable
local ctoday = class("ctoday",cdatabaseable)

--- ctoday.new#conf字段定义
--@field[opt=0] day_start_hour 作为一天开始的小时
--@field[opt=1] week_start_day 作为一周开始的天数
--@field[opt=0] week_start_day2 作为一周开始的天数(thisweek2)
--@field[opt=0] month_start_day 作为每月开始的天数
--@field[opt] onclear 数据过期时的回调函数
--@table ctoday_conf


--- ctoday.new调用后执行的构造函数
--@param[type=table] conf see @{ctoday_conf}
--@return a ctoday's instance
--@usage local today = ctoday.new()
function ctoday:init(conf)
    conf = conf or {}
    cdatabaseable.init(self)
    local hour = gg.time.hour()
    local nowday = gg.time.dayno()
    self.day_start_hour = conf.day_start_hour or DAY_START_HOUR
    self.week_start_day = conf.week_start_day or WEEK_START_DAY
    self.week_start_day2 = conf.week_start_day2 or WEEK_START_DAY2
    self.month_start_day = conf.month_start_day or MONTH_START_DAY
    self.dayno = hour < self.day_start_hour and nowday - 1 or nowday
    self.objs = {}
    if conf.objs then
        for k,v in pairs(conf.objs) do
            self:setobject(k,v)
        end
    end
    if conf.onclear then
        self.onclear = conf.onclear
    end
end

--- 序列化
--@return 序列化后的数据表
function ctoday:serialize()
    local data = {}
    data["dayno"] = self.dayno
    data["data"] = self.data
    local objdata = {}
    for k,obj in pairs(self.objs) do
		if obj.serialize then
			objdata[k] = obj:serialize()
		end
    end
    data["objs"] = objdata
    return data
end

--- 反序列化
--@param[type=table] data 准备反序列化的数据表
function ctoday:unserialize(data)
    if not data or not next(data) then
        return
    end
    self.dayno = data["dayno"]
    self.data = data["data"]
    local objdata = data["objs"] or {}
    for k,v in pairs(objdata) do
		local obj = self.objs[k]
		if obj.unserialize then
			obj:unserialize(v)
		end
    end
end

--- 清空所有数据
--@param[type=int,opt] olddayno 天编号
--@usage today:clear()
function ctoday:clear(olddayno)
    olddayno = olddayno or self.dayno
    local data = self.data
    cdatabaseable.clear(self)
    if self.onclear then
        self.onclear(data,olddayno)
    end
	for key,obj in pairs(self.objs) do
		if obj.clear then
			obj:clear()
		end
		self:setobject(key,obj)
	end
end

--- 设置
--@param[type=string] key 键
--@param[type=any] val 值
--@usage today:set("key",1)
--@usage today:set("k1.k2.k3","hi")
function ctoday:set(key,val)
    self:checkvalid()
    return cdatabaseable.set(self,key,val)
end

--- 获取
--@param[type=string] key 键
--@param[type=any] default 默认值
--@return[type=any] 该键保存的数据
--@usage local val = today:get("key",0)
--@usage local val = today:get("k1.k2.k3")
function ctoday:get(key,default)
    self:checkvalid()
    return cdatabaseable.get(self,key,default)
end

--- [deprecated] get的别名
ctoday.query = ctoday.get

--- 增加
--@param[type=string] key 键(增加时一般需要保证该键对应的值为整数类型)
--@param[type=number] val 增加的值
--@return[type=any] 该键保存的旧数据
--@usage data:add("key",1)
function ctoday:add(key,val)
    self:checkvalid()
    return cdatabaseable.add(self,key,val)
end

function ctoday:checkvalid()
    local nowday = gg.time.dayno()
    if self.dayno == nowday then
        return
    end
    local hour = gg.time.hour()
    if self.dayno + 1 == nowday then
        if hour < self.day_start_hour then
            return
        end
    end
    self.olddayno = self.dayno
    self.dayno = hour < self.day_start_hour and nowday-1 or nowday
    self:clear(self.olddayno)
end

function ctoday:setobject(key,obj)
    self:set(key,true)
    self.objs[key] = obj
end

function ctoday:getobject(key)
	-- may trigger clear
    local exist = self:query(key,false)
    local obj = self.objs[key]
    assert(obj,"invalid object key:" .. tostring(key))
	return obj
end

return ctoday
