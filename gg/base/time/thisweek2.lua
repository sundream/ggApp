--- 本周数据(周天为起始点),继承自gg.class.ctoday
--@script gg.base.time.thisweek2
--@author sundream
--@release 2019/3/29 14:00:00
--@usage see gg.base.time.today

local ctoday = gg.class.ctoday
local cthisweek2 = class("cthisweek2",ctoday)

function cthisweek2:init(conf)
    ctoday.init(self,conf)
    local weekday = gg.time.weekday()
    local nowweek2 = gg.time.weekno(nil,gg.time.STARTTIME2)
    local hour = gg.time.hour()
    self.dayno = (weekday == self.week_start_day2 and hour < self.day_start_hour) and nowweek2 - 1 or nowweek2
end

function cthisweek2:checkvalid()
    local nowweek2 = gg.time.weekno(nil,gg.time.STARTTIME2)
    if self.dayno == nowweek2 then
        return
    end
    local weekday = gg.time.weekday()
    local hour = gg.time.hour()
    if self.dayno + 1 == nowweek2 then
        if weekday == self.week_start_day2 and hour < self.day_start_hour then
            return
        end
    end
    local olddayno = self.dayno
    self.dayno = (weekday == self.week_start_day2 and hour < self.day_start_hour) and nowweek2 - 1 or nowweek2
    self:clear(olddayno)
end

return cthisweek2
