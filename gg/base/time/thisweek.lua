--- 本周数据(周一为起始点),继承自gg.class.ctoday
--@script gg.base.time.thisweek
--@author sundream
--@release 2019/3/29 14:00:00
--@usage see gg.base.time.today

local ctoday = gg.class.ctoday
local cthisweek = class("cthisweek",ctoday)

function cthisweek:init(conf)
    ctoday.init(self,conf)
    local weekday = gg.time.weekday()
    local nowweek = gg.time.weekno()
    local hour = gg.time.hour()
    self.dayno = (weekday == 1 and hour < self.day_start_hour) and nowweek - 1 or nowweek
end

function cthisweek:checkvalid()
    local nowweek = gg.time.weekno()
    if self.dayno == nowweek then
        return
    end
    local weekday = gg.time.weekday()
    local hour = gg.time.hour()
    if self.dayno + 1 == nowweek then
        if weekday == self.week_start_day and hour < self.day_start_hour then
            return
        end
    end
    local olddayno = self.dayno
    self.dayno = (weekday == self.week_start_day and hour < self.day_start_hour) and nowweek - 1 or nowweek
    self:clear(olddayno)
end

return cthisweek
