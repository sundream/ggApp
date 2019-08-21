util = util or {}

function util.get_app(appid)
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local key = string.format("app")
        local app = db:hget(key,appid)
        if app == nil then
            return nil
        else
            return cjson.decode(app)
        end
    else
        local doc = db.app:findOne({appid=appid})
        if doc == nil then
            return nil
        else
            doc._id = nil
            return doc
        end
    end
end

function util.zonelist_by_version(appid,version)
    -- mongo3.4.6存储的key不能包含"."
    version = string.gsub(version,"%.","_")
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
    local env = skynet.getenv("env")
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
