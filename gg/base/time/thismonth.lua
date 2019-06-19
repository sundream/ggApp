---本月数据: cthismonth,继承自gg.class.ctoday
--@script gg.base.time.thismonth
--@author sundream
--@release 2019/3/29 14:00:00
--@usage see gg.base.time.today

local ctoday = gg.class.ctoday
local cthismonth = class("cthismonth",ctoday)

function cthismonth:init(conf)
    ctoday.init(self,conf)
    local monthno = gg.time.monthno()
    local monthday = gg.time.day()
    local hour = gg.time.hour()
    self.dayno = (monthday == self.month_start_day and hour < self.day_start_hour) and monthno -1 or monthno
end

function cthismonth:checkvalid()
    local monthno = gg.time.monthno()
    if self.dayno == monthno then
        return
    end
    local monthday = gg.time.day()
    local hour = gg.time.hour()
    if self.dayno + 1 == monthno then
        if monthday == self.month_start_day and hour < self.day_start_hour then
            return
        end
    end
    self.olddayno = self.dayno
    self.dayno = (monthday == self.month_start_day and hour < self.day_start_hour) and monthno -1 or monthno
    self:clear(self.olddayno)
end

return cthismonth
