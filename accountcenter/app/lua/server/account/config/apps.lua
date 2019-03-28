-- 所有app信息
return {
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
		account_whitelist = {
			--["lgl"] = {"dev1"},
		},
		-- 平台白名单
		platform_whitelist = {
			-- my: 内部平台
			["my"] = {"dev1"},
		},
	},
}
