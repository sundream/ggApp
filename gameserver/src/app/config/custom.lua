-- app.config.custom中的配置会覆盖*.config,可以通过skynet.getenv获取,并且支持值为table,
return {
    -- db
    --[[
    db_type = "redis",
    db_is_cluster = false,
    db_config = {
        host = "127.0.0.1",
        port = 6000,
        auth = "redispwd",
    },
    ]]

    --[[
    db_type = "redis",
    db_is_cluster = true,
    db_config = {
        startup_nodes = {
            {host="127.0.0.1",port=7001},
            {host="127.0.0.1",port=7002},
            {host="127.0.0.1",port=7003},
        },
        opt = {
            max_connections = 256,
            read_slave = true,
            auth = nil,
            db = 0,
        },
    },
    ]]

    db_type = "mongodb",
    --db_is_cluster = true,
    db_config = {
        db = skynet.getenv("appid") or "game",
        rs = {
            {host = "127.0.0.1",port = 26000,username=nil,password=nil,authmod="scram-sha1",authdb="admin"},
        }
    },

    -- proto
    --[[
    proto = {
        type = "protobuf",
        pbfile = "src/proto/protobuf/all.pb",
        idfile = "src/proto/protobuf/message_define.lua",
    },
    proto = {
        type = "sproto",
        c2s = "src/proto/sproto/all.spb",
        s2c = "src/proto/sproto/all.spb",
        binary = true,
    },
    ]]
    proto = {
        type = "json"
    },

    -- cluster config
    nodes = require "app.config.nodes",
}
