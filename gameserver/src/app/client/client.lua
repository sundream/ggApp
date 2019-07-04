-- 扩展cclient
local cclient = gg.class.cclient

--- 收到客户端连接
--@param[type=string] linktype 连接类型,如tcp/kcp/websocket
--@param[type=int] linkid 连接ID
--@param[type=string] addr 连接地址
function cclient:onconnect(linktype,linkid,addr)
    local linkobj = gg.class.clinkobj.new(linktype,linkid,addr)
    self:addlinkobj(linkobj)
end

--- 客户端连接断开,被动掉线
--@param[type=int] linkid 连线ID
function cclient:onclose(linkid)
    local linkobj = self:getlinkobj(linkid)
    if not linkobj then
        return
    end
    local pid = linkobj.pid
    local player = playermgr.getplayer(pid)
    if player then
        player:disconnect("onclose")
    else
        self:dellinkobj(linkid)
    end
end

--- 收到客户端消息
--@param[type=int] linkid 连线ID
--@param[type=table] message 消息
function cclient:onmessage(linkid,message)
    local linkobj = self:getlinkobj(linkid)
    if not linkobj then
        return
    end
    logger.logf("debug","client","op=recv,linkid=%s,linktype=%s,ip=%s,port=%s,pid=%s,message=%s",
        linkid,linkobj.linktype,linkobj.ip,linkobj.port,linkobj.pid,message)
    local cmd = message.cmd
    local player
    if linkobj.pid then
        player = assert(playermgr.getonlineplayer(linkobj.pid))
    else
        if not net.unauth_cmds[cmd] then
            if not gg.server:isstable() then
                logger.logf("warn","client","op=recv,linkid=%s,linktype=%s,ip=%s,port=%s,message=%s,result=ignore",
                    linkid,linkobj.linktype,linkobj.ip,linkobj.port,message)
                return
            end
            return
        end
        player = linkobj
    end
    if message.type == 1 then
        -- request
        local func = net:cmd(cmd)
        if func then
            func(player,message)
        end
    else
        local session = assert(message.header.session)
        local callback = self.sessions[session]
        if callback then
            callback(player,message)
        end
    end
end

--- 调度网关收到的客户端消息,如连接、关闭、收到数据等
function cclient:dispatch(session,source,cmd,...)
    if cmd == "onconnect" then
        self:onconnect(...)
    elseif cmd == "onclose" then
        self:onclose(...)
    elseif cmd == "onmessage" then
        self:onmessage(...)
    elseif cmd == "slaveof" then
        self:slaveof(...)
    end
end

--- 给客户端发送“请求”消息
--@param[type=table|int] linkobj 连线对象|玩家ID
--@param[type=string] proto 协议名
--@param[type=table] request 回复参数
--@param[type=function,opt] callback 收到对方回复时的回调函数
function cclient:send_request(linkobj,proto,request,callback)
    if type(linkobj) == "number" then
        local player = playermgr.getplayer(linkobj)
        if not player then
            return
        end
        linkobj = player.linkobj
    end
    if not linkobj then
        return
    end
    local message = self:send(linkobj.linkid,proto,request,callback)
    if message then
        logger.logf("debug","client","op=send,linkid=%s,linktype=%s,ip=%s,port=%s,pid=%s,message=%s",
        linkobj.linkid,linkobj.linktype,linkobj.ip,linkobj.port,linkobj.pid,message)
    end
    return message
end

cclient.sendpackage = cclient.send_request

--- 给客户端发送“回复”消息
--@param[type=table|int] linkobj 连线对象|玩家ID
--@param[type=string] proto 协议名
--@param[type=table] response 回复参数
--@param[type=int] session 回话ID(即对方请求时传来的唯一ID)
function cclient:send_response(linkobj,proto,response,session)
    if type(linkobj) == "number" then
        local player = playermgr.getplayer(linkobj)
        linkobj = player.linkobj
    end
    if not linkobj then
        return
    end
    local message = self:send(linkobj.linkid,proto,response,session)
    if message then
        logger.logf("debug","client","op=send,linkid=%s,linktype=%s,ip=%s,port=%s,pid=%s,message=%s",
        linkobj.linkid,linkobj.linktype,linkobj.ip,linkobj.port,linkobj.pid,message)
    end
    return message
end

return cclient
