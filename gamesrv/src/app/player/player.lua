cplayer = class("cplayer")

function cplayer:init(pid)
	self.pid = assert(pid)
	self.attr = cattr.new(self)
	self.data = cdatabaseable.new()
	self.today = ctoday.new()
	self.thistemp = cthistemp.new()
	self.thisweek = cthisweek.new()
	self.thisweek2 = cthisweek2.new()
	self.thismonth = cthismonth.new()
	self.today:register(function(data,dayno)
		local player = playermgr.getplayer(pid)
		player:oncleartoday(data,dayno)
	end)
	self.thisweek:register(function (data,dayno)
		local player = playermgr.getplayer(pid)
		player:onclearthisweek(data,dayno)
	end)
	self.time = cattrcontainer.new{
		today = self.today,
		thistemp = self.thistemp,
		thisweek = self.thisweek,
		thisweek2 = self.thisweek2,
		thismonth = self.thismonth,
	}
	self.component = {
		attr = self.attr,
		data = self.data,
		time = self.time,
	}
	-- 依序发包
	self.onloginlist = {}
	self.loadstate = "unload"
end

function cplayer:load(toload)
	if table.isempty(toload) then
		return
	end
	for name,data in pairs(toload) do
		local obj = self.component[name]
		if obj then
			obj:load(data)
		elseif type(data) == "table" then
			-- 纯数据组件
			self.component[name] = data
		end
	end
	self.loadstate = "loaded"
	self:onload()
end

function cplayer:save()
	local data = {}
	for name,obj in pairs(self.component) do
		if not obj.nosavetodatabase then
			if obj.save then
				data[name] = obj:save()
			else
				assert(type(obj) == "table")
				-- 纯数据组件
				data[name] = obj
			end
		end
	end
	return data
end

function cplayer:isloaded()
	return self.loadstate == "loaded"
end

function cplayer:onload()
	for k,obj in pairs(self.component) do
		if obj.onload then
			obj:onload(self)
		elseif obj.exec then
			obj:exec("onload",self)
		end
	end
end

function cplayer:deletefromdatabase()
	if dbmgr.db_type == "redis" then
		local db = dbmgr.getdb()
		local key = string.format("role:%s",self.pid)
		db:del(key)
	else
		local db = dbmgr.getdb()
		db.game.player:delete({pid=self.pid})
	end
	savemgr.closesave(self)
end

function cplayer:savetodatabase()
	-- 保活token用以作快速重连
	if (not self.debuglogin) and self.token then
		playermgr.tokens:expire(self.token,302)
	end
	if dbmgr.db_type == "redis" then
		local db = dbmgr.getdb()
		local key = string.format("role:%s",self.pid)
		local data = self:save()
		for name,objdata in pairs(data) do
			objdata = cjson.encode(objdata)
			db:hset(key,name,objdata)
		end
	else
		local db = dbmgr.getdb()
		local data = self:save()
		data.pid = self.pid
		db.game.player:update({pid=self.pid},data,true,false)
	end
end

function cplayer:loadfromdatabase()
	if dbmgr.db_type == "redis" then
		local db = dbmgr.getdb()
		local data = {}
		local key = string.format("role:%s",self.pid)
		local list = db:hgetall(key)
		for i=1,#list,2 do
			local name,objdata = list[i],list[i+1]
			data[name] = cjson.decode(objdata)
		end
		self:load(data)
	else
		local db = dbmgr.getdb()
		local data = db.game.player:findOne({pid=self.pid})
		self:load(data)
	end
end

function cplayer:create(conf)
	self.name = assert(conf.name)
	self.account = assert(conf.account)
end

function cplayer:entergame(replace)
	-- oncreate 放到首次登录时执行,create调用时player未纳入playermgr管理
	local logincnt = self:get("logincnt") or 0
	if logincnt == 0 then
		self:add("logincnt",1)
		self:oncreate()
	end
	self:onlogin(replace)
end

--- 主动掉线
--@breif 主动掉线会触发退出游戏流程
--@param[type=string] reason 原因
function cplayer:disconnect(reason)
	if self:isdisconnect() then
		return
	end
	self:ondisconnect(reason)
	local linkobj = self.linkobj
	playermgr.unbind_linkobj(self)
	client.dellinkobj(linkobj.linkid)
	-- 顶号不退出游戏
	if reason ~= "replace" then
		self:exitgame(reason)
	end
end

function cplayer:exitgame(reason)
	xpcall(self.onlogoff,onerror,self,reason)
	-- will call savetodatabase
	playermgr.delplayer(self.pid)
end

function cplayer:isdisconnect()
	if not self.linkobj then
		return true
	end
	return false
end

-- 跨服前处理流程
function cplayer:ongosrv(go_serverid)
end

function cplayer:synctoac(online)
	skynet.fork(self._synctoac,self,online)
end

function cplayer:_synctoac(online)
	local role = {
		roleid = self.pid,
		name = self.name,
		lv = self.lv,
		gold = self.gold,
		now_serverid = gg.server.id,
		online = online,
	}
	local accountcenter = skynet.getenv("accountcenter")
	local appid = skynet.getenv("appid")
	local url = "/api/account/role/update"
	local req = httpc.make_request({
		appid = appid,
		roleid = self.pid,
		role = cjson.encode(role),
	})
	httpc.postx(accountcenter,url,req)
end

function cplayer:oncreate()
	local my_serverid = gg.server.id
	logger.logf("info","login","op=oncreate,serverid=%s,account=%s,pid=%s,linktype=%s,linkid=%s,ip=%s,port=%s,version=%s,name=%s",
		my_serverid,self.account,self.pid,self.linktype,self.linkid,self.ip,self.port,self.version,self.name)
	for k,obj in pairs(self.component) do
		obj.loadstate = "loaded"
		if obj.oncreate then
			obj:oncreate(self)
		elseif obj.exec then
			obj:exec("oncreate",self)
		end
	end
end

-- 兼容处理
function cplayer:compat(replace)
	-- TODO: something
	self:compat_todo_delete(replace)
end

-- 开发阶段数据兼容的代码，正式上线后删除
function cplayer:compat_todo_delete(replace)
end

function cplayer:onlogin(replace)
	local my_serverid = gg.server.id
	local from_serverid = self.kuafu_forward and self.kuafu_forward.from_serverid
	logger.logf("info","login","op=onlogin,serverid=%s,from_serverid=%s,account=%s,pid=%s,linktype=%s,linkid=%s,ip=%s,port=%s,replace=%s,version=%s",
		my_serverid,from_serverid,self.account,self.pid,self.linktype,self.linkid,self.ip,self.port,replace,self.version)
	self:compat(replace)
	for _,k in ipairs(self.onloginlist) do
		local obj = self[k]
		if obj then
			if obj.onlogin then
				obj:onlogin(self,replace)
			elseif obj.exec then
				obj:exec("onlogin",self,replace)
			end
		end
	end
	if self.kuafu_forward then
		local kuafu_forward = self.kuafu_forward
		self.kuafu_forward = nil
		if kuafu_forward.onlogin then
			local onlogin = unpack_function(kuafu_forward.onlogin)
			xpcall(onlogin,onerror)
		end
	end
	self:synctoac(true)
end

function cplayer:onlogoff(reason)
	local my_serverid = gg.server.id
	local from_serverid = self.kuafu_forward and self.kuafu_forward.from_serverid
	logger.logf("info","login","op=onlogoff,serverid=%s,from_serverid=%s,account=%s,pid=%s,linktype=%s,linkid=%s,ip=%s,port=%s,version=%s,reason=%s",
		my_serverid,from_serverid,self.account,self.pid,self.linktype,self.linkid,self.ip,self.port,self.version,reason)
	for k,obj in pairs(self.component) do
		if obj.onlogoff then
			obj:onlogoff(self,reason)
		elseif obj.exec then
			obj:exec("onlogoff",self,reason)
		end
	end
	self:synctoac(false)
end

function cplayer:ondisconnect(reason)
	logger.logf("info","login","op=ondisconnect,pid=%s,linkid=%s,ip=%s,port=%s,reason=%s",
		self.pid,self.linkid,self.ip,self.port,reason)
	for k,obj in pairs(self.component) do
		if obj.ondisconnect then
			obj:ondisconnect(self,reason)
		elseif obj.exec then
			obj:exec("ondisconnect",self,reason)
		end
	end
end

function cplayer:ondayupdate()
	for k,obj in pairs(self.component) do
		if obj.ondayupdate then
			obj:ondayupdate()
		elseif obj.exec then
			obj:exec("ondayupdate")
		end
	end
end

function cplayer:onmondayupdate()
	for k,obj in pairs(self.component) do
		if obj.onmondayupdate then
			obj:onmondayupdate()
		elseif obj.exec then
			obj:exec("onmondayupdate")
		end
	end
end

function cplayer:onmonthupdate()
end

function cplayer:onhourupdate()
end

function cplayer:oncleartoday(data,dayno)
end

function cplayer:onclearthisweek(data,dayno)
end

function cplayer:genid()
	return self:add("id",1)
end

function cplayer:get(key,default)
	return self.data:get(key,default)
end

function cplayer:set(key,val)
	return self.data:set(key,val)
end

function cplayer:add(key,val)
	return self.data:add(key,val)
end

function cplayer:del(key)
	return self.data:del(key)
end

return cplayer
