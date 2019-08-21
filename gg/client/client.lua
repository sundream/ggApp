local cclient = class("cclient")

--- cclient.new调用后执行的构造函数
--@param[type=table] conf
--@return a cclient's instance
--@usage
--local gg.client = gg.class.cclient.new({
--  tcp_gate = xxx,
--  kcp_gate = xxx,
--  websocket_gate = xxx,
--})
function cclient:init(conf)
    conf = conf or {}
    self.tcp_gate = conf.tcp_gate
    self.kcp_gate = conf.kcp_gate
    self.websocket_gate = conf.websocket_gate
    self.session = 0
    self.sessions = {}
    -- 连线对象
    self.linkobjs = gg.class.ccontainer.new()
end

function cclient:gen_session()
    -- TODO: 生成64位ID?
    repeat
        self.session = self.session + 1
    until not self.sessions[self.session]
    return self.session
end

function cclient:send(linkid,cmd,args,callback)
    local linkobj = self:getlinkobj(linkid)
    if not linkobj then
        return
    end
    local is_response = type(callback) == "number"
    local message
    if not is_response then
        local session
        if callback then
            session = self:gen_session()
            self.sessions[session] = callback
        end
        message = {
            type = 1,
            cmd = cmd,
            args = args,
            session = session,
            ud = self.pack_ud and self:pack_ud(),
        }
    else
        local session = callback
        message = {
            type = 2,
            cmd = cmd,
            args = args,
            session = session,
            ud = self.pack_ud and self:pack_ud(),
        }
    end
    local linktype = linkobj.linktype
    if linktype == "tcp" then
        skynet.send(self.tcp_gate,"lua","write",linkid,message)
    elseif linktype == "kcp" then
        skynet.send(self.kcp_gate,"lua","write",linkid,message)
    elseif linktype == "websocket" then
        skynet.send(self.websocket_gate,"lua","write",linkid,message)
    end
    return message
end


--- 获得连接对象
--@param[type=int] linkid 连接ID
function cclient:getlinkobj(linkid)
    return self.linkobjs:get(linkid)
end

--- 增加连接对象
--@param[type=table] linkobj 连接对象
function cclient:addlinkobj(linkobj)
    local linkid = assert(linkobj.linkid)
    return self.linkobjs:add(linkobj,linkid)
end

--- 删除连接对象,删除后会触发连接关闭
--@param[type=int] linkid 连接ID
function cclient:dellinkobj(linkid)
    local linkobj = self.linkobjs:del(linkid)
    if linkobj then
        if linkobj.linktype == "tcp" then
            skynet.send(self.tcp_gate,"lua","close",linkid)
        elseif linkobj.linktype == "websocket" then
            skynet.send(self.websocket_gate,"lua","close",linkid)
        else
            assert(linkobj.linktype == "kcp")
            skynet.send(self.kcp_gate,"lua","close",linkid)
        end
        if linkobj.slave then
            self:dellinkobj(linkobj.slave.linkid)
        elseif linkobj.master then
            self:unbind_slave(linkobj.master)
        end
    end
    return linkobj
end

--- 使一个连接成为另一个连接的辅助连接
--@param[type=int] master_linkid 主连接ID
--@param[type=int] slave_linkid 辅助连接ID
function cclient:slaveof(master_linkid,slave_linkid)
    local master_linkobj = self:getlinkobj(master_linkid)
    local slave_linkobj = self:getlinkobj(slave_linkid)
    if not (master_linkobj and slave_linkobj) then
        return
    end
    assert(master_linkobj.slave == nil)
    assert(slave_linkobj.master == nil)
    master_linkobj.slave = slave_linkobj
    slave_linkobj.master = master_linkobj
end

--- 解除主连接身上的辅助连接
--@param[type=table] master_linkobj 主连接对象
function cclient:unbind_slave(master_linkobj)
    local slave_linkobj = master_linkobj.slave
    if not slave_linkobj then
        return
    end
    assert(slave_linkobj.master == master_linkobj)
    master_linkobj.slave = nil
    slave_linkobj.master = nil
end

--- 热更协议
function cclient:reload()
    if self.tcp_gate then
        skynet.send(self.tcp_gate,"lua","reload")
    end
    if self.websocket_gate then
        skynet.send(self.websocket_gate,"lua","reload")
    end
    if self.kcp_gate then
        skynet.send(self.kcp_gate,"lua","reload")
    end
end

--- 让gate转发协议到指定服务
--@param[type=int] linkid 连接ID
--@param[type=string] proto 协议名
--@param[type=int|string] address 服务地址
function cclient:forward(linkid,proto,address)
    if self.tcp_gate then
        skynet.send(self.tcp_gate,"lua","forward",linkid,proto,address)
    end
    if self.websocket_gate then
        skynet.send(self.websocket_gate,"lua","forward",linkid,proto,address)
    end
    if self.kcp_gate then
        skynet.send(self.kcp_gate,"lua","forward",linkid,proto,address)
    end
end

return cclient
