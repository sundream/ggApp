--- 同步模块,如保证相同阻塞逻辑不重入
--@script gg.base.sync
--@author sundream
--@release 2018/12/25 10:30:00
sync = sync or {}

sync.once = sync.once or {
	tasks = {},
}

--- 保证相同阻塞逻辑不重入
--@param[type=int|string] id 自定义阻塞逻辑ID
--@param[type=func] func 带有阻塞逻辑的函数
--@param[opt] ... func需要的参数
--@return[type=bool] 执行是否异常
--@return func执行返回的值
--@usage
--	local id = string.format("player.%s",pid)
--	local ok,player = sync.once.Do(id,playermgr._loadplayer,pid)
function sync.once.Do(id,func,...)
	local tasks = sync.once.tasks
	local task = tasks[id]
	if not task then
		task = {
			waiting = {},
			result = nil,
		}
		tasks[id] = task
		--print("[sync.once.Do] call",id)
		local rettbl = table.pack(xpcall(func,debug.traceback,...))
		task.result = rettbl
		local waiting = task.waiting
		tasks[id] = nil
		--print("[sync.once.Do] call return",id,table.dump(task))
		if next(waiting) then
			for i,co in ipairs(waiting) do
				skynet.wakeup(co)
			end
		end
		return table.unpack(task.result,1,task.result.n)
	else
		local co = coroutine.running()
		table.insert(task.waiting,co)
		--print("[sync.once.Do] wait",id)
		skynet.wait(co)
		--print("[sync.once.Do] wait return",id,table.dump(task))
		return table.unpack(task.result,1,task.result.n)
	end
end

return sync
