require "base.init"
local Router = require "router"
local util = require "server.account.util"


local Server = {}

function Server:init_worker()
	self.name = "account"
	self.version = require "server.account.version"
	self.config = require "server.account.config"
	self:init_router(self.config.router)
end

function Server:init_router(config)
	self.router = Router:new(config)
	self:register("api.account.rpc")
	self:register("api.account.register")
	self:register("api.account.login")
	self:register("api.account.checktoken")
	self:register("api.account.role.add")
	self:register("api.account.role.del")
	self:register("api.account.role.update")
	self:register("api.account.role.get")
	self:register("api.account.role.list")
	self:register("api.account.role.rebindsrv")
	self:register("api.account.role.rebindacct")
	self:register("api.account.server.add")
	self:register("api.account.server.del")
	self:register("api.account.server.update")
	self:register("api.account.server.get")
	self:register("api.account.server.list")
end

function Server:register(modname)
	local uri = string.gsub(modname,"%.","/")
	if uri:sub(1,1) ~= "/" then
		uri = "/" .. uri
	end
	self.router:register(uri,require(modname))
end

function Server:run()
	self:dispatch()
end

function Server:dispatch()
	local uri = ngx.var.uri
	local method = ngx.req.get_method()
	method = string.lower(method)
	uri = string.rtrim(uri,"/")
	local handle = self.router:handle(uri)
	if not handle then
		util.response_json(ngx.HTTP_NOT_FOUND)
	else
		local func = handle[method]
		if func then
			local isok,err = xpcall(func,debug.traceback)
			if not isok then
				ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
				ngx.say(err)
			end
		else
			util.response_json(ngx.HTTP_METHOD_NOT_IMPLEMENTED)
		end
	end
end

return Server
