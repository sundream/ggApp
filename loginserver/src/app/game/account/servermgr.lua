servermgr = servermgr or {}

function servermgr.saveserver(appid,server)
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local id = assert(server.id)
        local key = string.format("server:%s",appid)
        db:hset(key,id,cjson.encode(server))
    else
        local id = assert(server.id)
        server.appid = appid
        db.server:update({appid=appid,id=id},server,true,false)
    end
end

function servermgr.loadserver(appid,serverid)
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local key = string.format("server:%s",appid)
        local retval = db:hget(key,serverid)
        if retval == nil then
            return nil
        else
            return cjson.decode(retval)
        end
    else
        local doc = db.server:findOne({appid=appid,id=serverid})
        if doc == nil then
            return nil
        else
            doc._id = nil
            return doc
        end
    end
end


function servermgr.checkserver(server)
    local server,err = table.check(server,{
        ip = {type="string"},                                   -- ip
        cluster_ip = {type="string",optional=true},             -- 集群ip
        cluster_port = {type="number",optional=true},           -- 集群端口
        tcp_port = {type="number",optional=true},               -- tcp端口
        kcp_port = {type="number",optional=true},               -- kcp端口
        websocket_port = {type="number",optional=true},         -- websocket端口
        debug_port = {type="number",optional=true},             -- debug端口
        http_port = {type="number",optional=true},              -- http端口
        id = {type="string"},                                   -- 服务器ID
        name = {type="string"},                                 -- 服务器名
        index = {type="number"},                                -- 服务器编号
        type = {type="string"},                                 -- 服务器类型
        zoneid = {type="string"},                               -- 区ID
        zonename = {type="string"},                             -- 区名
        area = {type="string"},                                 -- 大区ID
        areaname = {type="string"},                             -- 大区名
        env = {type="string"},                                  -- 部署环境ID
        envname = {type="string"},                              -- 部署环境名
        opentime = {type="number"},                             -- 预计开服时间
        isopen = {type="number",optional=true,default=1},       -- 是否开放
        busyness = {type="number",optional=true,default=0.0},   -- 负载
        newrole = {type="number",optional=true,default=1},      -- 是否可以新建角色
        updatetime = {type="number",optional=true,default=os.time()}, -- 更新时间
    })
    return server,err
end

function servermgr.addserver(appid,server)
    local server,err = servermgr.checkserver(server)
    if err then
        return httpc.answer.code.SERVER_FMT_ERR,err
    end
    if not (server.tcp_port or server.kcp_port or server.websocket_port) then
        return httpc.answer.code.SERVER_FMT_ERR,"no tcp/kcp/websocket port"
    end
    server.createtime = os.time()
    servermgr.saveserver(appid,server)
    return httpc.answer.code.OK
end

function servermgr.delserver(appid,serverid)
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local key = string.format("server:%s",appid)
        local retval = db:hdel(key,serverid)
        if retval == 0 then
            return httpc.answer.code.SERVER_NOEXIST
        else
            return httpc.answer.code.OK
        end
    else
        local ok = db.server:safe_delete({appid=appid,id=serverid},true)
        if not ok then
            return httpc.answer.code.SERVER_NOEXIST
        else
            return httpc.answer.code.OK
        end
    end
end

function servermgr.updateserver(appid,sync_server)
    local serverid = assert(sync_server.id)
    if not util.get_app(appid) then
        return httpc.answer.code.APPID_NOEXIST
    end
    local server = servermgr.getserver(appid,serverid)
    if not server then
        return httpc.answer.code.SERVER_NOEXIST
    end
    table.update(server,sync_server)
    servermgr.saveserver(appid,server)
    return httpc.answer.code.OK
end

function servermgr.getserver(appid,serverid)
    local server = servermgr.loadserver(appid,serverid)
    if server then
        local now = os.time()
        local online = (now - (server.updatetime or 0)) < 40
        if online then
            server.state = "online"
        else
            server.state = "down"
        end
    end
    return server
end
--random
function servermgr.getonlineserver(appid)
    local all_serverlist = servermgr.getserverlist(appid)
    local online_serverlist = table.filter(all_serverlist,function (srv)
        return srv.state == "online"
    end)
    if #online_serverlist == 0 then
        return nil
    end
    return online_serverlist[math.random(1, #online_serverlist)]
end

function servermgr.getserverlist(appid)
    local db = gg.dbmgr:getdb()
    if gg.dbmgr.db_type == "redis" then
        local serverlist = {}
        local key = string.format("server:%s",appid)
        local list = db:hgetall(key)
        local now = os.time()
        for i=1,#list,2 do
            local serverid = list[i]
            local server = cjson.decode(list[i+1])
            local online = (now - (server.updatetime or 0)) < 40
            if online then
                server.state = "online"
            else
                server.state = "down"
            end
            table.insert(serverlist,server)
        end
        return serverlist
    else
        local serverlist = {}
        local cursor = db.server:find({appid=appid})
        local now = os.time()
        while cursor:hasNext() do
            local doc = cursor:next()
            doc._id = nil
            local server = doc
            local online = (now - (server.updatetime or 0)) < 40
            if online then
                server.state = "online"
            else
                server.state = "down"
            end
            table.insert(serverlist,server)
        end
        return serverlist
    end
end

return servermgr
