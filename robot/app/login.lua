local cjson = require "cjson"
local crypt = require "skynet.crypt"
local Answer = require "app.answer"
local httpc = require "http.httpc"
local config = require "app.config.user"

-- 使用特定角色进入游戏,角色不存在会自动创建,不传递token默认为debug登录,
-- debug登录特点:
--	1. 创建角色时客户端可以控制角色ID
--	2. 创建角色时不经过账号中心(即不会校验账号的存在性)
local function entergame(tcpobj,acct,roleid,token,callback)
	local function fail(fmt,...)
		fmt = string.format("[linktype=%s,%s#%s] %s",tcpobj.linktype,tcpobj.account or acct,roleid,fmt)
		print(string.format(fmt,...))
	end
	local name = tostring(roleid)
	local token = token or "debug"
	local forward = "entergame"
	tcpobj:send_request("C2GS_CheckToken",{acct=acct,token=token,forward=forward,version="99.99.99"})
	tcpobj:wait("GS2C_CheckTokenResult",function (tcpobj,message)
		local request = message.request
		local status = request.status
		local code = request.code
		if status ~= 200 or code ~= Answer.code.OK then
			fail("checktoken fail: status=%s,code=%s",status,code)
			return
		end
		tcpobj:send_request("C2GS_EnterGame",{roleid=roleid})
		--[[
		tcpobj:wait("GS2C_ReEnterGame",function (tcpobj,message)
			tcpobj:ignore_one("GS2C_EnterGameResult")
			local request = message.request
			local token = request.token
			local roleid = request.roleid
			local go_serverid = request.go_serverid
			local ip = request.ip
			local new_tcpobj
			if tcpobj.linktype == "tcp" then
				new_tcpobj = connect(ip,request.tcp_port)
			elseif tcpobj.linktype == "kcp" then
				new_tcpobj = kcp_connect(ip,request.kcp_port)
			end
			tcpobj.child = new_tcpobj
			entergame(new_tcpobj,acct,roleid,token,callback)
		end)
		]]
		tcpobj:wait("GS2C_EnterGameResult",function (tcpobj,message)
			tcpobj:ignore_one("GS2C_ReEnterGame")
			local request = message.request
			local status = request.status
			local code = request.code
			if status ~= 200 or (code ~= Answer.code.OK and code ~= Answer.code.ROLE_NOEXIST) then
				fail("entergame fail: status=%s,code=%s",status,code)
				return
			end
			if code == Answer.code.ROLE_NOEXIST then
				tcpobj:send_request("C2GS_CreateRole",{acct=acct,name=name,roleid=roleid})
				tcpobj:wait("GS2C_CreateRoleResult",function (tcpobj,message)
					local request = message.request
					local status = request.status
					local code = request.code
					if status ~= 200 or code ~= Answer.code.OK then
						fail("createrole fail: status=%s,code=%s",status,code)
						return
					end
					local role = request.role
					roleid = assert(role.roleid)
					print(string.format("auto createrole: account=%s,roleid=%s",acct,roleid))
					entergame(tcpobj,acct,roleid,token,callback)
				end)
				return
			end
			tcpobj.account = request.account
			fail("login success")
			if callback then
				callback(tcpobj)
			end
		end)
	end)
end

local function signature(str,secret)
	if type(str) == "table" then
		str = table.ksort(str,"&",{sign=true})
	end
	return crypt.base64encode(crypt.hmac_sha1(secret,str))
end

local function make_request(request,secret)
	secret = secret or config.accountcenter.secret
	request.sign = signature(request,secret)
	return request
end

local function unpack_response(response)
	response = cjson.decode(response)
	return response
end

-- 类似entergame,但是会先进行账密校验,账号不存在还会自动注册账号
local function quicklogin(tcpobj,acct,roleid,callback)
	local function fail(fmt,...)
		fmt = string.format("[linktype=%s,%s#%s] %s",tcpobj.linktype,tcpobj.account or acct,roleid,fmt)
		print(string.format(fmt,...))
	end
	local passwd = "1"
	local name = roleid
	local accountcenter = string.format("%s:%s",config.accountcenter.ip,config.accountcenter.port)
	local appid = config.appid
	local url = "/api/account/login"
	local req = make_request({
		appid = appid,
		acct = acct,
		passwd = passwd,
	})
	local status,response = httpc.post(accountcenter,url,req)
	print(status,response)
	if status ~= 200 then
		fail("login fail,status:%s",status)
		return
	end
	response = unpack_response(response)
	local code = response.code
	if code == Answer.code.ACCT_NOEXIST then
		-- register account
		local url = "/api/account/register"
		local req = make_request({
			appid = appid,
			acct = acct,
			passwd = passwd,
			sdk = "my",
			channel = "my",
		})
		local status,response = httpc.post(accountcenter,url,req)
		if status ~= 200 then
			fail("register fail: status=%s",status)
			return
		end
		response = unpack_response(response)
		local code = response.code
		if code ~= Answer.code.OK then
			fail("register fail: code=%s,message=%s",code,Answer.message[code])
			return
		end
		quicklogin(tcpobj,acct,roleid,callback)
		return
	elseif code ~= Answer.code.OK then
		fail("login fail: code=%s,message=%s",code,Answer.message[code])
		return
	end
	local token = response.data.token
	acct = response.data.acct or acct
	entergame(tcpobj,acct,roleid,token,callback)
end

return {
	entergame = entergame,
	quicklogin = quicklogin,
}
