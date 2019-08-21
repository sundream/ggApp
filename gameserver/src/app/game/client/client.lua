local cclient = gg.class.cclient

function cclient:register_module(name,module,prefix)
    prefix = prefix or "C2GS"
    self[name] = module
    for proto,handler in pairs(module[prefix]) do
        self:register(prefix.."_"..proto,handler)
    end
end

function cclient:open()
    self:register_http("/api/rpc",require "app.game.client.http.api.rpc")
    self:register_module("login",require("app.game.client.login"))
    self:register_module("map",require("app.game.client.map"))

    for proto,handler in pairs(self.login.C2GS) do
        proto = "C2GS_" .. proto
        self:register_unsafe(proto,handler)
    end
    -- test
    for proto,handler in pairs(self.map.C2GS) do
        proto = "C2GS_" .. proto
        self:register_unsafe(proto,handler)
    end
end

function __hotfix(module)
    gg.actor.client:open()
end

return cclient
