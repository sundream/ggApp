---跨服流程
--@usage
--假定存在玩家C，当前在GS1服,要跳转到GS2服
--  1. GS1生成认证token,告知GS2
--  2. GS1通知C重定向到GS2(token也会告知客户端),并且将C踢下线,确保C的数据落地完毕
--  3. C断开GS1连接,重新连接GS2,并且用token到GS2认证登录
--  4. GS2收到C的登录请求,认证通过后允许C进入游戏
--  5. C在GS2走进入游戏流程(由于跨服前C的数据已落地完毕,因此跨服后能正确恢复数据)



---跨服
--@param[type=int|table] linkobj 玩家ID|连线对象
--@param[type=string] onlogin 经过gg.pack_function序列化过的函数

local cplayermgr = gg.class.cplayermgr

function cplayermgr:go_server(linkobj,go_serverid,onlogin)
    local from_serverid = gg.server.id
    if from_serverid == go_serverid then
        return
    end
    local go_server = gg.server.online_serverlist[go_serverid]
    if not go_server then
        return
    end
    local account
    local pid
    local player
    if type(linkobj) == "number" then
        player = self:getplayer(linkobj)
        if not player then
            return
        end
        if player.on_go_server then
            player:on_go_server(go_serverid)
        end
        account = player.account
        pid = player.pid
    else
        -- linkobj
        account = linkobj.account
        pid = linkobj.roleid
    end
    local ttl = 302
    local prefix = string.format("%s.%s.",from_serverid,skynet.hpc())
    local token = prefix .. string.randomkey(8)
    local token_data = {
        kuafu = true,
        onlogin = onlogin,
        from_serverid = from_serverid,
        account = account,
    }
    logger.logf("info","kuafu","op=go_server,pid=%d,from_serverid=%s,go_serverid=%s,token=%s",pid,from_serverid,go_serverid,token)
    gg.actor.cluster:call(go_serverid,"exec","self:tokens:set",token,token_data,ttl)
    gg.actor.client:sendpackage(linkobj,"GS2C_ReEnterGame",{
        token = token,
        roleid = pid,
        go_serverid = go_serverid,
        ip = go_server.ip,
        tcp_port = go_server.tcp_port,
        kcp_port = go_server.kcp_port,
        websocket_port = go_server.websocket_port,
    })
    local reason = string.format("go_server:%s",go_serverid)
    if type(linkobj) == "number" then
        self:kick(pid,reason)
    else
        gg.actor.client:dellinkobj(linkobj.linkid)
    end
end

-- 根据玩家ID获取<当前所在服,是否在线>
function cplayermgr:route(pid)
    -- 默认关闭夸服,便于测试
    if not skynet.getenv("open_kuafu") then
        return false
    end
    -- 应用层可以自己管理路由表,如用中心服集中管理并实时同步
    -- 这里暂时用账号中心记录的数据做演示
    local ok,online,now_serverid = pcall(self._route,self,pid)
    if not ok then
        return nil,false
    end
    return online,now_serverid
end

function cplayermgr:_route(pid)
    local status,response = gg.loginserver:getrole(pid)
    assert(status == 200)
    assert(response.code == httpc.answer.code.OK)
    local role = response.data.role
    if not role then
        return false,nil
    end
    return role.online,role.now_serverid
end

return cplayermgr