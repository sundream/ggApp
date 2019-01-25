return {
	mode = "debug",
	env = "dev",
	db = {
		type = "redis",
		config = {
			host = "127.0.0.1",
			port = 6385,
			auth = "redispwd",
		},
		--type = "mongodb",
		--config = {
		--	host = "127.0.0.1",
		--	port = 29017,
		--	username = nil,
		--	password = nil,
		--},
	},
}
