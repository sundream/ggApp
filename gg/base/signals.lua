local csignals = class("csignals")

function csignals:init(id)
    self.id = id or tostring(self)
    self.timeout = {}       -- 超时锁
    self.signals = {}
end

--- 生成信号ID
--@param ... 若干字符串或数字参数
--@usage
--local signal = self:signal("lucky number",8888)
function csignals:signal(...)
    local keys = {...}
    table.insert(keys,self.id)
    return table.concat(keys,".")
end

--- 等待信号
--@param[type=string] signal 信号
--@param[type=int,opt] timeuot 超时值,nil/<=0--永久等待
--@return[type=bool] 是否超时
--@return wakeup唤醒传递的所有参数
function csignals:wait(signal,timeout)
    local timer_id
    if timeout and timeout > 0 then
        timer_id = skynet.timeout(timeout,function ()
            local data = self.signals[signal]
            if not data or data.timer_id ~= timer_id then
                return
            end
            self:timeout_wakeup(signal)
        end)
    end
    assert(self.signals[signal] == nil)
    self.signals[signal] = {
        timer_id = timer_id,
    }
    skynet.wait(signal)
    local data = self.signals[signal]
    assert(data)
    self.signals[signal] = nil
    return data.timeout,table.unpack(data.result)
end

function csignals:_wakeup(signal,timeout,...)
    local data = self.signals[signal]
    if data then
        if timeout == self.timeout then
            data.timeout = true
            data.result = table.pack(...)
        else
            data.timeout = false
            data.result = table.pack(timeout,...)
        end
        skynet.wakeup(signal)
    end
end

--- 唤醒信号
--@param[type=string] signal 信号
--@param ... 唤醒传递的若干参数
function csignals:wakeup(signal,...)
    self:_wakeup(signal,...)
end

--- 超时唤醒信号,使wait返回结果为超时
--@param[type=string] signal 信号
function csignals:timeout_wakeup(signal)
    self:_wakeup(signal,self.timeout)
end

return csignals
