local profile = require "skynet.profile"
local cprofile = class("cprofile")

function cprofile:init(conf)
    conf = conf or {}
    self.cost = {}
    self.close = conf.close or false
    self.threshold = conf.threshold or 0.05
    self.log_overload = true
    if conf.log_overload then
        self.log_overload = conf.log_overload
    end
end

function cprofile:record(name,onerror,func,...)
    return self:stat(self.cost,name,onerror,func,...)
end

function cprofile:stat(record,name,onerror,func,...)
    if self.close then
        return xpcall(func,onerror,...)
    end
    profile.start()
    local result = table.pack(xpcall(func,onerror,...))
    local ok = result[1]
    local time = profile.stop()
    local cost = record[name]
    if not cost then
        cost = {
            cnt = 0,
            time = 0,
            failcnt = 0,
            overloadcnt = 0
        }
        record[name] = cost
    end
    cost.cnt = cost.cnt + 1
    cost.time = cost.time + time
    if not ok then
        cost.failcnt = cost.failcnt + 1
    else
        if self.threshold and time > self.threshold then
            cost.overloadcnt = cost.overloadcnt + 1
            if self.log_overload then
                logger.logf("info","profile","op=overload,name=%s,time=%ss",name,time)
            end
        end
    end
    return table.unpack(result)
end

return cprofile
