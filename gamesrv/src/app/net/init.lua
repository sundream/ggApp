net = net or {}

function net.init()
	net.handlers = {}
	net.http_handlers = {}
	net.register_module("login",require "app.net.login")
	net.register_http_cmd("/test/echo",require "app.net.http.test.echo")
end

function net.register_module(name,module)
	net[name] = module
	if module.C2GS then
		for proto,handler in pairs(module.C2GS) do
			net.register_cmd("C2GS_"..proto,handler)
		end
	end
end

function net.register_cmd(proto,handler)
	net.handlers[proto] = handler
end

function net.cmd(proto)
	return net.handlers[proto]
end

function net.register_http_cmd(uri,handler)
	net.http_handlers[uri] = handler
end

function net.http_cmd(uri)
	return net.http_handlers[uri]
end

function __hotfix(oldmod)
	net.init()
end

return net
