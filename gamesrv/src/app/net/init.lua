net = net or {}

function net.init()
	net.handlers = {}
	net.register_module("login",require "app.net.login")
end

function net.register_module(name,module)
	net[name] = module
	if module.C2GS then
		for proto,handler in pairs(module.C2GS) do
			net.handlers["C2GS_" .. proto] = handler
		end
	end
end

function net.cmd(proto)
	return net.handlers[proto]
end

function __hotfix(oldmod)
	net.init()
end

return net
