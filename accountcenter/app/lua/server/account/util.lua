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
	return require("server.account.config")
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
	if util.config().mode == "debug" and sign == "debug" then
		return true
	end
	if util.signature(str,secret) ~= sign then
		return false
	end
	return true
end

function util.get_app(appid)
	local config = util.config()
	return config.apps[appid]
end

function util.zonelist_by_version(appid,version)
	local app = util.get_app(appid)
	return app.version_whitelist[version]
end

function util.zonelist_by_ip(appid,ip)
	local app = util.get_app(appid)
	return app.ip_whitelist[ip]
end

function util.zonelist_by_acct(appid,acct)
	local app = util.get_app(appid)
	return app.acct_whitelist[acct]
end

function util.zonelist_by_channel(appid,channel)
	local app = util.get_app(appid)
	return app.channel_whitelist[channel]
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

function util.filter_serverlist(appid,version,ip,acct,channel,devicetype)
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
	if acct then
		zonelist = util.zonelist_by_acct(appid,acct)
		if zonelist then
			serverlist = util.serverlist_by_zonelist(all_serverlist,zonelist)
			return serverlist,zonelist
		end
	end
	local zonelist = util.zonelist_by_channel(appid,channel)
	if zonelist then
		serverlist = util.serverlist_by_zonelist(all_serverlist,zonelist)
		return serverlist,zonelist
	end
	return {},{}
end

return util
