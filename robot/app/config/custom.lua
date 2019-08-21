return {
    handshake = false,       -- false:不走握手流程
    --debuglogin = true,     -- true:调试登录(不和账号中心通信)
    appid = "appid",
    appkey = "secret",
    loginserver = {
        ip = "127.0.0.1",
        port = 8885,
        appkey = "secret",
    },
    --[[
    proto = {
        type = "protobuf",
        pbfile = "../../proto/protobuf/all.pb",
        idfile = "../../proto/protobuf/message_define.lua",
    },
    proto = {
        type = "sproto",
        c2s = "../../proto/sproto/all.spb",
        s2c = "../../proto/sproto/all.spb",
        binary = true,
    },
    ]]
    proto = {
        type = "json",
    }
}
