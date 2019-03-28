-- app.config.custom中的配置会覆盖*.config,可以通过skynet.getenv获取,并且支持值为table,
return {
	--[[
	db_type = "redis",
	db_is_cluster = false,
	db_config = {
		host = "127.0.0.1",
		port = 6385,
		auth = "redispwd",
	},
	]]

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

	--[[
	db_type = "mongodb",
	db_is_cluster = true,
	db_config = {
		rs = {
			{host = "127.0.0.1",port = 29017,username=nil,password=nil,authmod=nil,authdb=nil},
			{host = "127.0.0.1",port = 29018},
			{host = "127.0.0.1",port = 29019},
		}
	},
	]]
}
