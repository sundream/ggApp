gm = gm or {}

local queue = require "skynet.queue"
gm_lock = gm_lock or queue()
function gm.docmd(cmdline)
	local split = string.split(cmdline,"%s")
	local retlist = table.pack(gm_lock(gm._docmd,split))
	logger.logf("info","gm","op=docmd,cmdline='%s',return=%s",cmdline,retlist)
	return table.unpack(retlist)
end

local function getfunc(cmds,cmd)
	local func = table.getattr(cmds,cmd)
	if func then
		return func
	end
	cmd = string.lower(cmd)
	local func = table.getattr(cmds,cmd)
	if func then
		return func
	end
	for k,v in pairs(cmds) do
		if string.lower(k) == cmd then
			return v
		end
	end
end

function gm._docmd(cmds)
	local cmdline = table.concat(cmds," ")
	local pid = table.remove(cmds,1)
	local cmd = table.remove(cmds,1)
	pid = tonumber(pid)
	if not pid then
		return gm.say("no pid: " .. cmdline)
	end
	if not cmd then
		return gm.say("no cmd: " .. cmdline)
	end
	local func = getfunc(gm,cmd)
	if not func then
		return gm.say(string.format("not found cmd: %q",cmd))
	end
	if pid ~= 0 then
		gm.master = playermgr.getplayer(pid)
		if not gm.master then
			return pid .. " not online"
		end
		--[[
		local online,now_serverid = playermgr.route(pid)
		if online then
			if now_serverid ~= gg.server.id then
				return rpc.call(now_serverid,"exec","gm.docmd",cmdline)
			else
				gm.master = playermgr.getplayer(pid)
			end
		else
			local target = cdelaytonextlogin.new(pid)
			target:executex("gm.docmd",cmdline)
			return "delaytonextlogin"
		end
		]]
	end
	local ret = table.pack(pcall(func,cmds))
	gm.master = nil
	return table.unpack(ret,1,ret.n)
end

function gm.say(msg,pid)
	if gm.master then
		pid = pid or gm.master.pid
	end
	if pid and pid ~= 0 then
		-- todo: say with client
		print(msg)
	end
	return msg
end

return gm
