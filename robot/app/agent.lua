local skynet = require "skynet"
local config = require "app.config.custom"
local tcp = require "app.client.tcp"
local kcp = require "app.client.kcp"
local websocket = require "app.client.websocket"

local linkobj
local handler

local CMD = {}

function CMD.connect(conf)
    local ip = assert(conf.ip)
    local port = assert(conf.port)
    local gate_type = assert(conf.gate_type)
    if gate_type == "kcp" then
        linkobj = kcp.new({handler=handler})
    elseif gate_type == "websocket" then
        linkobj = websocket.new({handler=handler})
    else
        linkobj = tcp.new({handler=handler})
    end
    linkobj:connect(ip,port)
end

function CMD.close()
    if not linkobj then
        return
    end
    linkobj:close()
    linkobj = nil
    skynet.exit()
end

local agent = {}

function agent.start(h)
    handler = h
    skynet.start(function ()
        skynet.dispatch("lua",function (session,source,cmd,...)
            local func = CMD[cmd]
            skynet.retpack(func(...))
        end)
    end)
end

return agent
