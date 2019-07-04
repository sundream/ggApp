local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local socket_proxy = require "socket_proxy"
local config = require "app.config.custom"
local HandShake = require "app.client.handshake"
local codec = require "app.codec.codec"

local tcp = {}
local mt = {__index = tcp}

function tcp.new(opts)
    local codecobj = codec.new(config.proto)
    local self = {
        linkid = nil,
        linktype = "tcp",
        session = 0,
        sessions = {},
        wait_proto = {},
        codec = codecobj,
        handler = opts.handler,
    }
    self.handShake = HandShake.new(self)
    if not config.handshake then
        self.handShake.result = "OK"
    end
    return setmetatable(self,mt)
end

function tcp:connect(host,port)
    local linkid,err = socket.open(host,port)
    assert(linkid,err)
    self.linkid = linkid
    socket_proxy.subscribe(linkid,0)
    if self.handler.onconnect then
        self.handler.onconnect(self)
    end
    if self.handShake.result then
        if self.handler.onhandshake then
            self.handler.onhandshake(self,self.handShake.result)
        end
    end
    skynet.timeout(0,function ()
        self:dispatch_message()
    end)
end

function tcp:dispatch_message()
    while true do
        local ok,msg,sz = pcall(socket_proxy.read,self.linkid)
        if not ok then
            if self.handler.onclose then
                self.handler.onclose(self)
            end
            break
        end
        msg = skynet.tostring(msg,sz)
        xpcall(self.recv_message,skynet.error,self,msg)
    end
end
function tcp:recv_message(msg)
    self:onmessage(msg)
end

function tcp:close()
    socket_proxy.close(self.linkid)
end

function tcp:quite()
    self.verbose = not self.verbose
end

function tcp:say(...)
    skynet.error(string.format("[linktype=%s,linkid=%s]",self.linktype,self.linkid),...)
end

function tcp:onmessage(msg)
    if not self.handShake.result then
        local ok,err = self.handShake:doHandShake(msg)
        if not ok then
            self:close()
        end
        self:say(string.format("op=handShaking,ok=%s,err=%s,step=%s",ok,err,self.handShake.step))
        if self.handShake.result then
           self:say(string.format("op=handShake,encryptKey=%s,result=%s",self.handShake.encryptKey,self.handShake.result))
           if self.handler.onhandshake then
               self.handler.onhandshake(self,self.handShake.result)
           end
        end
        return
    end
    msg = self.handShake:decrypt(msg)
    local message = self.codec:unpack_message(msg)
    if self.handler.onmessage then
        self.handler.onmessage(self,message)
    end
    local protoname = message.cmd
    local callback = self:wakeup(protoname)
    if callback then
        callback(self,message)
    end
end

function tcp:send_request(protoname,request,callback)
    local session
    if callback then
        self.session = self.session + 1
        session = self.session
        self.sessions[session] = callback
    end
    local message = {
        type = 1,
        cmd = protoname,
        args = request,
        session = session,
    }
    return self:send(message)
end

function tcp:send_response(protoname,response,session)
    local message = {
        type = 2,
        cmd = protoname,
        args = response,
        session = session,
    }
    return self:send(message)
end

function tcp:send(message)
    local bin = self.codec:pack_message(message)
    bin = self.handShake:encrypt(bin)
    self:rawSend(bin)
end

function tcp:rawSend(bin)
    local size = #bin
    assert(size <= 65535,"package too long")
    socket_proxy.write(self.linkid,bin)
end

function tcp:wait(protoname,callback)
    if not self.wait_proto[protoname] then
        self.wait_proto[protoname] = {}
    end
    table.insert(self.wait_proto[protoname],callback)
end

function tcp:wakeup(protoname)
    if not self.wait_proto[protoname] then
        return nil
    end
    return table.remove(self.wait_proto[protoname],1)
end

tcp.ignore_one = tcp.wakeup

return tcp
