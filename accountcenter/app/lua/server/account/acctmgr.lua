---账号角色管理器
--@usage
--redis数据库结构
--角色表: appid:role:角色ID => {roleid=xxx,appid=xxx,acct=xxx,create_serverid=xxx,...}
--账号表: acct:账号 => {acct=xxx,passwd=xxx,sdk=xxx,platform=xxx,...}
--账号已有角色表: appid:roles:账号 => {角色ID列表}
--
--mongo数据库结构
--角色表: role =>  {roleid=xxx,appid=xxx,acct=xxx,create_serverid=xxx,...}
--账号表: account => {acct=xxx,passwd=xxx,sdk=xxx,platform=xxx,...}
--账号已有角色表: account_roles => {acct=xxx,appid=xxx,roles={角色ID列表}}


local resty_string = require "resty.string"
local resty_md5 = require "resty.md5"
local cjson = require "cjson"
local redis = require "lib.redis"
local mongo = require "lib.mongo"
local Answer = require "answer"
local util = require "server.account.util"
local servermgr = require "server.account.servermgr"
local db_type = util.config().db.type

local acctmgr = {}

function acctmgr.saveacct(acctobj)
	if db_type == "redis" then
		local acct = assert(acctobj.acct)
		local db = redis:new()
		local key = string.format("acct:%s",acct)
		db:set(key,cjson.encode(acctobj))
		redis:close(db)
	else
		local acct = assert(acctobj.acct)
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("account")
		collection:update({acct=acct},acctobj,1,0)
		mongo:close(conn)
	end
end

function acctmgr.getacct(acct)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("acct:%s",acct)
		local retval = db:get(key)
		redis:close(db)
		if retval == nil or retval == ngx.null then
			return nil
		else
			return cjson.decode(retval)
		end
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("account")
		local doc = collection:find_one({acct=acct})
		mongo:close(conn)
		if doc == nil or doc == ngx.null then
			return nil
		else
			return mongo:pack_doc(doc)
		end
	end
end

--/*
-- acctobj: {acct=账号,passwd=密码,sdk=sdk,platform=平台,...}
--*/
function acctmgr.addacct(acctobj)
	local acct = assert(acctobj.acct)
	local has_acctobj = acctmgr.getacct(acct)
	if has_acctobj then
		return Answer.code.ACCT_EXIST
	end
	acctobj.createtime = os.time()
	ngx.log(ngx.INFO,string.format("op=addacct,acctobj=%s",cjson.encode(acctobj)))
	acctmgr.saveacct(acctobj)
	return Answer.code.OK
end

function acctmgr.delacct(acct)
	local acctobj = acctmgr.getacct(acct)
	if acctobj then
		ngx.log(ngx.INFO,string.format("op=delacct,acct=%s",acct))
		if db_type == "redis" then
			local db = redis:new()
			db:del(acct)
			redis:close(db)
		else
			local conn = mongo:new()
			local db = conn:new_db_handle("game")
			local collection = db:get_col("account")
			collection:delete({acct=acct},1)
			mongo:close(conn)
		end
		return Answer.code.OK
	end
	return Answer.code.ACCT_NOEXIST
end

-- 返回角色ID列表
function acctmgr.getroles(acct,appid)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:roles:%s",appid,acct)
		local retval = db:get(key)
		redis:close(db)
		if retval == nil or retval == ngx.null then
			return {}
		else
			return cjson.decode(retval)
		end
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("account_roles")
		local doc = collection:find_one({acct=acct,appid=appid})
		mongo:close(conn)
		if doc == nil then
			return {}
		else
			return doc.roles
		end
	end
end

function acctmgr.getrolelist(acct,appid)
	if db_type == "redis" then
		local db = redis:new()
		local roles = acctmgr.getroles(acct,appid)
		local keys = {}
		for i,roleid in ipairs(roles) do
			table.insert(keys,string.format("%s:role:%s",appid,roleid))
		end
		local rolelist = {}
		if #keys > 0 then
			rolelist = db:mget(table.unpack(keys))
		end
		redis:close(db)
		for i,data in ipairs(rolelist) do
			rolelist[i] = cjson.decode(data)
		end
		return rolelist
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("role")
		local cursor = collection:find({acct=acct,appid=appid})
		local docs = {}
		for i,doc in cursor:pairs() do
			table.insert(docs,mongo:pack_doc(doc))
		end
		mongo:close(conn)
		return docs
	end
end

-- roles: 角色ID列表
function acctmgr.saveroles(acct,appid,roles)
	assert(roles ~= nil)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:roles:%s",appid,acct)
		db:set(key,cjson.encode(roles))
		redis:close(db)
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("account_roles")
		local doc = {acct=acct,appid=appid,roles=roles}
		collection:update({acct=acct,appid=appid,},doc,1,0)
		mongo:close(conn)
	end
end

function acctmgr.checkrole(role)
	local role,err = table.check(role,{
		roleid = {type="string"},
		name = {type="string"},
		job = {type="number"},
		sex = {type="number"},
		shapeid = {type="number"},
		lv = {type="number",optional=true,default=0,},
		gold = {type="number",optional=true,default=0,},
	})
	return role,err
end

function acctmgr.addrole(acct,appid,serverid,role)
	local role,err = acctmgr.checkrole(role)
	if err then
		return Answer.code.ROLE_FMT_ERR
	end
	local roleid = assert(role.roleid)
	local name = assert(role.name)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	if not acctmgr.getacct(acct) then
		return Answer.code.ACCT_NOEXIST
	end
	if not servermgr.getserver(appid,serverid) then
		return Answer.code.SERVER_NOEXIST
	end
	local found = acctmgr.getrole(appid,roleid)
	if found then
		return Answer.code.ROLE_EXIST
	end
	local rolelist = acctmgr.getroles(acct,appid)
	local found = table.find(rolelist,roleid)
	if found then
		return Answer.code.ROLE_EXIST
	end
	role.appid = appid
	role.acct = acct
	role.create_serverid = serverid
	role.createtime = role.createtime or os.time()
	ngx.log(ngx.INFO,string.format("op=addrole,acct=%s,appid=%s,role=%s",acct,appid,cjson.encode(role)))
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:role:%s",appid,roleid)
		db:set(key,cjson.encode(role))
		redis:close(db)
		return Answer.code.OK
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("role")
		--collection:update({appid=appid,roleid=roleid,},role,1,0)
		collection:insert({role})
		mongo:close(conn)
		table.insert(rolelist,roleid)
		acctmgr.saveroles(acct,appid,rolelist)
		return Answer.code.OK
	end
end

function acctmgr.getrole(appid,roleid)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:role:%s",appid,roleid)
		local retval = db:get(key)
		redis:close(db)
		if retval == nil or retval == ngx.null then
			return nil
		else
			return cjson.decode(retval)
		end
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("role")
		local doc = collection:find_one({appid=appid,roleid=roleid})
		mongo:close(conn)
		if doc == nil or doc == ngx.null then
			return nil
		else
			return mongo:pack_doc(doc)
		end
	end
end

function acctmgr.delrole(appid,roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	local role = acctmgr.getrole(appid,roleid)
	if not role then
		return Answer.code.ROLE_NOEXIST
	end
	local acct = role.acct
	local rolelist = acctmgr.getroles(acct,appid)
	local found_pos = table.find(rolelist,roleid)
	if not found_pos then
		return Answer.code.ROLE_NOEXIST
	end
	ngx.log(ngx.INFO,string.format("op=delrole,acct=%s,appid=%s,role=%s",acct,appid,cjson.encode(role)))
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:role:%s",appid,roleid)
		db:del(key)
		redis:close(db)
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("role")
		collection:delete({appid=appid,roleid=roleid},1)
		mongo:close(conn)
	end
	table.remove(rolelist,found_pos)
	acctmgr.saveroles(acct,appid,rolelist)
	return Answer.code.OK
end

-- 增量更新
function acctmgr.updaterole(appid,syncrole)
	local roleid = assert(syncrole.roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	local role = acctmgr.getrole(appid,roleid)
	if not role then
		return Answer.code.ROLE_NOEXIST
	end
	ngx.log(ngx.DEBUG,string.format("op=updaterole,appid=%s,syncrole=%s",appid,cjson.encode(syncrole)))
	table.update(role,syncrole)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:role:%s",appid,roleid)
		db:set(key,cjson.encode(role))
		redis:close(db)
		return Answer.code.OK
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("role")
		collection:update({appid=appid,roleid=roleid,},role,1,0)
		mongo:close(conn)
		return Answer.code.OK
	end
end

-- 有效范围: [minroleid,maxroleid)
function acctmgr.genroleid(appid,idkey,minroleid,maxroleid)
	minroleid = tonumber(minroleid)
	maxroleid = tonumber(maxroleid)
	assert(appid)
	assert(idkey)
	assert(minroleid)
	assert(maxroleid)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("roleid:%s:%s",appid,idkey)
		-- roleid in range [minroleid,maxroleid)
		local valid_range = maxroleid - minroleid
		local range = db:get(key)
		range = tonumber(range)
		if range and range >= valid_range then
			return nil
		else
			range = db:incr(key)
		end
		if range > valid_range then
			return nil
		end
		redis:close(db)
		return tostring(minroleid+range-1)
	else
		local valid_range = maxroleid - minroleid
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("roleid")
		local doc = collection:find_and_modify({
				query = {appid = appid,idkey = idkey,},
				update = {["$inc"] = {value = 1}},
				new = 1,
				upsert = 1,
			})
		local range = doc.value
		if range > valid_range then
			return nil
		end
		mongo:close(conn)
		return tostring(minroleid+range-1)
	end
end

function acctmgr.gentoken(input)
	local data = {
		input = input,
		time = os.time(),
		rand = math.random(1,1000000),
	}
	local str = cjson.encode(data)
	local md5 = resty_md5:new()
	md5:update(str)
	return resty_string.to_hex(md5:final())
end

function acctmgr.gettoken(token)
	--[[
	local db = redis:new()
	local retval = db:get(string.format("token:%s",token))
	redis:close(db)
	if retval == nil or retval == ngx.null then
		return nil
	else
		return cjson.decode(retval)
	end
	]]
	local tokens = ngx.shared.tokens
	local retval = tokens:get(token)
	if retval == nil or retval == ngx.null then
		return nil
	else
		return cjson.decode(retval)
	end
end

function acctmgr.addtoken(token,data,expire)
	--[[
	assert(data ~= nil)
	expire = expire or 300
	local db = redis:new()
	local key = string.format("token:%s",token)
	db:set(key,cjson.encode(data))
	db:expire(key,expire)
	]]
	assert(data ~= nil)
	expire = expire or 300
	local tokens = ngx.shared.tokens
	tokens:set(token,cjson.encode(data),expire)
end

function acctmgr.deltoken(token)
	--[[
	local db = redis:new()
	db:del(string.format("token:%s",token))
	redis:close(db)
	]]
	local tokens = ngx.shared.tokens
	tokens:delete(token)
end


-- 角色换绑服务器
function acctmgr.rebindsrv(acct,appid,new_serverid,old_roleid,new_roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	if not acctmgr.getacct(acct) then
		return Answer.code.ACCT_NOEXIST
	end
	if not servermgr.getserver(appid,new_serverid) then
		return Answer.code.SERVER_NOEXIST
	end
	local old_role = acctmgr.getrole(appid,old_roleid)
	if not old_role then
		return Answer.code.ROLE_NOEXIST
	end
	if old_roleid == new_roleid then
		if old_role.create_serverid == new_serverid then
			-- unchange
			return Answer.code.OK
		end
	else
		local new_role = acctmgr.getrole(appid,new_roleid)
		if new_role then
			return Answer.code.ROLE_EXIST
		end
	end
	ngx.log(ngx.INFO,string.format("op=rebindsrv,acct=%s,appid=%s,old_serverid=%s,new_serverid=%s,old_roleid=%s,new_roleid=%s",acct,appid,old_role.create_serverid,new_serverid,old_roleid,new_roleid))
	if old_roleid == new_roleid then
		acctmgr.updaterole(appid,{roleid=new_roleid,create_serverid=new_serverid})
	else
		acctmgr.delrole(appid,old_roleid)
		old_role.roleid = new_roleid
		acctmgr.addrole(acct,appid,new_serverid,old_role)
	end
	return Answer.code.OK
end

-- 角色换绑帐号
function acctmgr.rebindacct(new_acct,appid,roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	local new_acctobj = acctmgr.getacct(new_acct)
	if not new_acctobj then
		return Answer.code.ACCT_NOEXIST
	end
	local role = acctmgr.getrole(appid,roleid)
	if not role then
		return Answer.code.ROLE_NOEXIST
	elseif role.acct == new_acct then
		-- nochange
		return Answer.code.OK
	end
	local old_acct = role.acct
	ngx.log(ngx.INFO,string.format("op=rebindacct,appid=%s,roleid=%s,old_acct=%s,new_acct=%s",appid,roleid,old_acct,new_acct))
	acctmgr.delrole(appid,roleid)
	role.acct = new_acct
	acctmgr.addrole(new_acct,appid,role.create_serverid,role)
	return Answer.code.OK
end


return acctmgr
