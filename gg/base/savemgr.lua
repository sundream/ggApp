--- 存盘管理器
--@script gg.base.savemgr
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
-- 纳入管理的对象必须实现以下函数：
-- obj:savetodatabase()
-- obj.savename = 存盘对象标示名字，方便人类理解
-- obj.savetick = 存盘间隔（不指定则为默认存盘间隔300s)
--
-- gg.savemgr = csavemgr.new()
-- 切记对象销毁后调用gg.savemgr:closesave关闭存盘
-- 一般而言：对于需要纳入管理器的对象，再加入管理器时调用gg.savemgr:autosave，从管理器
-- 删除时调用gg.savemgr:closesave,如果存盘对象是全局对象，则新建时调用gg.savemgr:autosave即可。

local csavemgr = class("csavemgr")

function csavemgr:init()
    self.savetick = 300
    self.id = 0
    self.objs = {}
end

---开启一次存盘,既下次存盘间隔到后,存盘一次后就不再继续存盘
--@param[type=table] obj 存盘对象
function csavemgr:oncesave(obj)
    obj.savetype = "oncesave"
    assert(obj.savename,"no attribute: savename")
    local id = obj.saveid
    if not self:getobj(id) then
        id = self:addobj(obj)
    end
    logger.logf("info","save","op=oncesave,id=%s,savename=%s",id,obj.savename)
end

---开启自动存盘,存盘间隔为obj.savetick,若无savetick属性则默认为300s
--@param[type=table] obj 存盘对象
function csavemgr:autosave(obj)
    obj.savetype = "autosave"
    assert(obj.savename,"no attribute: savename")
    local id = obj.saveid
    if not self:getobj(id) then
        id = self:addobj(obj)
    end
    logger.logf("info","save","op=autosave,id=%s,savename=%s",id,obj.savename)
end

---使一个存盘对象立即存盘
--@param[type=table] obj 存盘对象
function csavemgr:nowsave(obj)
    local id = obj.saveid
    if not id then
        return
    end
    if not self:getobj(id) then
        return
    end
    assert(obj.savetype == "oncesave" or obj.savetype == "autosave")
    xpcall(function ()
        logger.logf("info","save","op=nowsave,id=%s,savename=%s,savetype=%s",id,obj.savename,obj.savetype)
        obj:savetodatabase()
    end,gg.onerror or debug.traceback)
    if obj.savetype == "oncesave" then
        self:closesave(obj)
    end
end

---关闭存盘
--@param[type=table] obj 存盘对象
function csavemgr:closesave(obj)
    local id = obj.saveid
    if not id then
        return
    end
    self:delobj(id)
    obj.savetype = nil
    obj.savename = nil
    obj.savetick = nil
end

--- 使所有管理的存盘对象立即存盘
function csavemgr:saveall()
    logger.logf("info","save","op=saveall")
    for id,obj in pairs(self.objs) do
        self:nowsave(obj)
    end
end

-- private method

function csavemgr:genid()
    repeat
        self.id = self.id + 1
    until self.objs[self.id] == nil
    return self.id
end

function csavemgr:getobj(id)
    return self.objs[id]
end

function csavemgr:addobj(obj,id)
    id = id or self:genid()
    logger.logf("info","save","op=addobj,id=%s,savename=%s",id,obj.savename)
    assert(self.objs[id] == nil)
    self.objs[id] = obj
    obj.saveid = id
    self:starttimer(id)
    return id
end

function csavemgr:delobj(id)
    local obj = self.objs[id]
    if obj then
        logger.logf("info","save","op=delobj,id=%s,savename=%s",id,obj.savename)
        self.objs[id] = nil
    end
end

function csavemgr:starttimer(id)
    local obj = self:getobj(id)
    if not obj then
        return
    end
    logger.logf("info","save","op=starttimer,id=%s,savename=%s",id,obj.savename)
    local key = string.format("timer.%s.%s",id,obj.savename)
    local interval = obj.savetick or self.savetick
    gg.timer:timeout(key,interval,function () self:ontimer(id) end)
end

function csavemgr:ontimer(id)
    local obj = self:getobj(id)
    if not obj then
        return
    end
    local key = string.format("timer.%s.%s",id,obj.savename)
    local interval = obj.savetick or self.savetick
    gg.timer:timeout(key,interval,function () self:ontimer(id) end)
    self:nowsave(obj)
end
