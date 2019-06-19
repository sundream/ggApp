---账号角色管理器
--@usage
--redis数据库结构
--角色表: appid:role:角色ID => {roleid=xxx,appid=xxx,account=xxx,create_serverid=xxx,...}
--账号表: account:账号 => {account=xxx,passwd=xxx,sdk=xxx,platform=xxx,...}
--账号已有角色表: appid:roles:账号 => {角色ID列表}
--账号已删除角色表: appid:deleted_roles:账号 => {角色ID列表}
--
--mongo数据库结构
--角色表: role =>  {roleid=xxx,appid=xxx,account=xxx,create_serverid=xxx,...}
--账号表: account => {account=xxx,passwd=xxx,sdk=xxx,platform=xxx,...}
--账号已有角色表: account_roles => {account=xxx,appid=xxx,roles={角色ID列表}}
--账号已删除角色表: account_deleted_roles => {account=xxx,appid=xxx,roles={角色ID列表}}


accountmgr = accountmgr or {}

function accountmgr.saveaccount(accountobj)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local account = assert(accountobj.account)
        local key = string.format("account:%s",account)
        db:set(key,cjson.encode(accountobj))
    else
        local account = assert(accountobj.account)
        db.account:update({account=account},accountobj,true,false)
    end
end

function accountmgr.getaccount(account)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("account:%s",account)
        local retval = db:get(key)
        if retval == nil then
            return nil
        else
            return cjson.decode(retval)
        end
    else
        local doc = db.account:findOne({account=account})
        if doc == nil then
            return nil
        else
            doc._id = nil
            return doc
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
        return httpc.answer.code.ACCT_EXIST
    end
    accountobj.createtime = os.time()
    logger.logf("info","account",string.format("op=addaccount,accountobj=%s",cjson.encode(accountobj)))
    accountmgr.saveaccount(accountobj)
    return httpc.answer.code.OK
end

function accountmgr.delaccount(account)
    local accountobj = accountmgr.getaccount(account)
    if accountobj then
        logger.logf("info","account",string.format("op=delaccount,account=%s",account))
        local db = dbmgr:getdb()
        if dbmgr.db_type == "redis" then
            db:del(account)
        else
            db.player:delete({account=account})
        end
        return httpc.answer.code.OK
    end
    return httpc.answer.code.ACCT_NOEXIST
end

-- 返回角色ID列表
function accountmgr.getroles(account,appid)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("%s:roles:%s",appid,account)
        local retval = db:get(key)
        if retval == nil then
            return {}
        else
            return cjson.decode(retval)
        end
    else
        local doc = db.account_roles:findOne({account=account,appid=appid})
        if doc == nil then
            return {}
        else
            return doc.roles
        end
    end
end

function accountmgr.getrolelist(account,appid)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local roles = accountmgr.getroles(account,appid)
        local keys = {}
        for i,roleid in ipairs(roles) do
            table.insert(keys,string.format("%s:role:%s",appid,roleid))
        end
        local rolelist = {}
        if #keys > 0 then
            rolelist = db:mget(table.unpack(keys))
        end
        for i,data in ipairs(rolelist) do
            rolelist[i] = cjson.decode(data)
        end
        return rolelist
    else
        local cursor = db.role:find({account=account,appid=appid})
        local docs = {}
        while cursor:hasNext() do
            local doc = cursor:next()
            doc._id = nil
            table.insert(docs,doc)
        end
        return docs
    end
end

-- roles: 角色ID列表
function accountmgr.saveroles(account,appid,roles)
    assert(roles ~= nil)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("%s:roles:%s",appid,account)
        db:set(key,cjson.encode(roles))
    else
        local doc = {account=account,appid=appid,roles=roles}
        db.account_roles:update({account=account,appid=appid},doc,true,false)
    end
end

-- 保存删除的角色列表
-- roles: 角色ID列表
function accountmgr.save_deleted_roles(account,appid,roles)
    assert(roles ~= nil)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("%s:deleted_roles:%s",appid,account)
        db:set(key,cjson.encode(roles))
    else
        local doc = {account=account,appid=appid,roles=roles}
        db.account_deleted_roles:update({account=account,appid=appid},doc,true,false)
    end
end

-- 返回已删除角色ID列表
function accountmgr.get_deleted_roles(account,appid)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("%s:deleted_roles:%s",appid,account)
        local retval = db:get(key)
        if retval == nil then
            return {}
        else
            return cjson.decode(retval)
        end
    else
        local doc = db.account_deleted_roles:findOne({account=account,appid=appid})
        if doc == nil then
            return {}
        else
            return doc.roles
        end
    end
end

function accountmgr.checkrole(role)
    local role,err = table.check(role,{
        roleid = {type="number"},
        name = {type="string"},
        sex = {type="number",optional=true},
        job = {type="string",optional=true},
        shapeid = {type="string",optional=true,},
        lv = {type="number",optional=true,default=0,},
        gold = {type="number",optional=true,default=0,},
    })
    return role,err
end

function accountmgr.addrole(account,appid,serverid,role)
    local role,err = accountmgr.checkrole(role)
    if err then
        return httpc.answer.code.ROLE_FMT_ERR,err
    end
    local roleid = assert(role.roleid)
    local name = assert(role.name)
    if not util.get_app(appid) then
        return httpc.answer.code.APPID_NOEXIST
    end
    if not accountmgr.getaccount(account) then
        return httpc.answer.code.ACCT_NOEXIST
    end
    if not servermgr.getserver(appid,serverid) then
        return httpc.answer.code.SERVER_NOEXIST
    end
    local found = accountmgr.getrole(appid,roleid)
    if found then
        return httpc.answer.code.ROLE_EXIST
    end
    local rolelist = accountmgr.getroles(account,appid)
    local found = table.find(rolelist,roleid)
    if found then
        return httpc.answer.code.ROLE_EXIST
    end
    role.appid = appid
    role.account = account
    role.create_serverid = serverid
    role.now_serverid = serverid
    role.createtime = role.createtime or os.time()
    logger.logf("info","account",string.format("op=addrole,account=%s,appid=%s,role=%s",account,appid,cjson.encode(role)))
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("%s:role:%s",appid,roleid)
        db:set(key,cjson.encode(role))
    else
        --db.role:update({appid=appid,roleid=roleid},role,true,false)
        db.role:insert(role)
    end
    table.insert(rolelist,roleid)
    accountmgr.saveroles(account,appid,rolelist)
    return httpc.answer.code.OK
end

function accountmgr.getrole(appid,roleid)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("%s:role:%s",appid,roleid)
        local retval = db:get(key)
        if retval == nil then
            return nil
        else
            return cjson.decode(retval)
        end
    else
        local doc = db.role:findOne({appid=appid,roleid=roleid})
        if doc == nil then
            return nil
        else
            doc._id = nil
            return doc
        end
    end
end

function accountmgr.delrole(appid,roleid,forever)
    if not util.get_app(appid) then
        return httpc.answer.code.APPID_NOEXIST
    end
    local role = accountmgr.getrole(appid,roleid)
    if not role then
        return httpc.answer.code.ROLE_NOEXIST
    end
    local account = role.account
    local rolelist = accountmgr.getroles(account,appid)
    local found_pos = table.find(rolelist,roleid)
    if not found_pos then
        return httpc.answer.code.ROLE_NOEXIST
    end
    logger.logf("info","account",string.format("op=delrole,account=%s,appid=%s,role=%s,forever=%s",account,appid,cjson.encode(role),forever))
    if forever then
        local db = dbmgr:getdb()
        if dbmgr.db_type == "redis" then
            local key = string.format("%s:role:%s",appid,roleid)
            db:del(key)
        else
            db.role:delete({appid=appid,roleid=roleid},true)
        end
    else
        local deleted_rolelist = accountmgr.get_deleted_roles(account,appid)
        table.insert(deleted_rolelist,roleid)
        accountmgr.save_deleted_roles(account,appid,deleted_rolelist)
    end
    table.remove(rolelist,found_pos)
    accountmgr.saveroles(account,appid,rolelist)
    return httpc.answer.code.OK
end

-- 增量更新
function accountmgr.updaterole(appid,syncrole)
    local roleid = assert(syncrole.roleid)
    if not util.get_app(appid) then
        return httpc.answer.code.APPID_NOEXIST
    end
    local role = accountmgr.getrole(appid,roleid)
    if not role then
        return httpc.answer.code.ROLE_NOEXIST
    end
    table.update(role,syncrole)
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("%s:role:%s",appid,roleid)
        db:set(key,cjson.encode(role))
        return httpc.answer.code.OK,role
    else
        db.role:update({appid=appid,roleid=roleid},role,true,false)
        return httpc.answer.code.OK,role
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
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
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
        return minroleid+range-1
    else
        local valid_range = maxroleid - minroleid
        local doc = db.roleid:findAndModify({
            query = {appid=appid,idkey=idkey},
            update = {["$inc"] = {sequence = 1}},
            new = true,
            upsert = true,
        })
        local range = doc.value.sequence
        if range > valid_range then
            return nil
        end
        return minroleid+range-1
    end
end

function accountmgr.gentoken(input)
    local prefix = string.format("loginserver.%s.",skynet.hpc())
    local token = prefix .. string.randomkey(8)
    return token
end

function accountmgr.gettoken(token)
    return skynet.call(".main","lua","service","exec","gg.thistemp:get",token)
end

function accountmgr.addtoken(token,data,expire)
    expire = expire or 300
    skynet.call(".main","lua","service","exec","gg.thistemp:set",token,data,expire)
end

function accountmgr.deltoken(token)
    skynet.call(".main","lua","service","exec","gg.thistemp:del",token)
end


-- 角色换绑服务器
function accountmgr.rebindserver(account,appid,new_serverid,old_roleid,new_roleid)
    if not util.get_app(appid) then
        return httpc.answer.code.APPID_NOEXIST
    end
    if not accountmgr.getaccount(account) then
        return httpc.answer.code.ACCT_NOEXIST
    end
    if not servermgr.getserver(appid,new_serverid) then
        return httpc.answer.code.SERVER_NOEXIST
    end
    local old_role = accountmgr.getrole(appid,old_roleid)
    if not old_role then
        return httpc.answer.code.ROLE_NOEXIST
    end
    if old_roleid == new_roleid then
        if old_role.create_serverid == new_serverid then
            -- unchange
            return httpc.answer.code.OK
        end
    else
        local new_role = accountmgr.getrole(appid,new_roleid)
        if new_role then
            return httpc.answer.code.ROLE_EXIST
        end
    end
    logger.logf("info","account",string.format("op=rebindserver,account=%s,appid=%s,old_serverid=%s,new_serverid=%s,old_roleid=%s,new_roleid=%s",
        account,appid,old_role.create_serverid,new_serverid,old_roleid,new_roleid))
    if old_roleid == new_roleid then
        accountmgr.updaterole(appid,{roleid=new_roleid,create_serverid=new_serverid})
    else
        accountmgr.delrole(appid,old_roleid,true)
        old_role.roleid = new_roleid
        accountmgr.addrole(account,appid,new_serverid,old_role)
    end
    return httpc.answer.code.OK
end

-- 角色换绑帐号
function accountmgr.rebindaccount(new_account,appid,roleid)
    if not util.get_app(appid) then
        return httpc.answer.code.APPID_NOEXIST
    end
    local new_accountobj = accountmgr.getaccount(new_account)
    if not new_accountobj then
        return httpc.answer.code.ACCT_NOEXIST
    end
    local role = accountmgr.getrole(appid,roleid)
    if not role then
        return httpc.answer.code.ROLE_NOEXIST
    elseif role.account == new_account then
        -- nochange
        return httpc.answer.code.OK
    end
    local old_account = role.account
    logger.logf("info","account",string.format("op=rebindaccount,appid=%s,roleid=%s,old_account=%s,new_account=%s",appid,roleid,old_account,new_account))
    accountmgr.delrole(appid,roleid,true)
    role.account = new_account
    accountmgr.addrole(new_account,appid,role.create_serverid,role)
    return httpc.answer.code.OK
end

-- 恢复角色
function accountmgr.recover_role(appid,roleid)
    if not util.get_app(appid) then
        return httpc.answer.code.APPID_NOEXIST
    end
    local role = accountmgr.getrole(appid,roleid)
    if not role then
        return httpc.answer.code.ROLE_NOEXIST
    end
    local account = role.account
    local deleted_rolelist = accountmgr.get_deleted_roles(account,appid)
    local found_pos = table.find(deleted_rolelist,roleid)
    if not found_pos then
        return httpc.answer.code.ROLE_NOEXIST
    end
    logger.logf("info","account",string.format("op=recover_role,account=%s,appid=%s,roleid=%s",account,appid,roleid))
    local rolelist = accountmgr.getroles(account,roleid)
    table.remove(deleted_rolelist,found_pos)
    table.insert(rolelist,roleid)
    accountmgr.saveroles(account,appid,rolelist)
    accountmgr.save_deleted_roles(account,appid,deleted_rolelist)
    return httpc.answer.code.OK
end

return accountmgr
