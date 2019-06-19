gm = gm or {}

local queue = require "skynet.queue"
gm._lock = gm._lock or queue()
function gm.docmd(cmdline)
    local split = string.split(cmdline,"%s")
    local retlist = table.pack(gm._lock(gm._docmd,split))
    logger.logf("info","gm","op=docmd,cmdline='%s',return=%s",cmdline,table.dump(retlist))
    return table.unpack(retlist)
end

function gm.getfunc(cmds,cmd)
    if cmd == "_lock" or cmd == "getfunc" then
        return nil
    end
    local func = table.getattr(cmds,cmd)
    if func then
        return func
    end
    cmd = string.lower(cmd)
    local func = table.getattr(cmds,cmd)
    if func then
        return func
    end
    for k,v in pairs(cmds) do
        if string.lower(k) == cmd then
            return v
        end
    end
end

function gm._docmd(cmds)
    local cmdline = table.concat(cmds," ")
    local pid = table.remove(cmds,1)
    local cmd = table.remove(cmds,1)
    pid = tonumber(pid)
    if not pid then
        return gm.say("no pid: " .. cmdline)
    end
    if not cmd then
        return gm.say("no cmd: " .. cmdline,pid)
    end
    local func = gm.getfunc(gm,cmd)
    if not func then
        return gm.say(string.format("not found cmd: %q",cmd),pid)
    end
    if pid ~= 0 then
        gm.master = nil
        if not gm.master then
            return pid .. " not online"
        end
    end
    local ret = table.pack(xpcall(func,debug.traceback,cmds))
    gm.master = nil
    return table.unpack(ret,1,ret.n)
end

function gm.say(msg,pid)
    if gm.master then
        pid = pid or gm.master.pid
    end
    if pid and pid ~= 0 then
        -- todo: say with client
        print(msg)
    end
    return msg
end

return gm
