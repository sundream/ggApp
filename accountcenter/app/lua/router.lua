local Router = {}
Router.__index = Router

function Router:new()
	local self = {}
	setmetatable(self,Router)
	self.handlers = {}
	return self
end

function Router:register(uri,handler)
	self.handlers[uri] = handler
end

function Router:unregister(uri)
	self.handlers[uri] = nil
end

function Router:handler(uri)
	return self.handlers[uri]
end

return Router
