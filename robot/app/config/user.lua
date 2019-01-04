return {
	no_handshake = true, -- true:不走握手流程
	--debuglogin = true,	 -- true:调试登录(不和账号中心通信)
	appid = "appid",
	accountcenter = {
		ip = "127.0.0.1",
		port = 8887,
		secret = "secret",	-- 和账号中心通信的密钥
	},
	proto = {
		type = "sproto",
		c2s = "../../proto/sproto/all.spb",
		s2c = "../../proto/sproto/all.spb",
		binary = true,
	},
	--[[
	-- protobuf
	proto = {
		type = "protobuf",
		pbfile = "../../proto/protobuf/all.pb",
		idfile = "../../proto/protobuf/message_define.lua",
	},
	--[[
	-- json
	proto = {
		type = "json",
	}
	]]
}
