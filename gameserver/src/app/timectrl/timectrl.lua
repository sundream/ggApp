timectrl = timectrl or {}

function timectrl.init(interval)
    timectrl.interval = interval or 5 --5mimute
    timectrl.starttimer()
end

function timectrl.next_fiveminute(now)
    now = now or gg.time.time()
    local secs = now + timectrl.interval * 60
    local min = gg.time.minute(secs)
    min = math.floor(min/timectrl.interval) * timectrl.interval
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

function timectrl.starttimer()
    local now = gg.time.time()
    local next_time = timectrl.next_fiveminute(now)
    assert(next_time > now,string.format("%d > %d",next_time,now))
    gg.timer:timeout("timectrl.starttimer",next_time-now,timectrl.fiveminute_update)
end

function timectrl.fiveminute_update()
    timectrl.starttimer()
    timectrl.onfiveminuteupdate()
    local now = gg.time.time()
    local min = gg.time.minute(now)
    if min % 10 == 0 then
        timectrl.tenminute_update()
    end
end

function timectrl.tenminute_update(now)
    timectrl.ontenminuteupdate()
    local min = gg.time.minute(now)
    if min == 0 or min == 30 then
        timectrl.halfhour_update()
    end
end

function timectrl.halfhour_update(now)
    timectrl.onhalfhourupdate()
    local min = gg.time.minute(now)
    if min == 0 then
        timectrl.hour_update(now)
    end
end

function timectrl.hour_update(now)
    timectrl.onhourupdate()
    local hour = gg.time.hour(now)
    if hour == 0  then
        timectrl.day_update(now)
    end
end

function timectrl.day_update(now)
    timectrl.ondayupdate()
    local weekday = gg.time.weekday(now)
    if weekday == 0 then
        timectrl.sunday_update(now)
    elseif weekday == 1 then
        timectrl.monday_update(now)
    end
    local day = gg.time.day(now)
    if day == 1 then
        timectrl.month_update()
    end
end

function timectrl.monday_update(now)
    timectrl.onmondayupdate()
end

function timectrl.sunday_update(now)
    timectrl.onsundayupdate()
end

function timectrl.month_update(now)
    timectrl.onmonthupdate()
end

function timectrl.onfiveminuteupdate()
end

function timectrl.ontenminuteupdate()
end

function timectrl.onhalfhourupdate()
end


function timectrl.onhourupdate()
    playermgr.broadcast(gg.class.cplayer.onhourupdate) -- safe call
end

function timectrl.ondayupdate()
    playermgr.broadcast(gg.class.cplayer.ondayupdate)
end

function timectrl.onmondayupdate()
    playermgr.broadcast(gg.class.cplayer.onmondayupdate)
end

function timectrl.onsundayupdate()
end

function timectrl.onmonthupdate()
    playermgr.broadcast(gg.class.cplayer.onmonthupdate)
end

return timectrl
