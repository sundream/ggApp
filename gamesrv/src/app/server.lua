cserver = class("cserver")

function cserver:init()
	-- 所有服务器
	self.all_serverlist = {}
	-- 所有在线服务器
	self.online_serverlist = {}

	self:starttimer()
end

-- 区域: 如dev--内网开发区,test--外网测试服，其他--外网正式服
function cserver:area()
	return skynet.getenv("area")
end

-- 服务器ID
function cserver:serverid()
	return skynet.getenv("id")
end

function cserver:accountcenter()
	return skynet.getenv("accountcenter")
end

function cserver:isdevsrv(area)
	area = area or self:area()
	return area == "dev"
end

function cserver:istestsrv(area)
	area = area or self:area()
	return area == "test"
end

function cserver:isstablesrv(area)
	return not (self:isdevsrv(area) or self:istestsrv(area))
end

function cserver:checkname(name)
	-- TODO: check name
	return httpc.answer.code.OK
end

function cserver:busyness()
	local mqlen = skynet.mqlen()
	local loadlv = mqlen / 100 -- >=1--高负载
	local busyness = (playermgr.onlinenum/playermgr.onlinelimit) * 0.8 + loadlv * 0.2
	return busyness
end

function cserver:starttimer()
	local interval = 10
	timer.timeout("server.on_tick",interval,function ()
		self:starttimer()
	end)
	pcall(self.on_tick,self)
end

function cserver:on_tick()
	local server = {
		busyness = self:busyness(),
		tcp_port = tonumber(skynet.getenv("tcp_port")),
		kcp_port = tonumber(skynet.getenv("kcp_port")),
		websocket_port = tonumber(skynet.getenv("websocket_port")),
		http_port = tonumber(skynet.getenv("http_port")),
		debug_port = tonumber(skynet.getenv("debug_port")),
	}
	local accountcenter = skynet.getenv("accountcenter")
	local appid = skynet.getenv("appid")
	local url = "/api/account/server/update"
	local req = httpc.make_request({
		appid = appid,
		serverid = self:serverid(),
		server = cjson.encode(server),
	})
	local status,response = httpc.post(accountcenter,url,req)
	assert(status == 200 and response.code == httpc.answer.code.OK)
	local url = "/api/account/server/list"
	local req = httpc.make_request({
		appid = appid,
		version = "0.0.0", -- 这个版本可以获取所有列表
		platform = "my",
		devicetype = "ios",
	})
	local status,response = httpc.post(accountcenter,url,req)
	assert(status == 200 and response.code == httpc.answer.code.OK)
	response = cjson.decode(response)
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
