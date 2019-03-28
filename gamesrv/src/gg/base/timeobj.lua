--- 带生命期数据管理容器模块,如
--今日数据: ctoday,
--本周(周一为起点)数据: cthisweek
--本周(周天为起点)数据: cthisweek2
--本月数据: cthismonth
--@script gg.base.timeobj
--@author sundream
--@release 2018/12/25 10:30:00

local DAY_START_HOUR = 0	-- 作为一天开始的小时
local WEEK_START_DAY = 1	-- 作为一周开始的天数
local WEEK_START_DAY2 = 0	-- 作为一周开始的天数(thisweek2)
local MONTH_START_DAY = 1	-- 作为每月开始的天数


--- ctoday类: 保存生命期为今日的数据
ctoday = class("ctoday",cdatabaseable)

--- ctoday.new#conf字段定义
--@field[opt=0] day_start_hour 作为一天开始的小时
--@field[opt=1] week_start_day 作为一周开始的天数
--@field[opt=0] week_start_day2 作为一周开始的天数(thisweek2)
--@field[opt=0] month_start_day 作为每月开始的天数
--@table ctoday_conf


--- ctoday.new调用后执行的构造函数
--@param[type=table] conf see @{ctoday_conf}
--@return a ctoday's instance
--@usage local today = ctoday.new()
function ctoday:init(conf)
	conf = conf or {}
	cdatabaseable.init(self)
	local hour = getdayhour()
	local nowday = getdayno()
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
	if conf.callback then
		self:register(conf.callback)
	end
end

--- 序列化
--@return 序列化后的数据表
function ctoday:save()
	local data = {}
	data["dayno"] = self.dayno
	data["data"] = self.data
	local objdata = {}
	for k,obj in pairs(self.objs) do
		objdata[k] = obj:save()
	end
	data["objs"] = objdata
	return data
end

--- 反序列化
--@param[type=table] data 准备反序列化的数据表
function ctoday:load(data)
	if not data or not next(data) then
		return
	end
	self.dayno = data["dayno"]
	self.data = data["data"]
	local objdata = data["objs"] or {}
	for k,v in pairs(objdata) do
		self.objs[k]:load(v)
	end
end

--- 注册onclear回调
--@param[type=func] callback onclear回调函数
function ctoday:register(callback)
	if type(callback) == "function" then
		self.onclear = callback
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
	--对象的清空操作放到getobject中执行，否则对象会被连续清空两次，无意义
--	for key,obj in pairs(self.objs) do
--		obj:clear()
--		self:setobject(key,obj)
--	end
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
	local nowday = getdayno()
	if self.dayno == nowday then
		return
	end
	local hour = getdayhour()
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
	local exist = self:query(key,false)
	local obj = self.objs[key]
	assert(obj,"invalid object key:" .. tostring(key))
	if not exist then
		obj:clear()
		self:setobject(key,obj)
	end
	return obj
end


--- cthisweek类: 保存生命期为本周(周一为起始点)的数据,继承自ctoday
cthisweek = class("cthisweek",ctoday)
function cthisweek:init(conf)
	ctoday.init(self,conf)
	local weekday = getweekday()
	local nowweek = getweekno()
	local hour = getdayhour()
	self.dayno = (weekday == 1 and hour < self.day_start_hour) and nowweek - 1 or nowweek
end

function cthisweek:checkvalid()
	local nowweek = getweekno()
	if self.dayno == nowweek then
		return
	end
	local weekday = getweekday()
	local hour = getdayhour()
	if self.dayno + 1 == nowweek then
		if weekday == self.week_start_day and hour < self.day_start_hour then
			return
		end
	end
	local olddayno = self.dayno
	self.dayno = (weekday == self.week_start_day and hour < self.day_start_hour) and nowweek - 1 or nowweek
	self:clear(olddayno)
end

--- cthisweek2类: 保存生命期为本周(周天为起始点)的数据,继承自ctoday
cthisweek2 = class("cthisweek2",ctoday)
function cthisweek2:init(conf)
	ctoday.init(self,conf)
	local weekday = getweekday()
	local nowweek2 = getweekno2()
	local hour = getdayhour()
	self.dayno = (weekday == self.week_start_day2 and hour < self.day_start_hour) and nowweek2 - 1 or nowweek2
end

function cthisweek2:checkvalid()
	local nowweek2 = getweekno2()
	if self.dayno == nowweek2 then
		return
	end
	local weekday = getweekday()
	local hour = getdayhour()
	if self.dayno + 1 == nowweek2 then
		if weekday == self.week_start_day2 and hour < self.day_start_hour then
			return
		end
	end
	local olddayno = self.dayno
	self.dayno = (weekday == self.week_start_day2 and hour < self.day_start_hour) and nowweek2 - 1 or nowweek2
	self:clear(olddayno)
end

--- cthismonth类: 保存生命期为本月的数据,继承自ctoday
cthismonth = class("cthismonth",ctoday)
function cthismonth:init(conf)
	ctoday.init(self,conf)
	local monthno = getmonthno()
	local monthday = getmonthday()
	local hour = getdayhour()
	self.dayno = (monthday == self.month_start_day and hour < self.day_start_hour) and monthno -1 or monthno
end

function cthismonth:checkvalid()
	local monthno = getmonthno()
	if self.dayno == monthno then
		return
	end
	local monthday = getmonthday()
	local hour = getdayhour()
	if self.dayno + 1 == monthno then
		if monthday == self.month_start_day and hour < self.day_start_hour then
			return
		end
	end
	self.olddayno = self.dayno
	self.dayno = (monthday == self.month_start_day and hour < self.day_start_hour) and monthno -1 or monthno
	self:clear(self.olddayno)
end

--- cthistemp类: 管理生命期为指定时间的对象
cthistemp = class("cthistemp",cdatabaseable)

function cthistemp:init()
	cdatabaseable.init(self)
	self.time = {}
end

--- 序列化
--@return 序列化后的数据表
function cthistemp:save()
	local data = {}
	data["data"] = self.data
	data["time"] = self.time
	return data
end

--- 反序列化
--@param[type=table] data 准备反序列化的数据表
function cthistemp:load(data)
	if not data or not next(data) then
		return
	end
	self.data = data["data"]
	self.time = data["time"]
end

--- 清空所有数据
function cthistemp:clear()
	cdatabaseable.clear(self)
	self.time = {}
end

function cthistemp:checkvalid(key)
	local attrs = self:__split(key)
	local expire = self:__getattr(self.time,attrs)
	if expire then
		local now = os.time()
		assert(type(expire) == "number",string.format("not-leaf-node:%s",key))
		if expire <= now then
			self:__setattr(self.time,attrs,nil)
			cdatabaseable.del(self,key)
			return false,nil
		end
	end
	return true,expire
end

--- 设置,首次设置必须指定生命期,未指定secs时,对象生命期不变
--@param[type=string] key 键
--@param[type=any] val 值
--@param[type=int] secs 超时值,秒为单位
--@param[type=func,opt] callback 超时回调
--@usage thistemp:set("firstset",1,10)
--@usage thistemp:set("firstset",20)	-- 只将值改成20，超时值不变
--@usage thistemp:set("firstset",10,20)	-- 值改成10,超时值改成未来20s
function cthistemp:set(key,val,secs)
	local expire = self:getexpire(key)
	local now = os.time()
	local new_expire
	if not expire then
		assert(secs)
		new_expire = now + secs
	else
		if secs then
			new_expire = now + secs
		else
			new_expire = expire
		end
	end
	local oldval = cdatabaseable.set(self,key,val)
	if expire ~= new_expire then
		local attrs = self:__split(key)
		self:__setattr(self.time,attrs,new_expire)
	end
	return oldval,expire
end

--- 增加
--@param[type=string] key 键(增加时一般需要保证该键对应的值为整数类型)
--@param[type=number] val 增加的值
--@usage
--		local oldval,expire = thistemp:get(key)
--		if nil == oldval then
--			local new_val = xxx
--			local new_expire = xxx
--			thistemp:set(key,new_val,new_expire)
--		else
--			thistemp:add(key,addval)
--		end
function cthistemp:add(key,val)
	return cdatabaseable.add(self,key,val)
end

--- 获取
--@param[type=string] key 键
--@param[type=any] default 默认值
--@return[type=any] 该键保存的数据
--@usage local val = thistemp:get("key",0)
--@usage local val = thistemp:get("k1.k2.k3")
function cthistemp:get(key,default)
	local expire = self:getexpire(key)
	return cdatabaseable.get(self,key,default),expire
end

--- [deprecated] get的别名
cthistemp.query = cthistemp.get

--- 删除
--@param[type=string] key 键
--@return[type=any] 该键保存的旧数据
--@usage thistemp:del("key")
--@usage thistemp:del("k1.k2.k3")
function cthistemp:del(key)
	local attrs = self:__split(key)
	return cdatabaseable.del(self,key),self:__delattr(self.time,attrs)
end

--- [deprecated] del的别名
cthistemp.delete = cthistemp.del

--- 获取过期时间点
--@param[type=string] key 键
--@return[type=int] 过期时间点
--@usage local expire = thistemp:getexpire("key")
--@usage local expire = thistemp:getexpire("k1.k2.k3")
function cthistemp:getexpire(key)
	local ok,expire = self:checkvalid(key)
	if not ok then
		return nil
	end
	return expire
end

cthistemp.getexceedtime = cthistemp.getexpire

--- 获取剩余超时值TTL
--@param[type=string] key 键
--@return[type=int] 剩余超时值TTL,秒为单位
--@usage local ttl = thistemp:ttl("key")
--@usage local ttl = thistemp:ttl("k1.k2.k3")
function cthistemp:ttl(key)
	local expire = self:getexpire(key)
	if not expire then
		return nil
	end
	return expire - os.time()
end

--- 延长生命周期(对已失效的key值无效)
--@param[type=string] key 键
--@param[type=int] expire 设置的过期时间点,秒为单位
--@return[type=int] 旧的过期时间点
function cthistemp:expireat(key,expire)
	local old_expire = self:getexpire(key)
	if not old_expire then
		return
	end
	local now = os.time()
	if expire <= now then
		self:del(key)
	else
		local attrs = self:__split(key)
		self:__setattr(self.time,attrs,expire)
	end
	return old_expire
end

--- 延长生命周期(对已失效的key值无效)
--@param[type=string] key 键
--@param[type=int] ttl 新的超时值,等价于expireat(key,os.time()+ttl)
--@return[type=int] 旧的过期时间点
function cthistemp:expire(key,ttl)
	return self:expireat(key,os.time()+ttl)
end

cthistemp.delay = cthistemp.expire
