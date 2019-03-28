---键值对数据管理基类,可被继承,也可直接实例化
--@script gg.base.databaseable
--@author sundream
--@release 2018/12/25 10:30:00
cdatabaseable = class("cdatabaseable")

--- cdatabaseable.new调用后执行的构造函数
--@usage local data = cdatabaseable.new()
function cdatabaseable:init()
	self.loadstate = "unload"
	self.dirty = true
	self.data = {}
end

--- 序列化
--@return 序列化后的数据表
function cdatabaseable:save()
	return self.data
end

--- 反序列化
--@param[type=table] data 准备反序列化的数据表
function cdatabaseable:load(data)
	if not data or not next(data) then
		return
	end
	self.data = data
end

--- 清空所有数据
function cdatabaseable:clear()
	self.dirty = false
	self.data = {}
end

--- 管理的数据是否已有脏数据
--@return[type=bool] 是否已有脏数据
function cdatabaseable:isdirty()
	return self.dirty
end

function cdatabaseable:__getattr(data,attrs)
	return table.query(data,attrs)
end

function cdatabaseable:__split(key)
	return string.split(key,".")
end

--- 获取
--@param[type=string] key 键
--@param[type=any] default 默认值
--@return[type=any] 该键保存的数据
--@usage local val = data:get("key",0)
--@usage local val = data:get("k1.k2.k3")
function cdatabaseable:get(key,default)
	local attrs = self:__split(key)
	local val = self:__getattr(self.data,attrs)
	if val ~= nil then
		return val
	else
		return default
	end
end

--- [deprecated] get的别名
cdatabaseable.query = cdatabaseable.get

function cdatabaseable:__setattr(data,attrs,val)
	local oldval = table.setattr(data,attrs,val)
	self.dirty = true
	return oldval
end

--- 设置
--@param[type=string] key 键
--@param[type=any] val 值
--@usage data:set("key",1)
--@usage data:set("k1.k2.k3","hi")
function cdatabaseable:set(key,val)
	local attrs = self:__split(key)
	return self:__setattr(self.data,attrs,val)
end

--- 增加
--@param[type=string] key 键(增加时一般需要保证该键对应的值为整数类型)
--@param[type=number] val 增加的值
--@return[type=any] 该键保存的旧数据
--@usage data:add("key",1)
function cdatabaseable:add(key,val)
	local oldval = self:get(key)
	local newval
	if oldval == nil then
		newval = val
	else
		newval = oldval + val
	end
	return self:__setattr(self.data,key,newval)
end

function cdatabaseable:__delattr(data,attrs)
	local lastkey = table.remove(attrs)
	local mod = self:__getattr(data,attrs)
	if mod == nil then
		return nil
	end
	local oldval = mod[lastkey]
	mod[lastkey] = nil
	self.dirty = true
	return oldval
end

--- 删除
--@param[type=string] key 键
--@return[type=any] 该键保存的旧数据
--@usage data:del("key")
--@usage data:del("k1.k2.k3")
function cdatabaseable:del(key)
	local attrs = self:__split(key)
	return self:__delattr(self.data,attrs)
end

--- [deprecated] del的别名
cdatabaseable.delete = cdatabaseable.del

return cdatabaseable
