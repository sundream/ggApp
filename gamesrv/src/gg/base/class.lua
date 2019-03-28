---功能: 给lua oop提供原语class,支持热更新，支持父类热更新直接
--反应到子类,不支持删除成员函数，需要屏蔽时可以写成空函数,
--参考: blog.codingnow.com/cloud/LuaOO
--@script gg.base.class
--@usage cthisweek = class("cthisweek",ctoday)
__class = __class or {}
local function reload_class(name)
	local class_type = assert(__class[name],"try to reload a non-exist class")
	local vtb = __class[class_type]
	assert(vtb ~= nil,"class without vtb")
	-- 清空类缓存的父类方法
	for k,v in pairs(vtb) do
		vtb[k] = nil
	end
	local super = class_type.__super
	for _,super_class in ipairs(super) do
		if super_class.__child then
			super_class.__child[class_type.__name] = true
		end
	end
	--print(string.format("reload class,name=%s class_type=%s vtb=%s",name,class_type,vtb))
	return class_type
end

local function update_hierarchy(name)
	local class_type = assert(__class[name],"try to update_hierarchy a non-exist class")
	reload_class(name)
	for name,_ in pairs(class_type.__child) do
		update_hierarchy(name)
	end
end

local function ajust_super(super)
	local pos
	for i,super_class in ipairs(super) do
		if not super_class.__child then
			pos = i
			break
		end
	end
	if pos then
		local selfattr = table.remove(super,pos)
		assert(selfattr)
		table.insert(super,1,selfattr)
	end
	return super
end

-- 设置自身类属性(功能同ajust_super)
local function set_super(class_type,super)
	local pos
	for i,super_class in ipairs(super) do
		if not super_class.__child then
			pos = i
			break
		end
	end
	if pos then
		local selfattr = table.remove(super,pos)
		for k,v in pairs(selfattr) do
			class_type[k] = v
		end
	end
	class_type.__super = super
	return super
end

-- 保证每个类名不同
function class(name,...)
	local super = {...}
	local class_type
	if not __class[name] then
		class_type = {}
		class_type.__child = {}
	else
		class_type = __class[name]
	end
	class_type.__name = name
	class_type.__super = ajust_super(super)
	--set_super(class_type,super)
	class_type.init = false		--constructor
	class_type.ctor = false
	class_type.new = function (...)
		local tmp = ...
		assert(tmp ~= class_type,string.format("must use %s.new(...) but not %s:new(...)",name,name))
		local self = {}
		self.__type = class_type
		setmetatable(self,{__index = class_type});
		do
			if class_type.init then
				class_type.init(self,...)
			elseif class_type.ctor then
				class_type.ctor(self,...)
			end
		end
		return self
	end
	if not __class[name] then -- if not getmetatable(class_type) then
		local vtb = {}	-- 仅用于缓存父类方法
		__class[name] = class_type
		__class[class_type] = vtb
		setmetatable(class_type,{__index = vtb,})
		setmetatable(vtb,{__index =
			function (t,k)
				for _,super_type in ipairs(class_type.__super) do
					local result = super_type[k]
					if result ~= nil then
						vtb[k] = result
						return result
					end
				end
			end
		})
	end
	update_hierarchy(name)
	return class_type
end

function issubclass(cls1,cls2)
	if not cls1.__name then
		return false
	end
	if not cls2.__child then
		return false
	end
	return cls2.__child[cls1.__name] and true or false
end

function typename(obj)
	if obj.__name then --a class
		return obj.__name
	end
	if obj.__type then
		return obj.__type.__name
	end
	return type(obj)
end

function isinstance(obj,cls)
	if not cls then
		return false
	end
	local classname = assert(cls.__name,"parameter 2 must be a class")
	if typename(obj) == classname then
		return true
	end
	for classname,_ in pairs(cls.__child) do
		if isinstance(obj,__class[classname]) then
			return true
		end
	end
	return false
end
