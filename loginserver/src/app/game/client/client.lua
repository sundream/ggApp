local cclient = gg.class.cclient

function cclient:open()
    self:register_http("/api/rpc",require "app.game.client.http.api.rpc")
    self:register_http("/api/app/add",require "app.game.client.http.api.app.add")
    self:register_http("/api/account/register",require "app.game.client.http.api.account.register")
    self:register_http("/api/account/login",require "app.game.client.http.api.account.login")
    self:register_http("/api/account/checktoken",require "app.game.client.http.api.account.checktoken")
    self:register_http("/api/account/role/add",require "app.game.client.http.api.account.role.add")
    self:register_http("/api/account/role/del",require "app.game.client.http.api.account.role.del")
    self:register_http("/api/account/role/recover",require "app.game.client.http.api.account.role.recover")
    self:register_http("/api/account/role/update",require "app.game.client.http.api.account.role.update")
    self:register_http("/api/account/role/get",require "app.game.client.http.api.account.role.get")
    self:register_http("/api/account/role/list",require "app.game.client.http.api.account.role.list")
    self:register_http("/api/account/role/rebindserver",require "app.game.client.http.api.account.role.rebindserver")
    self:register_http("/api/account/role/rebindaccount",require "app.game.client.http.api.account.role.rebindaccount")
    self:register_http("/api/account/server/add",require "app.game.client.http.api.account.server.add")
    self:register_http("/api/account/server/del",require "app.game.client.http.api.account.server.del")
    self:register_http("/api/account/server/update",require "app.game.client.http.api.account.server.update")
    self:register_http("/api/account/server/get",require "app.game.client.http.api.account.server.get")
    self:register_http("/api/account/server/list",require "app.game.client.http.api.account.server.list")
end

function __hotfix(module)
    gg.actor.client:open()
end

return cclient
