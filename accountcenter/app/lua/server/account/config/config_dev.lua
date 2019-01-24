return {
	mode = "debug",
	env = "dev",
	db = {
		type = "redis",
		config = {
			host = "172.16.100.120",
			port = 6385,
			auth = "redispwd",
		},
		--type = "mongodb",
		--config = {
		--	host = "172.16.100.120",
		--	port = 29017,
		--	username = nil,
		--	password = nil,
		--},
	},
}
