require "app.game"

local function response(linkid, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(linkid), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("linktype=http,linkid=%s,err=%s",linkid,err))
    end
end

local handler = {}

skynet.init(function ()
    game.init()
end)

skynet.start(function ()
    skynet.dispatch("lua",function (session,source,cmd,...)
        local func = assert(handler[cmd],cmd)
        func(...)
    end)
end)


function handler.start(watchdog,linkid,ip,port,msg_max_len)
    socket.start(linkid)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(linkid), msg_max_len)
    if code then
        if code ~= 200 then
            response(linkid, code)
        else
            local agent = {
                linkid = linkid,
                ip = ip,
                port = port,
                method = method,
            }
            if header["x-real-ip"] then
                agent.ip = header["x-real-ip"]
            end
            local uri, query = urllib.parse(url)
            -- uri may include http://host:port ?
            if uri:sub(1,1) ~= "/" then
                uri = string.match(uri,"http[s]?://.-(/.+)")
            end
            -- 使用call保证http回复发送出去后才关闭连接!
            local ok
            if watchdog then
                ok = pcall(skynet.call,watchdog,"lua","service","http_onmessage",agent,uri,header,query,body)
            else
                ok = xpcall(net.http_onmessage,gg.onerror or debug.traceback,net,agent,uri,header,query,body)
            end
            if not ok then
                -- server internal error
                response(linkid,500)
            end
        end
    else
        if url == sockethelper.socket_error then
            skynet.error("socket closed")
        else
            skynet.error(url)
        end
    end
    socket.close(linkid)
end

function handler.stop(reason)
    dbmgr:shutdown()
    skynet.exit()
end

function handler.exec(...)
    gg.exec(_G,...)
end

--return handler
