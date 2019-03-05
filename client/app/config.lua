return {
	no_handshake = true,
	appid = "appid",
	accountcenter = {
		ip = "127.0.0.1",
		port = 8887,
		secret = "secret",
	},
	proto = {
		type = "sproto",
		c2s = "client/proto/sproto/all.spb",
		s2c = "client/proto/sproto/all.spb",
		binary = true,
	},
	--[[
	-- protobuf
	proto = {
		type = "protobuf",
		pbfile = "client/proto/protobuf/all.pb",
		idfile = "client/proto/protobuf/message_define.lua",
	},
	proto = {
		type = "json",
	}
	]]
}
