local cnet = class("cnet")

function cnet:init()
    self.handlers = {}
    self.http_handlers = {}
    -- 登录前允许接收的协议
    self.unauth_cmds = {}
end

function cnet:register_module(name,module,prefix)
    prefix = prefix or "C2GS"
    assert(self[name] == nil)
    self[name] = module
    for proto,handler in pairs(module[prefix]) do
        self:register_cmd(prefix.."_"..proto,handler)
    end
end

function cnet:register_cmd(cmd,handler)
    self.handlers[cmd] = handler
end

function cnet:register_http_cmd(cmd,handler)
    self.http_handlers[cmd] = handler
end

function cnet:cmd(cmd)
    return self.handlers[cmd]
end

function cnet:http_cmd(cmd)
    return self.http_handlers[cmd]
end

function cnet:register_unauth_cmd(cmd)
    self.unauth_cmds[cmd] = true
end

function cnet:http_onmessage(linkobj,uri,header,query,body)
    logger.logf("debug","http","op=recv,linkid=%s,ip=%s,port=%s,method=%s,uri=%s,header=%s,query=%s,body=%s",
        linkobj.linkid,linkobj.ip,linkobj.port,linkobj.method,uri,header,query,body)

    local handler = self:http_cmd(uri)
    if handler then
        local func = handler[linkobj.method]
        if func then
            func(linkobj,header,query,body)
        else
            -- method not implemented
            httpc.response(linkobj.linkid,501)
        end
    else
        -- not found
        httpc.response(linkobj.linkid,404)
    end
    skynet.ret(nil)
end

function cnet:open()
    self:register_http_cmd("/api/rpc",require "app.http.api.rpc")
    self:register_module("login",require("app.net.login"))

    for proto in pairs(net.login.C2GS) do
        proto = "C2GS_" .. proto
        self:register_unauth_cmd(proto)
    end
end

net = net or cnet.new()

function __hotfix(module)
    net:open()
end

return cnet
