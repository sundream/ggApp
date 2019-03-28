--- 时间函数
--@script gg.base.time
--@author sundream
--@release 2018/12/25 10:30:00

--- 纪元0(标准纪元): 1970-01-01 00:00:00 周四 一月
STARTTIME0 = os.time({year=1970,month=1,day=1,hour=0,min=0,sec=0})
--- 纪元1: 2014-08-25 00:00:00 周一 八月
STARTTIME1 = os.time({year=2014,month=8,day=25,hour=0,min=0,sec=0})
--- 纪元2: 2014-08-24 00:00:00 周日 八月
STARTTIME2 = os.time({year=2014,month=8,day=24,hour=0,min=0,sec=0})
HOUR_SECS = 3600
DAY_SECS = 24 * HOUR_SECS
WEEK_SECS = 7 * DAY_SECS

--- 获取从纪元1开始经过的小时数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的小时数
function gethourno(now,starttime)
	now = now or os.time()
	starttime = starttime or STARTTIME1
	local diff = now - starttime
	return math.floor(diff/HOUR_SECS) + 1
end

--- 获取从纪元2开始经过的小时数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元2
--@return[type=int] 经过的小时数
function gethourno2(now,starttime)
	starttime = starttime or STARTTIME2
	return gethourno(now,starttime)
end

--- 获取从纪元1开始经过的天数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的天数
function getdayno(now,starttime)
	now = now or os.time()
	starttime = starttime or STARTTIME1
	local diff = now - starttime
	return math.floor(diff/DAY_SECS) + 1
end

--- 获取从纪元2开始经过的天数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元2
--@return[type=int] 经过的天数
function getdayno2(now,starttime)
	starttime = starttime or STARTTIME2
	return getdayno(now,starttime)
end

--- 获取从纪元1开始经过的礼拜数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的礼拜数
function getweekno(now,starttime)
	now = now or os.time()
	starttime = starttime or STARTTIME1
	local diff = now - starttime
	return math.floor(diff/WEEK_SECS) + 1
end

--- 获取从纪元2开始经过的礼拜数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元2
--@return[type=int] 经过的礼拜数
function getweekno2(now,starttime)
	starttime = starttime or STARTTIME2
	return getweekno(now,starttime)
end

--- 获取从纪元1开始经过的月数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元1
--@return[type=int] 经过的月数
function getmonthno(now,starttime)
	now = now or os.time()
	starttime = starttime or STARTTIME1
	local year1 = getyear(starttime)
	local month1 = getyearmonth(starttime)
	local year2 = getyear(now)
	local month2 = getyearmonth(now)
	return (year2 - year1) * 12 + month2 - month1
end

--- 获取从纪元2开始经过的月数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@param[type=int,opt] starttime 纪元时间点,默认为纪元2
--@return[type=int] 经过的月数
function getmonthno2(now,starttime)
	starttime = starttime or STARTTIME2
	return getmonthno(now,starttime)
end

--- 获取当前秒数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 秒数
function getsecond(now)
	return now or os.time()
end

--- 获取当前为第几年
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 第几年
function getyear(now)
	now = now or os.time()
	local s = os.date("%Y",now)
	return tonumber(s)
end

--- 获取当前为本年第几月
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 第几月
function getyearmonth(now)
	now = now or os.time()
	local s = os.date("%m",now)
	return tonumber(s)
end

--- 获取当前为本月第几天
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 第几天
function getmonthday(now)
	now = now or os.time()
	local s = os.date("%d",now)
	return tonumber(s)
end

--- 本月有多少天
--@param[type=int,opt] monthno 本年的月份,不指定则为本月
--@return[type=int] 多少天
function howmuchdays(monthno)
	local month_zerotime = os.time({year=getyear(),month=monthno,day=1,hour=0,min=0,sec=0})
	for monthday in ipairs({31,30,29,28}) do
		local time = month_zerotime + monthday * DAY_SECS
		if getyearmonth(time) == monthno then
			return monthday
		end
	end
	assert("Invalid monthno:" .. tostring(monthno))
end

--- 今天为星期几(星期天为0)
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 星期几
function getweekday(now)
	now = now or os.time()
	local s = os.date("%w",now)
	return tonumber(s)
end

--- 获取当前小时
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 小时
function getdayhour(now)
	now = now or os.time()
	local s = os.date("%H",now)
	return tonumber(s)
end

--- 获取当前分钟
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 分钟
function gethourminute(now)
	now = now or os.time()
	local s = os.date("%M",now)
	return tonumber(s)
end

--- 获取当前秒
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 秒
function getminutesecond(now)
	now = now or os.time()
	local s = os.date("%S",now)
	return tonumber(s)
end

--- 获取当天过去的秒数
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 秒数
function getdaysecond(now)
	now = now or os.time()
	return getdayhour(now) * HOUR_SECS + gethourminute(now) * 60 + getminutesecond(now)
end

--- 获取当天0点时间(秒为单位)
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 当天0点时间(秒为单位)
function getdayzerotime(now)
	now = now or os.time()
	return getsecond(now) - getdaysecond(now)
end


--- 获取当周0点(星期一为一周起点)
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 当周0点(星期一为一周起点)
function getweekzerotime(now)
	now = now or os.time()
	local weekday = getweekday(now)
	weekday = weekday == 0 and 7 or weekday
	local diffday = weekday - 1
	return getdayzerotime(now-diffday*DAY_SECS)
end

--- 获取当周0点（星期天为一周起点)
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 当周0点（星期天为一周起点)
function getweekzerotime2(now)
	now = now or os.time()
	local weekday = getweekday(now)
	local diffday = weekday - 0
	return getdayzerotime(now-diffday*DAY_SECS)
end

--- 获取当月0点
--@param[type=int,opt] now 待计算的时间,默认为当前时间
--@return[type=int] 当月0点
function getmonthzerotime(now)
	now = now or os.time()
	local monthday = getmonthday(now)
	return getdayzerotime(now-monthday*DAY_SECS)
end

--- 将秒数格式花为{day=天,hour=小时,min=分钟,sec=秒}的表示
--@param[type=table] fmt 格式表,形如{day=true,hour=true,min=true,sec=true}
--@param[type=int] secs 秒数
--@return[type=table] 格式化后的时间表
--@usage
--	local secs = 3661
--	-- {day=0,hour=1,min=1,sec=61},格式只指定了hour,因此只有hour是精确的
--	local t = dhms_time({hour=true})
--	-- {day=0,hour=1,min=1,sec=1},格式只指定了hour,min,sec,因此hour,min,sec都精确
--	local t = dhms_time({hour=true,min=true,sec=true})
function dhms_time(fmt,secs)
	local day = math.floor(secs/DAY_SECS)
	local hour = math.floor(secs/HOUR_SECS)
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
-- strftime("%D天%H时%S秒",30*24*3600+3601) => 30天01时01秒
-- strftime("%h时%s秒",30*24*3600+3601) => 721时1秒
function strftime(fmt,secs)
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
	local date = dhms_time(date_fmt,secs)
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
