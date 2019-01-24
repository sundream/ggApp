local Router = {}
Router.__index = Router

function Router:new()
	local self = {}
	setmetatable(self,Router)
	self.handles = {}
	return self
end

function Router:register(uri,handle)
	self.handles[uri] = handle
end

function Router:unregister(uri)
	self.handles[uri] = nil
end

function Router:handle(uri)
	return self.handles[uri]
end

return Router
