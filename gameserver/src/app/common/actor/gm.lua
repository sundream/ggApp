local queue = require "skynet.queue"

local cgm = class("cgm")

function cgm:init()
    self.cmd = {}
    self.master = nil
    self.lock = queue()
end

function cgm:register(cmd,handler)
    self.cmd[cmd] = handler
end

function cgm:gethandler(cmd)
    return self.cmd[cmd]
end

function cgm:dispatch(session,source,cmdline)
    if session ~= 0 then
        skynet.retpack(self:docmd(cmdline))
    else
        self:docmd(cmdline)
    end
end

function cgm:docmd(cmdline)
   local retlist = table.pack(self.lock(self._docmd,self,cmdline))
    logger.logf("info","gm","op=docmd,cmdline='%s',return=%s",cmdline,table.dump(retlist))
    return table.unpack(retlist)
end

function cgm:_docmd(cmdline)
    local split = string.split(cmdline,"%s")
    local pid = table.remove(split,1)
    local cmd = table.remove(split,1)
    local args = split
    pid = tonumber(pid)
    if not pid then
        return self:say("no pid: " .. cmdline)
    end
    if not cmd then
        return self:say("no cmd: " .. cmdline,pid)
    end
    local handler
    for k,v in pairs(self.cmd) do
        if k:lower() == cmd:lower() then
            handler = v
        end
    end
    if not handler then
        return self:say(string.format("not found cmd: %q",cmd),pid)
    end
    if pid ~= 0 then
        self.master = gg.playermgr:getplayer(pid)
        if not self.master then
            return pid .. "not online"
        end
    end
   local ret = table.pack(xpcall(handler,debug.traceback,self,args))
    if ret[1] then
        self:say("执行未报错")
    else
        self:say("执行报错")
    end
    self.master = nil
    return table.unpack(ret,1,ret.n)
end

function cgm:say(msg,pid)
    if self.master then
        pid = pid or self.master.pid
    end
    if pid and pid ~= 0 then
        -- todo: say to client
    end
    return msg
end

return cgm