---角色换绑服务器
--@param[type=int] roleid 角色ID
--@param[type=string] new_serverid 新服务器ID
--@return[type=bool] 是否成功
--@return[type=string] 如果失败,返回错误消息
--@usage
--流程:
--假定角色R1在GS1服创建,目前要换服到GS2,登录服为LS
--如果没有使用DB集群:
--1. C->GS1:    通知GS1换绑服务器
--2. GS1->GS2:  将序列化角色R1的数据发到GS2,并要求GS2创建新角色,角色数据来自R1
--3. GS2->LS:   创建角色,假定为R2
--4. GS2:       用创建的角色克隆R1的数据,并立即存盘
--5. GS2->GS1:  GS2通知GS1创建角色结果,如果成功,同时传递<R1,R2>
--6. GS1:       删除本服角色
--7. GS1->LS:   通知登录服删除R1角色
--8. GS1->C:    通知客户端角色换绑结果
--如果使用DB集群:
--将其中2~7步改成: GS1->LS: 通知登录服角色换绑服务器
local cplayermgr = gg.class.cplayermgr

function cplayermgr:rebindserver(roleid,new_serverid)
    local player = self:loadplayer(roleid)
    if not player then
        return false,"角色不存在"
    end
    local new_roleid
    local account = player.account
    self:unloadplayer(roleid)
    local db_is_cluster = skynet.getenv("db_is_cluster")
    if not db_is_cluster then
        local role_data = player:serialize()
        local ok
        ok,new_roleid = gg.actor.cluster:call(new_serverid,".game","exec","gg.playermgr:clone",role_data,account)
        if not ok then
            local err = new_roleid
            return false,err
        end
        self:delrole(roleid,true)
    else
        new_roleid = roleid
        local status,response = gg.loginserver:rebindserver(account,new_serverid,roleid,new_roleid)
        if status ~= 200 then
            return false,"error status: " .. tostring(status)
        end
        if response.code ~= httpc.answer.code.OK then
            return false,response.message
        end
    end
    -- 玩家在线则让其切到新服
    if player.linkobj then
        player.pid = new_roleid
        self:go_server(player,new_serverid)
    end
    if self.on_rebindserver then
        self:on_rebindserver(new_serverid,roleid,new_roleid)
    end
    return true,new_roleid
end

---角色换绑账号
--@param[type=int] roleid 角色ID
--@param[type=string] new_account 新的账号
--@return[type=bool] 是否成功
--@return[type=string] 如果失败,返回错误消息
function cplayermgr:rebindaccount(roleid,new_account)
    local player = self:loadplayer(roleid)
    if not player then
        return false,"角色不存在"
    end
    local call_ok,ok,err = pcall(function ()
        local status,response gg.loginserver:rebindaccount(roleid,new_account)
        if status ~= 200 then
            return false,"error status: " .. tostring(status)
        end
        if response.code ~= httpc.answer.code.OK then
            return false,response.message
        end
        return true
    end)
    if not call_ok then
        err = ok
        ok = call_ok
    end
    if ok then
        player.account = new_account
    end
    self:unloadplayer(roleid)
    return ok,err
end

---删除角色
--@param[type=int] roleid 角色ID
--@param[type=bool,opt] forever 是否永久删除
--@return[type=bool] 是否成功
--@return[type=string] 如果失败,返回错误消息
function cplayermgr:delrole(roleid,forever)
    local status,response = gg.loginserver:delrole(roleid,forever)
    if status ~= 200 then
        return false,"error status: " .. tostring(status)
    end
    if response.code ~= httpc.answer.code.OK then
        return false,response.message
    end
    if self.on_delrole then
        self:on_delrole(roleid)
    end
    if forever then
        gg.class.cplayer.deletefromdatabase(roleid)
    end
    return true
end

---恢复角色
--@param[type=int] roleid 角色ID
--@return[type=bool] 是否成功
--@return[type=string] 如果失败,返回错误消息
function cplayermgr:recover_role(roleid)
    local status,response = gg.loginserver:recover_role(roleid)
    if status ~= 200 then
        return false,"error status: " .. tostring(status)
    end
    if response.code ~= httpc.answer.code.OK then
        return false,response.message
    end
    return true
end

---克隆角色
--@param[type=int] roleid 角色ID
--@return[type=bool] 是否成功
--@return[type=string] 如果失败,返回错误消息
function cplayermgr:clone(role_data,account)
	role_data = gg.deepcopy(role_data)
    local serverid = skynet.getenv("id")
    local appid = skynet.getenv("appid")
    local attr = role_data.attr
    local name = attr.name
    local shapeid = attr.shapeid
    local sex = attr.sex
    local role = {
        account = account,
        name = name,
        shapeid = shapeid,
        sex = sex,
    }
    local status,response = gg.loginserver:addrole(account,serverid,role,nil,appid,1000000,1000000000)
    if status ~= 200 then
        return false,"error status: " .. tostring(status)
    end
    if response.code ~= httpc.answer.code.OK then
        return false,response.message
    end
    local r = response.data.role
    role.roleid = r.roleid
    role.createtime = r.createtime or os.time()
    local player = self:createplayer(role.roleid,role)
    player:unserialize(role_data)
    player:savetodatabase()
    return true,role.roleid
end

return cplayermgr

