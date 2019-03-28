profile = profile or require "skynet.profile"

profile.cost = profile.cost or {}
profile.close = false
profile.threshold = 0.05
profile.log_overload = true

function profile.record(name,onerror,func,...)
	return profile.stat(profile.cost,name,onerror,func,...)
end

function profile.stat(record,name,onerror,func,...)
	if profile.close then
		return xpcall(func,onerror,...)
	end
	profile.start()
	local result = table.pack(xpcall(func,onerror,...))
	local ok = result[1]
	local time = profile.stop()
	local cost = record[name]
	if not cost then
		cost = {
			cnt = 0,
			time = 0,
			failcnt = 0,
			overloadcnt = 0
		}
		record[name] = cost
	end
	cost.cnt = cost.cnt + 1
	cost.time = cost.time + time
	if not ok then
		cost.failcnt = cost.failcnt + 1
	else
		if profile.threshold and time > profile.threshold then
			cost.overloadcnt = cost.overloadcnt + 1
			if profile.log_overload then
				logger.logf("info","profile","op=overload,name=%s,time=%ss",name,time)
			end
		end
	end
	return table.unpack(result)
end

return profile
