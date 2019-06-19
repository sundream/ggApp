--- 时间函数
--@script gg.base.time
--@author sundream
--@release 2019/3/29 14:00:00

local time = {}

--- 纪元0(标准纪元): 1970-01-01 00:00:00 周四 一月
time.STARTTIME0 = os.time({year=1970,month=1,day=1,hour=0,min=0,sec=0})
--- 纪元1: 2014-08-25 00:00:00 周一 八月
time.STARTTIME1 = os.time({year=2014,month=8,day=25,hour=0,min=0,sec=0})
--- 纪元2: 2014-08-24 00:00:00 周日 八月
time.STARTTIME2 = os.time({year=2014,month=8,day=24,hour=0,min=0,sec=0})
time.HOUR_SECS = 3600
time.DAY_SECS = 24 * time.HOUR_SECS
time.WEEK_SECS = 7 * time.DAY_SECS

--- 获取从自定义纪元开始经过的小时数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的小时数
function time.hourno(now,starttime)
    now = now or os.time()
    starttime = starttime or time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/time.HOUR_SECS) + 1
end

--- 获取从自定义纪元开始经过的天数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的天数
function time.dayno(now,starttime)
    now = now or os.time()
    starttime = starttime or time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/time.DAY_SECS) + 1
end

--- 获取从自定义纪元开始经过的礼拜数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的礼拜数
function time.weekno(now,starttime)
    now = now or os.time()
    starttime = starttime or time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/time.WEEK_SECS) + 1
end

--- 获取从自定义纪元开始经过的月数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的月数
function time.monthno(now,starttime)
    now = now or os.time()
    starttime = starttime or time.STARTTIME1
    local year1 = time.year(starttime)
    local month1 = time.month(starttime)
    local year2 = time.year(now)
    local month2 = time.month(now)
    return (year2 - year1) * 12 + month2 - month1
end

--- 获取当前时间戳(秒为单位)
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 秒数
function time.time(now)
    return now or os.time()
end

--- time的别名
time.now = time.time

--- 获取当前为第几年
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 第几年
function time.year(now)
    now = now or os.time()
    local s = os.date("%Y",now)
    return tonumber(s)
end

--- 获取当前为本年第几月
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 第几月[1,12]
function time.month(now)
    now = now or os.time()
    local s = os.date("%m",now)
    return tonumber(s)
end

--- 获取当前为本月第几天
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 第几天[1,31]
function time.day(now)
    now = now or os.time()
    local s = os.date("%d",now)
    return tonumber(s)
end

--- 本月有多少天
--@param[type=int,opt] month 本年的月份,不指定则为本月
--@return[type=int] 多少天
function time.howmuchdays(month)
    local month_zerotime = os.time({year=time.year(),month=month,day=1,hour=0,min=0,sec=0})
    for monthday in ipairs({31,30,29,28}) do
        local timestamp = month_zerotime + monthday * time.DAY_SECS
        if time.month(timestamp) == month then
            return monthday
        end
    end
    assert("Invalid month:" .. tostring(month))
end

--- 今年过去的天数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 天数[1,366]
function time.yearday(now)
    now = now or os.time()
    local s = os.date("%j",now)
    return tonumber(s)
end

--- 今天为星期几(星期天为0)
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 星期几[0,6]
function time.weekday(now)
    now = now or os.time()
    local s = os.date("%w",now)
    return tonumber(s)
end

--- 获取当前小时
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 小时[0,23]
function time.hour(now)
    now = now or os.time()
    local s = os.date("%H",now)
    return tonumber(s)
end

--- 获取当前分钟
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 分钟[0,59]
function time.minute(now)
    now = now or os.time()
    local s = os.date("%M",now)
    return tonumber(s)
end

--- 获取当前秒
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 秒[0,59]
function time.second(now)
    now = now or os.time()
    local s = os.date("%S",now)
    return tonumber(s)
end

--- 获取当天过去的秒数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 秒数
function time.daysecond(now)
    now = now or os.time()
    return time.hour(now) * time.HOUR_SECS + time.minute(now) * 60 + time.second(now)
end

--- 获取当天0点时间(秒为单位)
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 当天0点时间(秒为单位)
function time.dayzerotime(now)
    now = now or os.time()
    return time.time(now) - time.daysecond(now)
end


--- 获取当周0点
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] week_start_day 周起点天数,默认为周一,如果为周天为起点,则填0
--@return[type=int] 当周0点时间
function time.weekzerotime(now,week_start_day)
    now = now or os.time()
    week_start_day = week_start_day or 1
    local weekday = time.weekday(now)
    weekday = weekday == 0 and 7 or weekday
    local diffday = weekday - week_start_day
    return time.dayzerotime(now-diffday*time.DAY_SECS)
end

--- 获取当月0点
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 当月0点
function time.monthzerotime(now)
    now = now or os.time()
    local monthday = time.day(now)
    return time.dayzerotime(now-monthday*time.DAY_SECS)
end

--- 将秒数格式花为{day=天,hour=小时,min=分钟,sec=秒}的表示
--@param[type=table] fmt 格式表,形如{day=true,hour=true,min=true,sec=true}
--@param[type=int] secs 秒数
--@return[type=table] 格式化后的时间表
--@usage
--  local secs = 3661
--  -- {day=0,hour=1,min=1,sec=61},格式只指定了hour,因此只有hour是精确的
--  local t = time.dhms_time({hour=true})
--  -- {day=0,hour=1,min=1,sec=1},格式只指定了hour,min,sec,因此hour,min,sec都精确
--  local t = time.dhms_time({hour=true,min=true,sec=true})
function time.dhms_time(fmt,secs)
    local day = math.floor(secs/time.DAY_SECS)
    local hour = math.floor(secs/time.HOUR_SECS)
    local min = math.floor(secs/60)
    local sec = secs
    if fmt.day then
        hour = hour - 24 * day
        min = min - 24*60 * day
        sec = sec - 24*3600 * day
    end
    if fmt.hour then
        min = min - 60 * hour
        sec = sec - 3600 * hour
    end
    if fmt.min then
        sec = sec - 60 * min
    end
    return {
        day = day,
        hour = hour,
        min = min,
        sec = sec,
    }
end


--- 格式化秒数，最大粒度：天
--@param[type=string] fmt 格式字符串
--@param[type=int] secs 秒数
--@return[type=string] 格式化后的时间字符串
--@usage
-- fmt构成元素:
-- %D : XX day
-- %H : XX hour
-- %M : XX minute
-- %S : XX sec
-- %d/%h/%m/%s含义同对应大写格式,但是不会0对齐
-- e.g:
-- time.strftime("%D天%H时%S秒",30*24*3600+3601) => 30天01时01秒
-- time.strftime("%h时%s秒",30*24*3600+3601) => 721时1秒
function time.strftime(fmt,secs)
    local startpos = 1
    local endpos = string.len(fmt)
    local has_fmt = {}
    local pos = startpos
    while pos <= endpos do
        local findit,fmtflag
        findit,pos,fmtflag = string.find(fmt,"%%([dhmsDHMS])",pos)
        if not findit then
            break
        else
            pos = pos + 1
            has_fmt[fmtflag] = true
        end
    end
    if not next(has_fmt) then
        return fmt
    end
    local date_fmt = {sec=true}
    if has_fmt["d"] or has_fmt["D"] then
        date_fmt.day = true
    end
    if has_fmt["h"] or has_fmt["H"] then
        date_fmt.hour = true
    end
    if has_fmt["m"] or has_fmt["M"] then
        date_fmt.min = true
    end
    local date = time.dhms_time(date_fmt,secs)
    local DAY = string.format("%02d",date.day)
    local HOUR = string.format("%02d",date.hour)
    local MIN = string.format("%02d",date.min)
    local SEC = string.format("%02d",date.sec)
    local day = tostring(date.day)
    local hour = tostring(date.hour)
    local min = tostring(date.min)
    local sec = tostring(date.sec)
    local repls = {
        d = day,
        h = hour,
        m = min,
        s = sec,
        D = DAY,
        H = HOUR,
        M = MIN,
        S = SEC,
    }
    return string.gsub(fmt,"%%([dhmsDHMS])",repls)
end

return time
