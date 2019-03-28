local cjson = require "cjson"
cjson.encode_empty_table_as_object(false)
cjson.encode_sparse_array(true)

local util = {}

function util.response_json(status,response)
	ngx.status = status
	ngx.header["content-type"] = "application/json;charset=utf-8"
	if response ~= nil then
		ngx.say(cjson.encode(response))
	end
end

function util.config()
	local env = os.getenv("env")
	if env == "dev" then
		return require("server.account.config.config_dev")
	end
end

function util.signature(str,secret)
	if type(str) == "table" then
		str = table.ksort(str,"&",{sign=true})
	end
	local str2 = ngx.hmac_sha1(secret,str)
	local sign = ngx.encode_base64(str2)
	return sign
end

function util.check_signature(sign,str,secret)
	-- 密钥配置成nocheck,则不检查签名(https通信时可能会这样做)
	if secret == "nocheck" then
		return true
	end
	if util.config().env == "dev" and sign == "debug" then
		return true
	end
	if util.signature(str,secret) ~= sign then
		return false
	end
	return true
end

function util.apps()
	return require "server.account.config.apps"
end

function util.get_app(appid)
	local apps = util.apps()
	return apps[appid]
end

function util.sdks()
	return require "server.account.config.sdks"
end

function util.get_sdk(sdk)
	local sdks = util.sdks()
	return sdks[sdk]
end

function util.platforms()
	return require "server.account.config.platforms"
end

function util.get_platform(platform)
	local platforms = util.platforms()
	return platforms[platform]
end

function util.get_sdklogin(sdk)
	local modname = string.format("api.account.sdklogin.%s",sdk)
	local ok,func = xpcall(require,debug.traceback,modname)
	return ok,func
end

function util.zonelist_by_version(appid,version)
	local app = util.get_app(appid)
	return app.version_whitelist[version]
end

function util.zonelist_by_ip(appid,ip)
	local app = util.get_app(appid)
	return app.ip_whitelist[ip]
end

function util.zonelist_by_account(appid,account)
	local app = util.get_app(appid)
	return app.account_whitelist[account]
end

function util.zonelist_by_platform(appid,platform)
	local app = util.get_app(appid)
	return app.platform_whitelist[platform]
end

function util.serverlist_by_zonelist(all_serverlist,zonelist)
	local serverlist = {}
	for i,server in ipairs(all_serverlist) do
		for j,zoneid in ipairs(zonelist) do
			if string.match(server.zoneid,zoneid) then
				table.insert(serverlist,server)
			end
		end
	end
	return serverlist
end

function util.filter_serverlist(appid,version,ip,account,platform,devicetype)
	local servermgr = require "server.account.servermgr"
	local config = util.config()
	local env = config.env
	local all_serverlist = {}
	local list = servermgr.getserverlist(appid)
	for i,server in ipairs(list) do
		if server.env == env then
			table.insert(all_serverlist,server)
		end
	end
	local serverlist
	local zonelist = util.zonelist_by_version(appid,version)
	if zonelist then
		serverlist = util.serverlist_by_zonelist(all_serverlist,zonelist)
		return serverlist,zonelist
	end
	local zonelist = util.zonelist_by_ip(appid,ip)
	if zonelist then
		serverlist = util.serverlist_by_zonelist(all_serverlist,zonelist)
		return serverlist,zonelist
	end
	if account then
		zonelist = util.zonelist_by_account(appid,account)
		if zonelist then
			serverlist = util.serverlist_by_zonelist(all_serverlist,zonelist)
			return serverlist,zonelist
		end
	end
	local zonelist = util.zonelist_by_platform(appid,platform)
	if zonelist then
		serverlist = util.serverlist_by_zonelist(all_serverlist,zonelist)
		return serverlist,zonelist
	end
	return {},{}
end

return util
