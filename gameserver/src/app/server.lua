local cserver = class("cserver")

function cserver:init()
    -- 所有服务器
    self.all_serverlist = {}
    -- 所有在线服务器
    self.online_serverlist = {}

    -- config
    self.id = skynet.getenv("id")
    self.name = skynet.getenv("name")
    self.index = tonumber(skynet.getenv("index"))
    self.type = skynet.getenv("type")
    self.appid = skynet.getenv("appid")
    self.appkey = skynet.getenv("appkey")
    self.area = skynet.getenv("area")
    self.env = skynet.getenv("env")
    self.zoneid = skynet.getenv("zoneid")
    self.loglevel = skynet.getenv("loglevel")
    self.arename = skynet.getenv("arename")
    self.envname = skynet.getenv("envname")
    self.zonename = skynet.getenv("zonename")
    self.opentime = skynet.getenv("opentime")

    self.ip = skynet.getenv("ip")
    self.cluster_ip = skynet.getenv("cluster_ip")
    self.cluster_port = tonumber(skynet.getenv("cluster_port"))
    self.tcp_port = tonumber(skynet.getenv("tcp_port"))
    self.kcp_port = tonumber(skynet.getenv("kcp_port"))
    self.websocket_port = tonumber(skynet.getenv("websocket_port"))
    self.http_port = tonumber(skynet.getenv("http_port"))
    self.debug_port = tonumber(skynet.getenv("debug_port"))

    self:starttimer()
end

-- 后端程序本地开发服
function cserver:islocal()
	return self.index < 20
end

function cserver:isdev(area)
    area = area or self.area
    return area == "dev"
end

function cserver:istest(area)
    area = area or self.area
    return area == "test"
end

function cserver:isstable(area)
    return not (self:isdev(area) or self:istest(area))
end

function cserver:checkname(name)
    -- TODO: check name
    return httpc.answer.code.OK
end

function cserver:busyness()
    local mqlen = skynet.mqlen()
    local loadlv = mqlen / 100 -- >=1--高负载
    local busyness = (playermgr.onlinenum/playermgr.onlinelimit) * 0.8 + loadlv * 0.2
    busyness = math.ceil(busyness * 1000) / 1000
    return busyness
end

--- 获取服务器状态,如会返回当前在线人数,服务器压力等信息
function cserver:status()
    return {
        -- 服务器信息
        id = self.id,
        name = self.name,
        index = self.index,
        appid = self.appid,
        appkey = self.appkey,
        zoneid = self.zoneid,
        area = self.area,
        env = self.env,
        loglevel = self.loglevel,
        areaname = self.areaname,
        envname = self.envname,
        zonename = self.zonename,
        opentime = self.opentime,

        -- ip,port信息
        ip = self.ip,
        cluster_ip = self.cluster_ip,
        cluster_port = self.cluster_port,
        tcp_port = self.tcp_port,
        kcp_port = self.kcp_port,
        websocket_port = self.websocket_port,
        http_port = self.http_port,
        debug_port = self.debug_port,

        -- 状态信息
        onlinenum = playermgr.onlinenum,
        onlinelimit = playermgr.onlinelimit,
        tuoguannum = playermgr.tuoguannum(),
        min_onlinenum = playermgr.min_onlinenum,
        max_onlinenum = playermgr.max_onlinenum,
        linknum = gg.client.linkobjs and gg.client.linkobjs.len or 0,
        mqlen = skynet.mqlen(),
        task = skynet.task(),
        busyness = self:busyness(),
    }
end

function cserver:starttimer()
    local interval = 10
    gg.timer:timeout("server.on_tick",interval,function ()
        self:starttimer()
    end)
    pcall(self.on_tick,self)
end

function cserver:on_tick()
    self._tickcnt = (self._tickcnt or 0) + 1
    local interval = 10
    -- 计算每5分钟在线人数峰值，谷值
    if self._tickcnt % math.ceil(300/interval) == 0 then
        playermgr.min_onlinenum = nil
        playermgr.max_onlinenum = nil
    end
    playermgr.min_onlinenum = playermgr.min_onlinenum or playermgr.onlinenum
    playermgr.max_onlinenum = playermgr.max_onlinenum or playermgr.onlinenum
    if playermgr.onlinenum < playermgr.min_onlinenum then
        playermgr.min_onlinenum = playermgr.onlinenum
    end
    if playermgr.onlinenum > playermgr.max_onlinenum then
        playermgr.max_onlinenum = playermgr.onlinenum
    end
    local server = self:status()
    logger.logf("info","status","serverid=%s,onlinenum=%s,tuoguannum=%s,min_onlinenum=%s,max_onlinenum=%s,linknum=%s,onlinelimit=%s,mqlen=%s,task=%s,busyness=%s",
        server.id,server.onlinenum,server.tuoguannum,server.min_onlinenum,server.max_onlinenum,server.linknum,server.onlinelimit,server.mqlen,server.task,server.busyness)

    local serverid = server.id
    local status,response = gg.loginserver:updateserver(serverid,server)
    assert(status==200)
    assert(response.code == httpc.answer.code.OK)
    local version = "0.0.0"     -- 这个版本可以获取所有列表
    local platform = "local"
    local devicetype = "ios"
    local status,response = gg.loginserver:serverlist(version,platform,devicetype)
    assert(status==200)
    assert(response.code == httpc.answer.code.OK)
    self.all_serverlist = response.data.serverlist
    self.online_serverlist = table.filter(self.all_serverlist,function (srv)
        return srv.state == "online"
    end)
    for i,server in ipairs(self.all_serverlist) do
        self.all_serverlist[server.id] = server
    end
    for i,server in ipairs(self.online_serverlist) do
        self.online_serverlist[server.id] = server
    end
end

return cserver
