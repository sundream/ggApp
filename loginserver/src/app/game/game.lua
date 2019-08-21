require "app.game.init"

local function _print(...)
    print(...)
    skynet.error(...)
end

game = game or {}

function game.init()
    skynet.register(".game")
    -- encode时将稀疏数组编码成object，空表编码成[]
    cjson.encode_sparse_array(true)
    cjson.encode_empty_table_as_object(false)
    logger.init()
    gg.init()
    -- 应用层初始化代码放到game.start中!!!
    gg.actor.client:open()
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
    gg.actor:start()
    local gate_conf = {
        --watchdog = address,
        service_name = "app/game/httpd_main",
    }
    local http_port = skynet.getenv("http_port")
    if http_port then
        gate_conf.port = http_port
        httpd.start(gate_conf)
    end
    gg.actor.gm:open()
    _print("gm:open")
    --gg.actor.cluster:open()
    --_print("cluster:open")
    gg.start()
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
        gg.dbmgr:shutdown()
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

return game
