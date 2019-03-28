---账号角色管理器
--@usage
--redis数据库结构
--角色表: appid:role:角色ID => {roleid=xxx,appid=xxx,account=xxx,create_serverid=xxx,...}
--账号表: account:账号 => {account=xxx,passwd=xxx,sdk=xxx,platform=xxx,...}
--账号已有角色表: appid:roles:账号 => {角色ID列表}
--
--mongo数据库结构
--角色表: role =>  {roleid=xxx,appid=xxx,account=xxx,create_serverid=xxx,...}
--账号表: account => {account=xxx,passwd=xxx,sdk=xxx,platform=xxx,...}
--账号已有角色表: account_roles => {account=xxx,appid=xxx,roles={角色ID列表}}


local resty_string = require "resty.string"
local resty_md5 = require "resty.md5"
local cjson = require "cjson"
local redis = require "lib.redis"
local mongo = require "lib.mongo"
local Answer = require "answer"
local util = require "server.account.util"
local servermgr = require "server.account.servermgr"
local db_type = util.config().db.type

local accountmgr = {}

function accountmgr.saveaccount(accountobj)
	if db_type == "redis" then
		local account = assert(accountobj.account)
		local db = redis:new()
		local key = string.format("account:%s",account)
		db:set(key,cjson.encode(accountobj))
		redis:close(db)
	else
		local account = assert(accountobj.account)
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("account")
		collection:update({account=account},accountobj,1,0)
		mongo:close(conn)
	end
end

function accountmgr.getaccount(account)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("account:%s",account)
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
		local doc = collection:find_one({account=account})
		mongo:close(conn)
		if doc == nil or doc == ngx.null then
			return nil
		else
			return mongo:pack_doc(doc)
		end
	end
end

--/*
-- accountobj: {account=账号,passwd=密码,sdk=sdk,platform=平台,...}
--*/
function accountmgr.addaccount(accountobj)
	local account = assert(accountobj.account)
	local has_accountobj = accountmgr.getaccount(account)
	if has_accountobj then
		return Answer.code.ACCT_EXIST
	end
	accountobj.createtime = os.time()
	ngx.log(ngx.INFO,string.format("op=addaccount,accountobj=%s",cjson.encode(accountobj)))
	accountmgr.saveaccount(accountobj)
	return Answer.code.OK
end

function accountmgr.delaccount(account)
	local accountobj = accountmgr.getaccount(account)
	if accountobj then
		ngx.log(ngx.INFO,string.format("op=delaccount,account=%s",account))
		if db_type == "redis" then
			local db = redis:new()
			db:del(account)
			redis:close(db)
		else
			local conn = mongo:new()
			local db = conn:new_db_handle("game")
			local collection = db:get_col("account")
			collection:delete({account=account},1)
			mongo:close(conn)
		end
		return Answer.code.OK
	end
	return Answer.code.ACCT_NOEXIST
end

-- 返回角色ID列表
function accountmgr.getroles(account,appid)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:roles:%s",appid,account)
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
		local doc = collection:find_one({account=account,appid=appid})
		mongo:close(conn)
		if doc == nil then
			return {}
		else
			return doc.roles
		end
	end
end

function accountmgr.getrolelist(account,appid)
	if db_type == "redis" then
		local db = redis:new()
		local roles = accountmgr.getroles(account,appid)
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
		local cursor = collection:find({account=account,appid=appid})
		local docs = {}
		for i,doc in cursor:pairs() do
			table.insert(docs,mongo:pack_doc(doc))
		end
		mongo:close(conn)
		return docs
	end
end

-- roles: 角色ID列表
function accountmgr.saveroles(account,appid,roles)
	assert(roles ~= nil)
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:roles:%s",appid,account)
		db:set(key,cjson.encode(roles))
		redis:close(db)
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("account_roles")
		local doc = {account=account,appid=appid,roles=roles}
		collection:update({account=account,appid=appid,},doc,1,0)
		mongo:close(conn)
	end
end

function accountmgr.checkrole(role)
	local role,err = table.check(role,{
		roleid = {type="number"},
		name = {type="string"},
		job = {type="number",optional=true},
		sex = {type="number",optional=true},
		shapeid = {type="number",optional=true,},
		lv = {type="number",optional=true,default=0,},
		gold = {type="number",optional=true,default=0,},
	})
	return role,err
end

function accountmgr.addrole(account,appid,serverid,role)
	local role,err = accountmgr.checkrole(role)
	if err then
		return Answer.code.ROLE_FMT_ERR
	end
	local roleid = assert(role.roleid)
	local name = assert(role.name)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	if not accountmgr.getaccount(account) then
		return Answer.code.ACCT_NOEXIST
	end
	if not servermgr.getserver(appid,serverid) then
		return Answer.code.SERVER_NOEXIST
	end
	local found = accountmgr.getrole(appid,roleid)
	if found then
		return Answer.code.ROLE_EXIST
	end
	local rolelist = accountmgr.getroles(account,appid)
	local found = table.find(rolelist,roleid)
	if found then
		return Answer.code.ROLE_EXIST
	end
	role.appid = appid
	role.account = account
	role.create_serverid = serverid
	role.createtime = role.createtime or os.time()
	ngx.log(ngx.INFO,string.format("op=addrole,account=%s,appid=%s,role=%s",account,appid,cjson.encode(role)))
	if db_type == "redis" then
		local db = redis:new()
		local key = string.format("%s:role:%s",appid,roleid)
		db:set(key,cjson.encode(role))
		redis:close(db)
	else
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("role")
		--collection:update({appid=appid,roleid=roleid,},role,1,0)
		collection:insert({role})
		mongo:close(conn)
	end
	table.insert(rolelist,roleid)
	accountmgr.saveroles(account,appid,rolelist)
	return Answer.code.OK
end

function accountmgr.getrole(appid,roleid)
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

function accountmgr.delrole(appid,roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	local role = accountmgr.getrole(appid,roleid)
	if not role then
		return Answer.code.ROLE_NOEXIST
	end
	local account = role.account
	local rolelist = accountmgr.getroles(account,appid)
	local found_pos = table.find(rolelist,roleid)
	if not found_pos then
		return Answer.code.ROLE_NOEXIST
	end
	ngx.log(ngx.INFO,string.format("op=delrole,account=%s,appid=%s,role=%s",account,appid,cjson.encode(role)))
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
	accountmgr.saveroles(account,appid,rolelist)
	return Answer.code.OK
end

-- 增量更新
function accountmgr.updaterole(appid,syncrole)
	local roleid = assert(syncrole.roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	local role = accountmgr.getrole(appid,roleid)
	if not role then
		return Answer.code.ROLE_NOEXIST
	end
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
function accountmgr.genroleid(appid,idkey,minroleid,maxroleid)
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
		return minroleid+range-1
	else
		local valid_range = maxroleid - minroleid
		local conn = mongo:new()
		local db = conn:new_db_handle("game")
		local collection = db:get_col("roleid")
		local doc = collection:find_and_modify({
				query = {appid = appid,idkey = idkey,},
				update = {["$inc"] = {sequence = 1}},
				new = 1,
				upsert = 1,
			})
		mongo:close(conn)
		local range = doc.sequence
		if range > valid_range then
			return nil
		end
		return minroleid+range-1
	end
end

function accountmgr.gentoken(input)
	local now = ngx.now()
	local str = tostring(input) .. now
	local md5 = resty_md5:new()
	str = str .. tostring(md5)
	md5:update(str)
	return resty_string.to_hex(md5:final())
end

function accountmgr.gettoken(token)
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

function accountmgr.addtoken(token,data,expire)
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

function accountmgr.deltoken(token)
	--[[
	local db = redis:new()
	db:del(string.format("token:%s",token))
	redis:close(db)
	]]
	local tokens = ngx.shared.tokens
	tokens:delete(token)
end


-- 角色换绑服务器
function accountmgr.rebindserver(account,appid,new_serverid,old_roleid,new_roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	if not accountmgr.getaccount(account) then
		return Answer.code.ACCT_NOEXIST
	end
	if not servermgr.getserver(appid,new_serverid) then
		return Answer.code.SERVER_NOEXIST
	end
	local old_role = accountmgr.getrole(appid,old_roleid)
	if not old_role then
		return Answer.code.ROLE_NOEXIST
	end
	if old_roleid == new_roleid then
		if old_role.create_serverid == new_serverid then
			-- unchange
			return Answer.code.OK
		end
	else
		local new_role = accountmgr.getrole(appid,new_roleid)
		if new_role then
			return Answer.code.ROLE_EXIST
		end
	end
	ngx.log(ngx.INFO,string.format("op=rebindserver,account=%s,appid=%s,old_serverid=%s,new_serverid=%s,old_roleid=%s,new_roleid=%s",
		account,appid,old_role.create_serverid,new_serverid,old_roleid,new_roleid))
	if old_roleid == new_roleid then
		accountmgr.updaterole(appid,{roleid=new_roleid,create_serverid=new_serverid})
	else
		accountmgr.delrole(appid,old_roleid)
		old_role.roleid = new_roleid
		accountmgr.addrole(account,appid,new_serverid,old_role)
	end
	return Answer.code.OK
end

-- 角色换绑帐号
function accountmgr.rebindaccount(new_account,appid,roleid)
	if not util.get_app(appid) then
		return Answer.code.APPID_NOEXIST
	end
	local new_accountobj = accountmgr.getaccount(new_account)
	if not new_accountobj then
		return Answer.code.ACCT_NOEXIST
	end
	local role = accountmgr.getrole(appid,roleid)
	if not role then
		return Answer.code.ROLE_NOEXIST
	elseif role.account == new_account then
		-- nochange
		return Answer.code.OK
	end
	local old_account = role.account
	ngx.log(ngx.INFO,string.format("op=rebindaccount,appid=%s,roleid=%s,old_account=%s,new_account=%s",appid,roleid,old_account,new_account))
	accountmgr.delrole(appid,roleid)
	role.account = new_account
	accountmgr.addrole(new_account,appid,role.create_serverid,role)
	return Answer.code.OK
end


return accountmgr
