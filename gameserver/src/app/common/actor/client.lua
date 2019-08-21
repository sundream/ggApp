-- 扩展cclient
local cclient = gg.class.cclient

function cclient:register(cmd,handler)
    if not self.cmd then
        self.cmd = {}
    end
    self.cmd[cmd] = handler
end

function cclient:register_unsafe(cmd,handler)
    if not self.unsafe_cmd then
        self.unsafe_cmd = {}
    end
    self.unsafe_cmd[cmd] = handler
end

function cclient:register_http(cmd,handler)
    if not self.http_cmd then
        self.http_cmd = {}
    end
    self.http_cmd[cmd] = handler
end

--- 收到客户端http请求
--@param[type=int] linkobj http会话连接对象
--@param[type=string] uri 请求uri
--@param[type=table] header 请求头
--@param[type=string] query 请求参数(根据格式可能需要用urllib.parse_query解析成table)
--@param[type=string] body 请求体(根据格式可能需要用cjson.decode解析)
function cclient:http_onmessage(linkobj,uri,header,query,body)
    logger.logf("debug","http","op=recv,linkid=%s,ip=%s,port=%s,method=%s,uri=%s,header=%s,query=%s,body=%s",
        linkobj.linkid,linkobj.ip,linkobj.port,linkobj.method,uri,header,query,body)

    local handler = self.http_cmd and self.http_cmd[uri]
    if handler then
        local func = handler[linkobj.method]
        if func then
            func(linkobj,header,query,body)
        else
            -- method not implemented
            httpc.response(linkobj.linkid,501)
        end
    else
        -- not found
        httpc.response(linkobj.linkid,404)
    end
    skynet.ret(nil)
end

--- 收到客户端连接
--@param[type=string] linktype 连接类型,如tcp/kcp/websocket
--@param[type=int] linkid 连接ID
--@param[type=string] addr 连接地址
function cclient:onconnect(linktype,linkid,addr)
    local linkobj = gg.class.clinkobj.new(linktype,linkid,addr)
    self:addlinkobj(linkobj)
end

--- 客户端握手完毕
--@param[type=string] linktype 连接类型,如tcp/kcp/websocket
--@param[type=int] linkid 连接ID
--@param[type=string] addr 连接地址
--@param[type=string] result 握手结果,OK--成功,FAIL--失败
function cclient:onhandshake(linktype,linkid,addr,result)
    if result ~= "OK" then
        return
    end
end

--- 客户端连接断开,被动掉线
--@param[type=int] linkid 连线ID
function cclient:onclose(linkid)
    local linkobj = self:getlinkobj(linkid)
    if not linkobj then
        return
    end
    local pid = linkobj.pid
    local player = gg.playermgr:getplayer(pid)
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
        player = assert(gg.playermgr:getonlineplayer(linkobj.pid))
    else
        if not self.unsafe_cmd or not self.unsafe_cmd[cmd] then
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
        local handler = self.cmd and self.cmd[cmd]
        if handler then
            handler(player,message)
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
    elseif cmd == "onhandshake" then
        self:onhandshake(...)
    elseif cmd == "onclose" then
        self:onclose(...)
    elseif cmd == "onmessage" then
        self:onmessage(...)
    elseif cmd == "http_onmessage" then
        self:http_onmessage(...)
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
        local player = gg.playermgr:getplayer(linkobj)
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
end

cclient.sendpackage = cclient.send_request

--- 给客户端发送“回复”消息
--@param[type=table|int] linkobj 连线对象|玩家ID
--@param[type=string] proto 协议名
--@param[type=table] response 回复参数
--@param[type=int] session 回话ID(即对方请求时传来的唯一ID)
function cclient:send_response(linkobj,proto,response,session)
    if type(linkobj) == "number" then
        local player = gg.playermgr:getplayer(linkobj)
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
end

return cclient