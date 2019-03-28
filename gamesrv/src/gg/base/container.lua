--- 容器基类,可被继承，也可直接实例化
--@script gg.base.container
--@author sundream
--@release 2018/12/25 10:30:00
ccontainer = class("ccontainer")

--- ccontainer.new调用后执行的构造函数
--@param[type=table] param
--@return a ccontainer's instance
--@usage
--local container = ccontainer.new({
--	-- 所有字段均为可选字段
--	name = "test",
--	onclear = xxx,
--	onadd = xxx,
--	ondel = xxx,
--	onupdate = xxx,
--	key2id = xxx,
--	id2key = xxx,
--})
function ccontainer:init(param)
	param = param or {}
	self.name = param.name
	self:register(param)
	self.objid = 0
	self.len = 0
	self.objs = {}
end

--- 清空所有数据
function ccontainer:clear()
	local objs = self.objs
	self.objs = {}
	self.len = 0
	if self.onclear then
		self:onclear(objs)
	end
end

-- 可重写
function ccontainer:id2key(id)
	return tostring(id)
end

-- 可重写
function ccontainer:key2id(id)
	return tonumber(id)
end

--- 反序列化
--@param[type=table] data 准备反序列化的数据表
--@param[type=func,opt] loadfunc 容器元素数据的反序列化函数
function ccontainer:load(data,loadfunc)
	if not data or not next(data) then
		return
	end
	self.objid = data.objid
	local objs = data.objs or {}
	local len = 0
	for id,objdata in pairs(objs) do
		id = self:key2id(id)
		local obj
		if loadfunc then
			obj = loadfunc(objdata)
		else
			obj = objdata
		end
		if obj then
			self.objs[id] = obj
			len = len + 1
		end
	end
	self.len = len
end

--- 序列化
--@param[type=func,opt] savefunc 容器元素数据的序列化函数
--@return[type=table] 序列化后的数据表
function ccontainer:save(savefunc)
	local data = {}
	data.objid = self.objid
	local objs = {}
	for id,obj in pairs(self.objs) do
		id = self:id2key(id)
		if savefunc then
			objs[id] = savefunc(obj)
		else
			objs[id] = obj
		end
	end
	data.objs = objs
	return data
end

--- 注册回调函数
--@param[type=table] callback 回调函数表
--@usage
--container:register({
--	onclear = xxx,
--	onadd = xxx,
--	ondel = xxx,
--	onupdate = xxx,
--	key2id = xxx,
--	id2key = xxx,
--})
function ccontainer:register(callback)
	if callback then
		if callback.onclear then
			self.onclear = callback.onclear
		elseif callback.onadd then
			self.onadd = callback.onadd
		elseif callback.ondel then
			self.ondel = callback.ondel
		elseif callback.onupdate then
			self.onupdate = callback.onupdate
		elseif callback.key2id then
			self.key2id = callback.key2id
		elseif callback.id2key then
			self.id2key = callback.id2key
		end
	end
end

function ccontainer:genid()
	repeat
		self.objid = self.objid + 1
	until self.objs[self.objid] == nil
	return self.objid
end

--- 添加元素
--@param[type=table] obj 元素对象
--@param[type=int|string,opt] id 元素ID,不填则自动生成
--@return[type=int|string] 元素的ID
function ccontainer:add(obj,id)
	id = id or self:genid()
	assert(self.objs[id]==nil,"Exist Object:" .. tostring(id))
	self.objs[id] = obj
	self.len = self.len + 1
	if self.onadd then
		self:onadd(id,obj)
	end
	return id
end

--- 删除元素
--@param[type=int|string] id 元素ID
--@return[type=table] 该ID对应的元素,无则返回nil
function ccontainer:del(id)
	local obj = self:get(id)
	if obj then
		self.objs[id] = nil
		self.len = self.len - 1
		if self.ondel then
			self:ondel(id,obj)
		end
		return obj
	end
end

--- 更新元素
--@param[type=int|string] id 元素ID
--@param[type=table] attrs 更新的属性表
function ccontainer:update(id,attrs)
	local obj = self:get(id)
	if obj then
		for k,v in pairs(attrs) do
			obj[k] = v
		end
		if self.onupdate then
			self:onupdate(id,attrs)
		end
	end
end

--- 获取元素
--@param[type=int|string] id 元素ID
--@return[type=table] 该ID对应的元素,无则返回nil
function ccontainer:get(id)
	return self.objs[id]
end

return ccontainer
