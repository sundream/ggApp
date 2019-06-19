--- 同步模块,如保证相同阻塞逻辑不重入
--@script gg.base.sync
--@author sundream
--@release 2018/12/25 10:30:00

local csync = class("csync")

function csync:init()
    self.tasks = {}
end

--- 保证相同阻塞逻辑不重入
--@param[type=int|string] id 自定义阻塞逻辑ID
--@param[type=func] func 带有阻塞逻辑的函数
--@param[opt] ... func需要的参数
--@return[type=bool] 执行是否异常
--@return func执行返回的值
--@usage
--  local sync = gg.class.csync.new()
--  local id = string.format("player.%s",pid)
--  local ok,player = sync.once_do(id,playermgr._loadplayer,pid)
function csync:once_do(id,func,...)
    local tasks = self.tasks
    local task = tasks[id]
    if not task then
        task = {
            waiting = {},
            result = nil,
        }
        tasks[id] = task
        --print("[sync.once_do] call",id)
        local rettbl = table.pack(xpcall(func,debug.traceback,...))
        task.result = rettbl
        local waiting = task.waiting
        tasks[id] = nil
        --print("[sync.once_do] call return",id,table.dump(task))
        if next(waiting) then
            for i,co in ipairs(waiting) do
                skynet.wakeup(co)
            end
        end
        return table.unpack(task.result,1,task.result.n)
    else
        local co = coroutine.running()
        table.insert(task.waiting,co)
        --print("[sync.once_do] wait",id)
        skynet.wait(co)
        --print("[sync.once_do] wait return",id,table.dump(task))
        return table.unpack(task.result,1,task.result.n)
    end
end

return csync
