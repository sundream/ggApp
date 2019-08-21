require "app.game.init"

local function _print(...)
    print(...)
    skynet.error(...)
end

game = game or {}

function game.init()
    skynet.memlimit(1024*1024*1024)
    skynet.register(".game")
    -- encode时将稀疏数组编码成object，空表编码成[]
    cjson.encode_sparse_array(true)
    cjson.encode_empty_table_as_object(false)
    logger.init()
    gg.init()
    -- 应用层初始化代码放到game.start中!!!
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
    gg.timectrl:starttimer()
    _print("timectrl:starttimer")
    gg.actor:start()
    local address = skynet.self()
    -- 多久不活跃会主动关闭套接字(1/100秒为单位)
    local gate_conf = {
        watchdog = address,
        proto = assert(skynet.getenv("proto")),
        timeout = assert(tonumber(skynet.getenv("socket_timeout"))),
        maxclient = assert(tonumber(skynet.getenv("socket_max_num"))),
        msg_max_len = assert(tonumber(skynet.getenv("msg_max_len"))),
        encrypt_algorithm = skynet.getenv("encrypt_algorithm"),
    }
    local tcp_gate
    local kcp_gate
    local websocket_gate
    local tcp_port = skynet.getenv("tcp_port")
    if tcp_port then
        gate_conf.port = tcp_port
        tcp_gate = skynet.uniqueservice("gg/service/gate/tcp")
        skynet.call(tcp_gate,"lua","open",gate_conf)
    end
    local kcp_port = skynet.getenv("kcp_port")
    if kcp_port then
        gate_conf.port = kcp_port
        kcp_gate = skynet.uniqueservice("gg/service/gate/kcp")
        skynet.call(kcp_gate,"lua","open",gate_conf)
    end
    local websocket_port = skynet.getenv("websocket_port")
    if websocket_port then
        gate_conf.port = websocket_port
        websocket_gate = skynet.uniqueservice("gg/service/gate/websocket")
        skynet.call(websocket_gate,"lua","open",gate_conf)
    end
    local http_port = skynet.getenv("http_port")
    if http_port then
        gate_conf.port = http_port
        gate_conf.service_name = "gg/service/httpd"
        httpd.start(gate_conf)
    end
    gg.actor.gm:open()
    _print("gm:open")
    gg.actor.cluster:open()
    _print("cluster:open")
    gg.actor.client.tcp_gate = tcp_gate
    gg.actor.client.kcp_gate = kcp_gate
    gg.actor.client.websocket_gate = websocket_gate
    gg.actor.client:open()
    _print("client:open")
    gg.start()
    _print("started")
    logger.logf("info","game","op=started")
end

function game.stop(reason)
    logger.logf("info","game","op=stoping")
    gg.playermgr:kickall()
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
