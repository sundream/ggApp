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
	apps = {
		appid = {
			appid = "appid",
			secret = "secret",
			-- 版本白名单
			version_whitelist = {
				-- 特殊版本
				["0.0.0"] = {".*"},
			},
			-- ip白名单
			ip_whitelist = {
				--["127.0.0.1"] = {"dev1"},
			},
			-- 账号白名单
			acct_whitelist = {
				--["lgl"] = {"dev1"},
			},
			-- 渠道白名单
			channel_whitelist = {
				-- my: 内部渠道
				["my"] = {"dev1"},
			},
		},
	}
}
