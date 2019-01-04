cattrcontainer = class("cattrcontainer")

function cattrcontainer:init(args)
	self.attrs = {}
	for name,obj in pairs(args) do
		assert(self.attrs[name] == nil)
		self.attrs[name] = true
		self[name] = obj
	end
end

function cattrcontainer:get(name)
	if not self.attrs[name] then
		return
	end
	return self[name]
end

function cattrcontainer:add(name,obj)
	assert(self.attrs[name] == nil)
	self.attrs[name] = true
	self[name] = obj
end

function cattrcontainer:del(name)
	local obj = self:get(name)
	if not obj then
		return
	end
	self.attrs[name] = nil
	self[name] = nil
	return obj
end

function cattrcontainer:load(data)
	if table.isempty(data) then
		return
	end
	for name,attrdata in pairs(data) do
		local obj = self:get(name)
		if obj then
			obj:load(attrdata)
		end
	end
end

function cattrcontainer:save()
	local data = {}
	for name in pairs(self.attrs) do
		local obj = self:get(name)
		data[name] = obj:save()
	end
	return data
end

function cattrcontainer:clear()
	for name in pairs(self.attrs) do
		local obj = self:get(name)
		if obj.clear then
			obj:clear()
		end
	end
end

function cattrcontainer:exec(method,...)
	for name in pairs(self.attrs) do
		local obj = self:get(name)
		local func = obj[method]
		if func then
			func(obj,...)
		end
	end
end
