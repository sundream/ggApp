---管理生命期为指定时间的对象: cthistemp
--@script gg.base.time.thistemp
--@author sundream
--@release 2019/3/29 14:00:00

local cdatabaseable = gg.class.cdatabaseable
local cthistemp = class("cthistemp",cdatabaseable)

function cthistemp:init()
    cdatabaseable.init(self)
    self.time = {}
end

--- 序列化
--@return 序列化后的数据表
function cthistemp:serialize()
    local data = {}
    data["data"] = self.data
    data["time"] = self.time
    return data
end

--- 反序列化
--@param[type=table] data 准备反序列化的数据表
function cthistemp:unserialize(data)
    if not data or not next(data) then
        return
    end
    self.data = data["data"]
    self.time = data["time"]
end

--- 清空所有数据
function cthistemp:clear()
    cdatabaseable.clear(self)
    self.time = {}
end

function cthistemp:checkvalid(key)
    local attrs = self:__split(key)
    local expire = self:__getattr(self.time,attrs)
    if expire then
        local now = os.time()
        assert(type(expire) == "number",string.format("not-leaf-node:%s",key))
        if expire <= now then
            self:__setattr(self.time,attrs,nil)
            cdatabaseable.del(self,key)
            return false,nil
        end
    end
    return true,expire
end

--- 设置,首次设置必须指定生命期,未指定secs时,对象生命期不变
--@param[type=string] key 键
--@param[type=any] val 值
--@param[type=int] secs 超时值,秒为单位
--@param[type=func,opt] callback 超时回调
--@usage thistemp:set("firstset",1,10)
--@usage thistemp:set("firstset",20)    -- 只将值改成20，超时值不变
--@usage thistemp:set("firstset",10,20) -- 值改成10,超时值改成未来20s
function cthistemp:set(key,val,secs)
    local expire = self:getexpire(key)
    local now = os.time()
    local new_expire
    if not expire then
        assert(secs)
        new_expire = now + secs
    else
        if secs then
            new_expire = now + secs
        else
            new_expire = expire
        end
    end
    local oldval = cdatabaseable.set(self,key,val)
    if expire ~= new_expire then
        local attrs = self:__split(key)
        self:__setattr(self.time,attrs,new_expire)
    end
    return oldval,expire
end

--- 增加
--@param[type=string] key 键(增加时一般需要保证该键对应的值为整数类型)
--@param[type=number] val 增加的值
--@usage
--      local oldval,expire = thistemp:get(key)
--      if nil == oldval then
--          local new_val = xxx
--          local new_expire = xxx
--          thistemp:set(key,new_val,new_expire)
--      else
--          thistemp:add(key,addval)
--      end
function cthistemp:add(key,val)
    return cdatabaseable.add(self,key,val)
end

--- 获取
--@param[type=string] key 键
--@param[type=any] default 默认值
--@return[type=any] 该键保存的数据
--@usage local val = thistemp:get("key",0)
--@usage local val = thistemp:get("k1.k2.k3")
function cthistemp:get(key,default)
    local expire = self:getexpire(key)
    return cdatabaseable.get(self,key,default),expire
end

--- [deprecated] get的别名
cthistemp.query = cthistemp.get

--- 删除
--@param[type=string] key 键
--@return[type=any] 该键保存的旧数据
--@usage thistemp:del("key")
--@usage thistemp:del("k1.k2.k3")
function cthistemp:del(key)
    local attrs = self:__split(key)
    return cdatabaseable.del(self,key),self:__delattr(self.time,attrs)
end

--- [deprecated] del的别名
cthistemp.delete = cthistemp.del

--- 获取过期时间点
--@param[type=string] key 键
--@return[type=int] 过期时间点
--@usage local expire = thistemp:getexpire("key")
--@usage local expire = thistemp:getexpire("k1.k2.k3")
function cthistemp:getexpire(key)
    local ok,expire = self:checkvalid(key)
    if not ok then
        return nil
    end
    return expire
end

cthistemp.getexceedtime = cthistemp.getexpire

--- 获取剩余超时值TTL
--@param[type=string] key 键
--@return[type=int] 剩余超时值TTL,秒为单位
--@usage local ttl = thistemp:ttl("key")
--@usage local ttl = thistemp:ttl("k1.k2.k3")
function cthistemp:ttl(key)
    local expire = self:getexpire(key)
    if not expire then
        return nil
    end
    return expire - os.time()
end

--- 延长生命周期(对已失效的key值无效)
--@param[type=string] key 键
--@param[type=int] expire 设置的过期时间点,秒为单位
--@return[type=int] 旧的过期时间点
function cthistemp:expireat(key,expire)
    local old_expire = self:getexpire(key)
    if not old_expire then
        return
    end
    local now = os.time()
    if expire <= now then
        self:del(key)
    else
        local attrs = self:__split(key)
        self:__setattr(self.time,attrs,expire)
    end
    return old_expire
end

--- 延长生命周期(对已失效的key值无效)
--@param[type=string] key 键
--@param[type=int] ttl 新的超时值,等价于expireat(key,os.time()+ttl)
--@return[type=int] 旧的过期时间点
function cthistemp:expire(key,ttl)
    return self:expireat(key,os.time()+ttl)
end

cthistemp.delay = cthistemp.expire

return cthistemp
