-- 应答模式

local creqresp = class("creqresp")


function creqresp:init()
    self.sessions = {}
    self.id = 0

    self:starttimer_checkallsession()
end

function creqresp:genid()
    self.id = self.id + 1
    return self.id
end

function creqresp:req(pid,request,callback)
    local id
    if callback then
        id = self:genid()
    else
        id = 0
    end
    if id ~= 0 then
        local lifetime = request.lifetime
        local exceedtime
        if lifetime and lifetime > 0 then
            exceedtime = os.time() + lifetime
        end
        self.sessions[id] = {
            request = request,
            callback = callback,
            exceedtime = exceedtime,
            pid = pid,
        }
    end
    return id
end

function creqresp:resp(pid,id,response)
    local session = self.sessions[id]
    if session and
        (not session.pid or session.pid == 0 or session.pid == pid) then
        self.sessions[id] = nil
        if session.callback then
            session.callback(pid,session.request,response)
        end
        return session
    end
end

function creqresp:starttimer_checkallsession()
    local interval = creqresp.interval or 5
    gg.timer:timeout("creqresp:starttimer_checkallsession",interval,function () self:starttimer_checkallsession() end)
    local now = os.time()
    local die_sessions = {}
    for id,session in pairs(self.sessions) do
        if session.exceedtime and session.exceedtime < now then
            self.sessions[id] = nil
            die_sessions[id] = session
        end
    end
    for id,session in pairs(die_sessions) do
        if session.callback then
            session.callback(session.pid,session.request,{})
        end
    end
end

return creqresp
