local httpd = require "http.httpd"

httpd.webagents = httpd.webagents or {}

function httpd.start(conf)
    local ip = conf.ip or "0.0.0.0"
    local watchdog = conf.watchdog
    local port = assert(conf.port)
    local msg_max_len = conf.msg_max_len or 8*1024
    local agent_num = conf.agent_num or 16
    local service_name = assert(conf.service_name)
    skynet.start(function ()
        for i=1,agent_num do
            httpd.webagents[i] = skynet.newservice(service_name)
        end
        local balance = 1
        local id = socket.listen(ip,port)
        skynet.error(string.format("Listen web port %s:%s",ip,port))
        socket.start(id , function(linkid, addr)
            --skynet.error(string.format("%s connected, pass it to agent :%08x", addr, httpd.webagents[balance]))
            local client_ip,client_port = string.match(addr,"([^:]+):(%d+)")
            skynet.send(httpd.webagents[balance], "lua","start",watchdog,linkid,client_ip,client_port,msg_max_len)
            balance = balance + 1
            if balance > agent_num then
                balance = 1
            end
        end)
    end)
end

function httpd.stop(reason)
    for i,agent in ipairs(httpd.webagents) do
        skynet.send(agent,"lua","stop",reason)
    end
end
