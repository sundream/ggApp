net.login = net.login or {
	C2GS = {},
	GS2C = {},
}

local C2GS = net.login.C2GS
local GS2C = net.login.GS2C

function C2GS.Ping(linkobj,message)
	local request = message.request
	client.sendpackage(linkobj,"GS2C_Pong",{
		str = request and request.str,
		time = os.time(),
	})
end

function net.login.is_safe_ip(ip)
	return ip == "127.0.0.1"
end

net.login.version = skynet.getenv("version") or "0.0.1"

function net.login.is_low_version(version)
	local list1 = string.split(net.login.version,".")
	local list2 = string.split(version,".")
	local len = #list1
	for i=1,len do
		local ver1 = tonumber(list1[i])
		local ver2 = tonumber(list2[i])
		if not ver2 then
			return true
		end
		if ver2 < ver1 then
			return true
		elseif ver2 > ver1 then
			return false
		end
	end
	return false
end

-- CreateRole/EnterGame前token认证,检查是否通过登录认证
function C2GS.CheckToken(linkobj,message)
	local request = message.request
	local token = assert(request.token)
	local account = assert(request.account)
	local version = request.version
	local forward = request.forward		-- 透传参数
	if net.login.is_low_version(version) then
		local response = httpc.answer.response(httpc.answer.code.LOW_VERSION)
		response.status = 200
		response.forward = forward
		client.sendpackage(linkobj,"GS2C_CheckTokenResult",response)
		return
	end
	local debuglogin = false
	local token_data = playermgr.tokens:get(token)
	if token == "debug" and net.login.is_safe_ip(linkobj.ip) then
		debuglogin = true
	elseif token_data ~= nil then
		if token_data.account and token_data.account ~= account then
			local response = httpc.answer.response(httpc.answer.code.TOKEN_UNAUTH)
			response.status = 200
			response.forward = forward
			client.sendpackage(linkobj,"GS2C_CheckTokenResult",response)
			return
		end
		if token_data.kuafu then
			-- 跨服透传的数据只生效一次
			token_data.kuafu = nil
			linkobj.kuafu_forward = token_data
		end
	else
		-- TODO: check ban createrole/entergame
		local accountcenter = skynet.getenv("accountcenter")
		local appid = skynet.getenv("appid")
		local url = "/api/account/checktoken"
		local req = httpc.make_request({
			appid = appid,
			account = account,
			token = token,
		})
		local status,response = httpc.postx(accountcenter,url,req)
		if status ~= 200 then
			client.sendpackage(linkobj,"GS2C_CheckTokenResult",{status = status,forward=forward})
			return
		end
		response = httpc.unpack_response(response)
		if response.code ~= httpc.answer.code.OK then
			client.sendpackage(linkobj,"GS2C_CheckTokenResult",{
				status = status,
				code = response.code,
				message = response.message,
				forward = forward,
			})
			return
		end
		playermgr.tokens:set(token,{account=account},302)
	end
	linkobj.passlogin = true
	linkobj.version = version
	linkobj.token = token
	linkobj.debuglogin = debuglogin
	local status,code = 200,0
	client.sendpackage(linkobj,"GS2C_CheckTokenResult",{
		status = status,
		code = code,
		message = httpc.answer.message[code],
		forward = forward;
	})
end

function C2GS.CreateRole(linkobj,message)
	local request = message.request
	local account = assert(request.account)
	local name = assert(request.name)
	if not linkobj.passlogin then
		local response = httpc.answer.response(httpc.answer.code.PLEASE_LOGIN_FIRST)
		response.status = 200;
		client.sendpackage(linkobj,"GS2C_CreateRoleResult",response)
		return
	end
	local errcode = gg.server:checkname(name)
	if errcode ~= httpc.answer.code.OK then
		local response = httpc.answer.response(errcode)
		response.status = 200
		client.sendpackage(linkobj,"GS2C_CreateRoleResult",response)
		return
	end
	local role = {
		account = account,
		name = name,
	}
	local roleid
	if linkobj.debuglogin and request.roleid then
		-- 方便内部测试
		roleid = request.roleid
	else
		local accountcenter = skynet.getenv("accountcenter")
		local appid = skynet.getenv("appid")
		local serverid = skynet.getenv("id")
		local url = "/api/account/role/add"
		local req = httpc.make_request({
			appid = appid,
			account = account,
			serverid = serverid,
			role = cjson.encode(role),
			genrolekey = appid, -- 全服ID统一分配
			minroleid = 1000000,
			maxroleid = 1000000000,
		})
		local status,response = httpc.postx(accountcenter,url,req)
		if status ~= 200 then
			client.sendpackage(linkobj,"GS2C_CreateRoleResult",{status = status,})
			return
		end
		response = httpc.unpack_response(response)
		if response.code ~= httpc.answer.code.OK then
			client.sendpackage(linkobj,"GS2C_CreateRoleResult",{
				status = status,
				code = response.code,
				message = response.message,
			})
			return
		end
		local roledata = assert(response.data.role)
		roleid = assert(tonumber(roledata.roleid))
	end
	role.roleid = roleid
	role.account = account
	playermgr.createplayer(role.roleid,role)
	local status = 200
	local code = httpc.answer.code.OK
	client.sendpackage(linkobj,"GS2C_CreateRoleResult",{
		status = status,
		code = code,
		message = httpc.answer.message[code],
		role = role,
	})
end

function net.login._entergame(linkobj,message)
	local request = message.request
	local pid = assert(request.roleid)
	-- TODO: check ban entergame
	if linkobj.pid then
		local response = httpc.answer.response(httpc.answer.code.REPEAT_ENTERGAME)
		response.status = 200
		client.sendpackage(linkobj,"GS2C_EnterGameResult",response)
		return
	end
	if not linkobj.passlogin then
		local response = httpc.answer.response(httpc.answer.code.PLEASE_LOGIN_FIRST)
		response.status = 200
		client.sendpackage(linkobj,"GS2C_EnterGameResult",response)
		return
	end
	local replace
	local player = playermgr.getplayer(pid)
	if player then
		replace = true
		if not player:isdisconnect() then
			-- TODO: give tip to been replace's linkobj?
			-- will unbind and del linkobj
			player:disconnect("replace")
		end
	else
		-- 跨服顶号
		local online,now_serverid = playermgr.route(pid)
		if online then
			--assert(now_serverid ~= cserver:serverid())
			if now_serverid ~= gg.server.id then
				-- 强制关服可能导致online状态不对
				linkobj.roleid = pid
				playermgr.gosrv(linkobj,now_serverid)
				return
			end
		end
		replace = false
		player = playermgr.recoverplayer(pid)
		if not player then
			local response = httpc.answer.response(httpc.answer.code.ROLE_NOEXIST)
			response.status = 200

			client.sendpackage(linkobj,"GS2C_EnterGameResult",response)
			return
		end
	end
	playermgr.bind_linkobj(player,linkobj)
	if not replace then
		playermgr.addplayer(player)
	end
	client.sendpackage(linkobj,"GS2C_EnterGameStart")
	player:entergame(replace)
	linkobj.passlogin = nil
	local response = httpc.answer.response(httpc.answer.code.OK)
	response.status = 200
	response.account = player.account
	response.linkid = linkobj.linkid
	client.sendpackage(linkobj,"GS2C_EnterGameResult",response)
end

function C2GS.EnterGame(linkobj,message)
	local request = message.request
	local roleid = assert(request.roleid)
	local id = string.format("entergame.%s",roleid)
	local ok,errmsg = sync.once.Do(id,net.login._entergame,linkobj,message)
	assert(ok,errmsg)
end

function C2GS.ExitGame(player,message)
	playermgr.kick(player.pid,"exitgame")
end

function __hotfix(oldmod)
	hotfix.hotfix("app.net.init")
end

return net.login
