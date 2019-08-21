local cinternal = class("cinternal")

function cinternal:init()
    self.cmd = {}

    -- 自身节点和服务地址
    self.node = skynet.getenv("id")
    self.address = skynet.self()

    -- 上一条请求来源的服务地址
    self.source_node = nil
    self.source_address = nil
    -- builtin router
    self:register("exec",function (method,...)
        return gg.exec(_G,method,...)
    end)
    self:register("eval",gg.eval)
end

function cinternal:register(cmd,handler)
    self.cmd[cmd] = handler
end

function cinternal:gethandler(cmd)
    return self.cmd[cmd]
end

function cinternal:dispatch(session,source,cmd,...)
    self.source_node = self.node
    self.source_address = source
    if logger.loglevel > logger.DEBUG then
        local handler = self:gethandler(cmd)
        assert(handler,cmd)
        if session ~= 0 then
            skynet.retpack(handler(...))
        else
            handler(...)
        end
    else
        local request = {...}
        logger.logf("debug","internal","op=recv,session=%s,source=%s,my_node=%s,my_address=%s,cmd=%s,request=%s",
            session,source,self.node,self.address,cmd,request)
        local handler = self:gethandler(cmd)
        assert(handler,cmd)
        local response = {handler(...)}
        if session ~= 0 then
            logger.logf("debug","internal","op=resp,session=%s,source=%s,my_node=%s,my_address=%s,cmd=%s,request=%s,response=%s",
                session,source,self.node,self.address,cmd,request,response)
            skynet.retpack(table.unpack(response))
        end
    end
    self.source_node = nil
    self.source_address = nil
end

--- internal:call方式调用,如果调用失败则报错
--@param[type=string|int] address 对方actor地址
--@param[type=string] cmd 指令名
--@param ... 指令参数
--@return 执行指令返回的结果
function cinternal:call(address,cmd,...)
    if logger.loglevel > logger.DEBUG then
        return skynet.call(address,"lua","internal",cmd,...)
    else
        local request = {...}
        logger.logf("debug","internal","op=call,address=%s,my_node=%s,my_address=%s,cmd=%s,request=%s",
            address,self.node,self.address,cmd,request)
        local response = {skynet.call(address,"lua","internal",cmd,...)}
        logger.logf("debug","internal","op=return,address=%s,my_node=%s,my_address=%s,cmd=%s,request=%s,response=%s",
            address,self.node,self.address,cmd,request,response)
        return table.unpack(response)
    end
end

--- internal:send方式调用,,不等待,不关心对方返回结果
--@param[type=string|int] address 对方actor地址
--@param[type=string] cmd 指令名
--@param ... 指令参数
function cinternal:send(address,cmd,...)
    if logger.loglevel > logger.DEBUG then
        return skynet.send(address,"lua","internal",cmd,...)
    else
        local request = {...}
        logger.logf("debug","internal","op=send,address=%s,my_node=%s,my_address=%s,cmd=%s,request=%s",
            address,self.node,self.address,cmd,request)
        return skynet.send(address,"lua","internal",cmd,...)
    end
end

function cinternal:pcall(address,cmd,...)
    return pcall(self.call,self,address,cmd,...)
end

function cinternal:xpcall(address,cmd,...)
    return xpcall(self.call,gg.onerror,self,address,cmd,...)
end

return cinternal
