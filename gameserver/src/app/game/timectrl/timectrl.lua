local ctimectrl = class("ctimectrl")

function ctimectrl:init(interval)
    self.interval = interval or 5 --5mimute
end

function ctimectrl:next_fiveminute(now)
    now = now or gg.time.time()
    local secs = now + self.interval * 60
    local min = gg.time.minute(secs)
    min = math.floor(min/self.interval) * self.interval
    local tm = {
        year = gg.time.year(secs),
        month = gg.time.month(secs),
        day = gg.time.day(secs),
        hour = gg.time.hour(secs),
        min = min,
        sec = 0,
    }
    return os.time(tm)
end

function ctimectrl:starttimer()
    local now = gg.time.time()
    local next_time = self:next_fiveminute(now)
    assert(next_time > now,string.format("%d > %d",next_time,now))
    gg.timer:timeout("timectrl.starttimer",next_time-now,function ()
        self:starttimer()
        self:fiveminute_update()
    end)
end

function ctimectrl:fiveminute_update()
    self:onfiveminuteupdate()
    local now = gg.time.time()
    local min = gg.time.minute(now)
    if min % 10 == 0 then
        self:tenminute_update()
    end
end

function ctimectrl:tenminute_update(now)
    self:ontenminuteupdate()
    local min = gg.time.minute(now)
    if min == 0 or min == 30 then
        self:halfhour_update()
    end
end

function ctimectrl:halfhour_update(now)
    self:onhalfhourupdate()
    local min = gg.time.minute(now)
    if min == 0 then
        self:hour_update(now)
    end
end

function ctimectrl:hour_update(now)
    self:onhourupdate()
    local hour = gg.time.hour(now)
    if hour == 0  then
        self:day_update(now)
    end
end

function ctimectrl:day_update(now)
    self:ondayupdate()
    local weekday = gg.time.weekday(now)
    if weekday == 0 then
        self:sunday_update(now)
    elseif weekday == 1 then
        self:monday_update(now)
    end
    local day = gg.time.day(now)
    if day == 1 then
        self:month_update()
    end
end

function ctimectrl:monday_update(now)
    self:onmondayupdate()
end

function ctimectrl:sunday_update(now)
    self:onsundayupdate()
end

function ctimectrl:month_update(now)
    self:onmonthupdate()
end

function ctimectrl:onfiveminuteupdate()
end

function ctimectrl:ontenminuteupdate()
end

function ctimectrl:onhalfhourupdate()
end


function ctimectrl:onhourupdate()
    gg.playermgr:broadcast(gg.class.cplayer.onhourupdate) -- safe call
end

function ctimectrl:ondayupdate()
    gg.playermgr:broadcast(gg.class.cplayer.ondayupdate)
end

function ctimectrl:onmondayupdate()
    gg.playermgr:broadcast(gg.class.cplayer.onmondayupdate)
end

function ctimectrl:onsundayupdate()
end

function ctimectrl:onmonthupdate()
    gg.playermgr:broadcast(gg.class.cplayer.onmonthupdate)
end

return ctimectrl
