local cjson = require "cjson"
local redis = require "lib.redis"
local mongo = require "lib.mongo"
local Answer = require "answer"
local util = require "server.account.util"
local db_type = util.config().db.type

local servermgr = {}

function servermgr.saveserver(appid,server)
	if db_type == "redis" then
		local db = redis:new()
		local id = assert(server.id)
		local key = string.format("server:%s",appid)
		db:hset(key,id,cjson.encode(server))
		redis:close(db)
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("server")
		local id = assert(server.id)
		server.appid = appid
		collection:update({appid=appid,id=id},server,1,0)
		mongo:close(conn)
	end
end

function servermgr.loadserver(appid,serverid)
	if db_type == "redis" then
		local db,err = redis:new()
		local key = string.format("server:%s",appid)
		local retval = db:hget(key,serverid)
		redis:close(db)
		if retval == nil or retval == ngx.null then
			return nil
		else
			return cjson.decode(retval)
		end
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("server")
		local doc = collection:find_one({appid=appid,id=serverid})
		mongo:close(conn)
		if doc == nil or doc == ngx.null then
			return nil
		else
			return mongo:pack_doc(doc)
		end
	end
end


function servermgr.checkserver(server)
	local server,err = table.check(server,{
		ip = {type="string"},									-- ip
		cluster_ip = {type="string",optional=true},				-- 集群ip
		cluster_port = {type="number",optional=true},			-- 集群端口
		tcp_port = {type="number",optional=true},				-- tcp端口
		kcp_port = {type="number",optional=true},				-- kcp端口
		websocket_port = {type="number",optional=true},			-- websocket端口
		debug_port = {type="number",optional=true},				-- debug端口
		http_port = {type="number",optional=true},				-- http端口
		id = {type="string"},									-- 服务器ID
		name = {type="string"},									-- 服务器名
		index = {type="number"},								-- 服务器编号
		type = {type="string"},									-- 服务器类型
		zoneid = {type="string"},								-- 区ID
		zonename = {type="string"},								-- 区名
		area = {type="string"},									-- 大区ID
		areaname = {type="string"},								-- 大区名
		env = {type="string"},									-- 部署环境ID
		envname = {type="string"},								-- 部署环境名
		opentime = {type="number"},								-- 预计开服时间
		isopen = {type="number",optional=true,default=1},		-- 是否开放
		busyness = {type="number",optional=true,default=0.0},	-- 负载
		newrole = {type="number",optional=true,default=1},		-- 是否可以新建角色
		updatetime = {type="number",optional=true,default=os.time()}, -- 更新时间
	})
	return server,err
end

function servermgr.addserver(appid,server)
	local server,err = servermgr.checkserver(server)
	if err then
		return Answer.code.SERVER_FMT_ERR
	end
	if not (server.tcp_port or server.kcp_port or server.websocket_port) then
		return Answer.code.SERVER_FMT_ERR
	end
	server.createtime = os.time()
	servermgr.saveserver(appid,server)
	return Answer.code.OK
end

function servermgr.delserver(appid,serverid)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("server:%s",appid)
		local retval = db:hdel(key,serverid)
		redis:close(db)
		if retval == 0 then
			return Answer.code.SERVER_NOEXIST
		else
			return Answer.code.OK
		end
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("server")
		local n = collection:delete({appid=appid,id=serverid},1,1)
		mongo:close(conn)
		if n == 0 then
			return Answer.code.SERVER_NOEXIST
		else
			return Answer.code.OK
		end
	end
end

function servermgr.updateserver(appid,sync_server)
	local serverid = assert(sync_server.id)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	local server = servermgr.getserver(appid,serverid)
	if not server then
		return Answer.code.SERVER_NOEXIST
	end
	table.update(server,sync_server)
	servermgr.saveserver(appid,server)
	return Answer.code.OK
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

function servermgr.getserverlist(appid)
	if db_type == "redis" then
		local serverlist = {}
		local db = redis:new()
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
		redis:close(db)
		return serverlist
	else
		local serverlist = {}
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("server")
		local r = collection:find({appid=appid})
		local docs = r:sort({n=1})
		local now = os.time()
		for i,doc in ipairs(docs) do
			local server = mongo:pack_doc(doc)
			local online = (now - (server.updatetime or 0)) < 40
			if online then
				server.state = "online"
			else
				server.state = "down"
			end
			table.insert(serverlist,server)
		end
		mongo:close(conn)
		return serverlist
	end
end

return servermgr
