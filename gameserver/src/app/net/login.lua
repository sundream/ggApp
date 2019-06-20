local netlogin = {
    C2GS = {},
    GS2C = {},
}

netlogin.version = require "app.version"

local C2GS = netlogin.C2GS
local GS2C = netlogin.GS2C

function C2GS.Ping(linkobj,message)
    local lutil = require "lutil"
    local args = message.args
    gg.client:sendpackage(linkobj,"GS2C_Pong",{
        str = args and args.str,
        time = lutil.getms(),
    })
end

function netlogin.is_safe_ip(ip)
    return ip == "127.0.0.1"
end

function netlogin.is_low_version(version)
    local list1 = string.split(netlogin.version,".")
    local list2 = string.split(version,".")
    local len = #list1
    for i=1,len do
        local ver1 = tonumber(list1[i])
        local ver2 = tonumber(list2[i])
        if not ver2 then
            return true
        end
        if ver2 < ver1 then
            return true
        elseif ver2 > ver1 then
            return false
        end
    end
    return false
end

-- CreateRole/EnterGame前token认证,检查是否通过登录认证
function C2GS.CheckToken(linkobj,message)
    local args = message.args
    local token = assert(args.token)
    local account = assert(args.account)
    local version = assert(args.version)
    local forward = args.forward     -- 透传参数
    local ip = linkobj.ip
    if netlogin.is_low_version(version) then
        local response = httpc.answer.response(httpc.answer.code.LOW_VERSION)
        response.status = 200
        response.forward = forward
        gg.client:sendpackage(linkobj,"GS2C_CheckTokenResult",response)
        return
    end
    if forward == "CreateRole" then
        if gg.is_close_createrole(account,ip) then
            local response = httpc.answer.response(httpc.answer.code.CLOSE_CREATEROLE)
            response.status = 200
            response.forward = forward
            gg.client:sendpackage(linkobj,"GS2C_CheckTokenResult",response)
            return
        end
    else
        -- EnterGame
        if gg.is_close_entergame(account,ip) then
            local response = httpc.answer.response(httpc.answer.code.CLOSE_ENTERGAME)
            response.status = 200
            response.forward = forward
            gg.client:sendpackage(linkobj,"GS2C_CheckTokenResult",response)
            return
        end
    end
    local debuglogin = false
    local token_data = playermgr.tokens:get(token)
    if token == "debug" and netlogin.is_safe_ip(linkobj.ip) then
        debuglogin = true
    elseif token_data ~= nil then
        if token_data.account and token_data.account ~= account then
            local response = httpc.answer.response(httpc.answer.code.TOKEN_UNAUTH)
            response.status = 200
            response.forward = forward
            gg.client:sendpackage(linkobj,"GS2C_CheckTokenResult",response)
            return
        end
        if token_data.kuafu then
            -- 跨服透传的数据只生效一次
            token_data.kuafu = nil
            linkobj.kuafu_forward = token_data
        end
    else
        local status,response = gg.loginserver:checktoken(account,token)
        if status ~= 200 then
            gg.client:sendpackage(linkobj,"GS2C_CheckTokenResult",{status = status,forward=forward})
            return
        end
        if response.code ~= httpc.answer.code.OK then
            gg.client:sendpackage(linkobj,"GS2C_CheckTokenResult",{
                status = status,
                code = response.code,
                message = response.message,
                forward = forward,
            })
            return
        end
        playermgr.tokens:set(token,{account=account},302)
    end
    linkobj.passlogin = true
    linkobj.version = version
    linkobj.token = token
    linkobj.debuglogin = debuglogin
    local status,code = 200,0
    gg.client:sendpackage(linkobj,"GS2C_CheckTokenResult",{
        status = status,
        code = code,
        message = httpc.answer.message[code],
        forward = forward;
    })
end

function C2GS.CreateRole(linkobj,message)
    local args = message.args
    local account = assert(args.account)
    local name = assert(args.name)
    local shapeid = args.shapeid
    local sex = args.sex or 1
    if not linkobj.passlogin then
        local response = httpc.answer.response(httpc.answer.code.PLEASE_LOGIN_FIRST)
        response.status = 200;
        gg.client:sendpackage(linkobj,"GS2C_CreateRoleResult",response)
        return
    end
    local errcode = gg.server:checkname(name)
    if errcode ~= httpc.answer.code.OK then
        local response = httpc.answer.response(errcode)
        response.status = 200
        gg.client:sendpackage(linkobj,"GS2C_CreateRoleResult",response)
        return
    end
    local role = {
        account = account,
        name = name,
        shapeid = shapeid,
        sex = sex,
    }
    if linkobj.debuglogin and args.roleid then
        -- 方便内部测试
        role.roleid = args.roleid
        role.createtime = os.time()
    else
        local appid = skynet.getenv("appid")
        local serverid = skynet.getenv("id")
        local status,response = gg.loginserver:addrole(account,serverid,role,nil,appid,1000000,1000000000)
        if status ~= 200 then
            gg.client:sendpackage(linkobj,"GS2C_CreateRoleResult",{status = status,})
            return
        end
        if response.code ~= httpc.answer.code.OK then
            gg.client:sendpackage(linkobj,"GS2C_CreateRoleResult",{
                status = status,
                code = response.code,
                message = response.message,
            })
            return
        end
        local roledata = assert(response.data.role)
        role.roleid = assert(tonumber(roledata.roleid))
        role.createtime = roledata.createtime or os.time()
    end
    playermgr.createplayer(role.roleid,role)
    local status = 200
    local code = httpc.answer.code.OK
    gg.client:sendpackage(linkobj,"GS2C_CreateRoleResult",{
        status = status,
        code = code,
        message = httpc.answer.message[code],
        role = role,
    })
end

function netlogin._entergame(linkobj,message)
    local args = message.args
    local pid = assert(args.roleid)
    -- TODO: check ban entergame
    if linkobj.pid then
        local response = httpc.answer.response(httpc.answer.code.REPEAT_ENTERGAME)
        response.status = 200
        gg.client:sendpackage(linkobj,"GS2C_EnterGameResult",response)
        return
    end
    if not linkobj.passlogin then
        local response = httpc.answer.response(httpc.answer.code.PLEASE_LOGIN_FIRST)
        response.status = 200
        gg.client:sendpackage(linkobj,"GS2C_EnterGameResult",response)
        return
    end
    local replace
    local player = playermgr.getplayer(pid)
    if player then
        replace = true
        if not player:isdisconnect() then
            -- TODO: give tip to been replace's linkobj?
            -- will unbind and del linkobj
            player:disconnect("replace")
        end
    else
        -- 跨服顶号
        local online,now_serverid = playermgr.route(pid)
        if online then
            if now_serverid ~= gg.server.id then
                -- 强制关服可能导致online状态不对
                linkobj.roleid = pid
                playermgr.go_server(linkobj,now_serverid)
                return
            end
        end
        replace = false
        player = playermgr.recoverplayer(pid)
        if not player then
            local response = httpc.answer.response(httpc.answer.code.ROLE_NOEXIST)
            response.status = 200
            gg.client:sendpackage(linkobj,"GS2C_EnterGameResult",response)
            return
        end
    end
    if gg.is_ban_entergame(player) then
        local response = httpc.answer.response(httpc.answer.code.BAN_ROLE)
        gg.client:sendpackage(linkobj,"GS2C_EnterGameResult",response)
        return
    end
    playermgr.bind_linkobj(player,linkobj)
    if not replace then
        -- playermgr.loadplayer和entergame并发时,player可能已经被添加
        if playermgr.getplayer(pid) then
            playermgr.delplayer(pid)
        end
        playermgr.addplayer(player)
    end
    gg.client:sendpackage(linkobj,"GS2C_EnterGameStart")
    player:entergame(replace)
    linkobj.passlogin = nil
    local response = httpc.answer.response(httpc.answer.code.OK)
    response.status = 200
    response.account = player.account
    response.linkid = linkobj.linkid
    gg.client:sendpackage(linkobj,"GS2C_EnterGameResult",response)
end

function C2GS.EnterGame(linkobj,message)
    local args = message.args
    local roleid = assert(args.roleid)
    local id = string.format("EnterGame.%s",roleid)
    local ok,errmsg = gg.sync:once_do(id,netlogin._entergame,linkobj,message)
    assert(ok,errmsg)
end

function C2GS.ExitGame(player,message)
    if player.disconnect then
        player:disconnect("normal")
    end
end

function __hotfix(module)
    gg.hotfix("app.net.net")
end

return netlogin
