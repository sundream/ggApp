require "app.init"

local function _print(...)
    print(...)
    skynet.error(...)
end

game = game or {}

function game.init()
    -- encode时将稀疏数组编码成object，空表编码成[]
    cjson.encode_sparse_array(true)
    cjson.encode_empty_table_as_object(false)
    game.init_traceback()
    logger.init()
    gg.init()
    net:open()
end

function game.start()
    _print("starting")
    logger.logf("info","game","op=starting")
    local logpath = assert(skynet.getenv("logpath"))
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        -- remember address + port for shell/gm.sh
        local file = io.open(logpath.."/debug_console.txt","wb")
        file:write(string.format("address=%s\nport=%s",skynet.self(),debug_port))
        file:close()
        local debug_ip = skynet.getenv("debug_ip") or "127.0.0.1"
        skynet.newservice("debug_console",debug_ip,debug_port)
    end
    if not skynet.getenv "daemon" then
        local file = io.open(logpath.."/skynet.pid","wb")
        file:write(game.getpid())
        file:close()
        console.init()
    end
    local address = skynet.self()
    skynet.name(".main",address)
    skynet.dispatch("lua",game.dispatch)
    local gate_conf = {
        --watchdog = address,
        service_name = "app/httpd_main",
    }
    local http_port = skynet.getenv("http_port")
    if http_port then
        gate_conf.port = http_port
        httpd.start(gate_conf)
    end

    _print("started")
    logger.logf("info","game","op=started")
end

function game.stop(reason)
    logger.logf("info","game","op=stoping")
    httpd.stop(reason)
    game.saveall()
    skynet.timeout(300,function ()
        logger.logf("info","game","op=stoped")
        _print("stoped")
        dbmgr:shutdown()
        logger.shutdown()
        local logpath = assert(skynet.getenv("logpath"))
        os.execute(string.format("rm %s/skynet.pid",logpath))
        os.exit()
    end)
end

function game.saveall()
    logger.logf("info","game","op=saveall")
    gg.savemgr:saveall()
end

function game._dispatch(session,source,typ,...)
    --skynet.trace()
    if typ == "client" then
        -- 客户端消息
        client.dispatch(session,source,...)
    elseif typ == "cluster" then
        -- 集群(服务器间）消息
        rpc.dispatch(session,source,...)
    elseif typ == "service" then
        -- 同节点其他服务与主服务通信消息
        game.service_dispatch(session,source,...)
    elseif typ == "gm" then
        -- debug_console发过来的gm消息
        -- 客户端自己执行的gm可以通过特定协议(如频道消息）+ gm权限控制执行
        game.dogm(session,source,...)
    end
end


function game.dispatch(session,source,typ,...)
    local ok,err
    local cmd = game.extract_cmd(typ,...)
    if cmd then
        local profile = gg.profile
        profile.cost[typ] = profile.cost[typ] or {__tostring=tostring,}
        ok,err = profile:stat(gg.profile.cost[typ],cmd,gg.onerror,game._dispatch,session,source,typ,...)
    else
        ok,err = xpcall(game._dispatch,gg.onerror,session,source,typ,...)
    end
    -- 将错误传给引擎,这样被对方skynet.call报错后也会回复对方一个错误包
    assert(ok,err)
end

function game.dogm(session,source,...)
    local cmdline = ...
    if session ~= 0 then
        local ok,msg,sz = pcall(skynet.pack,gm.docmd(cmdline))
        if ok then
            skynet.ret(msg,sz)
        else
            local err = msg
            skynet.retpack(err)
        end
    else
        gm.docmd(cmdline)
    end
end

function game.service_dispatch(session,source,cmd,...)
    if cmd == "http_onmessage" then
        net:http_onmessage(...)
    elseif cmd == "exec"  then
        if session ~= 0 then
            skynet.retpack(gg.exec(_G,...))
        else
            gg.exec(_G,...)
        end
    end
end

function game.getpid()
    if not game.pid then
        local serverid = skynet.getenv("id")
        local cmd = string.format("ps -ef | grep skynet | grep %s | grep -v grep",serverid)
        local file = io.popen(cmd,"r")
        local line = file:read("*a")
        file:close()
        local list = string.split(line)
        game.pid = assert(tonumber(list[2]))
    end
    return game.pid
end

function game.extract_cmd(typ,...)
    if typ == "client" then
        local cmd = ...
        if cmd == "onmessage" then
            local message = select(3,...)
            return message.cmd
        else
            return cmd
        end
        -- 客户端消息
    elseif typ == "cluster" then
        -- 集群(服务器间）消息
        local protoname,cmd,cmd2 = select(2,...)
        if protoname == "playerexec" then
            cmd = cmd2
        end
        if not game._cache then
            game._cache = {}
        end
        if not game._cache[protoname] then
            game._cache[protoname] = {}
        end
        if not game._cache[protoname][cmd] then
            game._cache[protoname][cmd] = protoname .. "." .. cmd
        end
        return game._cache[protoname][cmd]
    elseif typ == "service" then
        -- 同节点其他服务与主服务通信消息
        return nil
    elseif typ == "gm" then
        -- debug_console发过来的gm消息
        local cmdline = ...
        -- pid cmd arg1 arg2 ...
        local cmds = string.split(cmdline,"%s")
        return cmds[2]
    end
end

function game.init_traceback()
    -- 配置traceback收集规则
    for name,class_type in pairs(gg.class) do
        if type(name) == "string" then
            class_type.__tostring = gg.__tostring
        end
    end
end

return game
