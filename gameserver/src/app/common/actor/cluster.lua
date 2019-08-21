local ccluster = class("ccluster")

function ccluster:init()
    self.cmd = {}
    -- 自身节点和服务地址
    self.node = skynet.getenv("id")
    self.address = skynet.self()
    -- 上一条请求来源的节点和服务地址
    self.source_node = nil
    self.source_address = nil

    -- builtin router
    self:register("exec",function (method,...)
        return gg.exec(_G,method,...)
    end)
    self:register("eval",gg.eval)
    self:register("playerexec",function (pid,method,...)
        local player = gg.playermgr:getplayer(pid)
        if player then
            return gg.exec(player,method,...)
        end
    end)
end

function ccluster:open()
    self:reload()
    -- 开启集群
    local serverid = skynet.getenv("id")
    local cluster_port
    if skynet.getenv("area") == "dev" then
        cluster_port = tonumber(skynet.getenv("cluster_port")) or serverid
    else
        cluster_port = serverid
    end
    cluster.open(cluster_port)
end

function ccluster:reload()
    -- 优先使用nodes中提供的集群配置
    local nodes = skynet.getenv("nodes") or {}
    local node_address = {}
    for node_name,conf in pairs(nodes) do
        node_address[node_name] = conf.address
    end
    if next(node_address) then
        cluster.reload(node_address)
    else
        cluster.reload()
    end
end

function ccluster:register(cmd,handler)
    self.cmd[cmd] = handler
end

function ccluster:gethandler(cmd)
    return self.cmd[cmd]
end

function ccluster:dispatch(session,source,source_node,source_address,cmd,...)
    self.source_node = source_node
    self.source_address = source_address
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
        logger.logf("debug","cluster","op=recv,session=%s,source=%s,my_node=%s,my_address,source_node=%s,source_address=%s,cmd=%s,request=%s",
            session,source,self.node,self.address,source_node,source_address,cmd,request)
        local handler = self:gethandler(cmd)
        assert(handler,cmd)
        local response = {handler(...)}
        if session ~= 0 then
            logger.logf("debug","cluster","op=resp,session=%s,my_node=%s,my_address=%s,source=%s,source_node=%s,source_address=%s,cmd=%s,request=%s,response=%s",
                session,source,self.node,self.address,source_node,source_address,cmd,request,response)
            skynet.retpack(table.unpack(response))
        end
    end
    self.source_node = nil
    self.source_address = nil
end

--- cluster:call方式调用,如果调用失败则报错
--@param[type=string] node 节点名
--@param[type=string|int] address 对方actor地址
--@param[type=string] cmd 指令名
--@param ... 指令参数
--@return 执行指令返回的结果
function ccluster:call(node,address,cmd,...)
    if logger.loglevel > logger.DEBUG then
        return cluster.call(node,address,"cluster",self.node,self.address,cmd,...)
    else
        local request = {...}
        logger.logf("debug","cluster","op=call,node=%s,address=%s,my_node=%s,my_address=%s,cmd=%s,request=%s",
            node,address,self.node,self.address,cmd,request)
        local response = {cluster.call(node,address,"cluster",self.node,self.address,cmd,...)}
        logger.logf("debug","cluster","op=return,node=%s,address=%s,my_node=%s,my_address=%s,cmd=%s,request=%s,response=%s",
            node,address,self.node,self.address,cmd,request,response)
        return table.unpack(response)
    end
end

--- cluster:send方式调用,不等待,不关心对方返回结果
--@param[type=string] node 节点名
--@param[type=string|int] address 对方actor地址
--@param[type=string] cmd 指令名
--@param ... 指令参数
function ccluster:send(node,address,cmd,...)
     if logger.loglevel > logger.DEBUG then
        return cluster.send(node,address,"cluster",self.node,self.address,cmd,...)
    else
        local request = {...}
        logger.logf("debug","cluster","op=send,node=%s,address=%s,my_node=%s,my_address=%s,cmd=%s,request=%s",
            node,address,self.node,self.address,cmd,request)
        return cluster.send(node,address,"cluster",self.node,self.address,cmd,...)
    end
end

function ccluster:pcall(node,address,cmd,...)
    return pcall(self.call,self,node,address,cmd,...)
end

function ccluster:xpcall(node,address,cmd,...)
    return xpcall(self.call,gg.onerror,self,node,address,cmd,...)
end

return ccluster
