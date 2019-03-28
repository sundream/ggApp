local skynet = require "skynet"
local cjson = require "cjson"
local crypt = require "skynet.crypt"
local Answer = require "app.answer"
local httpc = require "http.httpc"
local config = require "app.config.custom"


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

--- 扩展httpc.post,支持传入header,并根据header中指定content-type对form编码
--@param[type=string] host 主机地址,如:127.0.0.1:8887
--@param[type=string] url url
--@param[type=string|table] form 请求的body数据,传table时默认根据header中指定的content-type编码
--@param[type=table,opt] header 请求头,默认为application/json编码
--@param[type=table,opt] recvheader 如果指定时会记录回复收到的header信息
function httpc.postx(host,url,form,header,recvheader)
	if not header then
		header = {
			["content-type"] = "application/json;charset=utf-8"
		}
	end
	local content_type = header["content-type"]
	local body
	if string.find(content_type,"application/json") then
		if type(form) == "table" then
			body = cjson.encode(form)
		else
			body = form
		end
	else
		assert(string.find(content_type,"application/x-www-form-urlencoded"))
		if type(form) == "table" then
			body = string.urlencode(form)
		else
			body = form
		end
	end
	assert(type(body) == "string")
	return httpc.request("POST", host, url, recvheader, header, body)
end



-- 使用特定角色进入游戏,角色不存在会自动创建,不传递token默认为debug登录,
-- debug登录特点:
--	1. 创建角色时客户端可以控制角色ID
--	2. 创建角色时不经过账号中心(即不会校验账号的存在性)
local function entergame(linkobj,account,roleid,token,callback)
	local function fail(fmt,...)
		fmt = string.format("[linkid=%s,account=%s,roleid=%s] %s",linkobj.linkid,linkobj.account or account,roleid,fmt)
		skynet.error(string.format(fmt,...))
	end
	local name = tostring(roleid)
	local token = token or "debug"
	local forward = "entergame"
	linkobj:send_request("C2GS_CheckToken",{account=account,token=token,forward=forward,version="99.99.99"})
	linkobj:wait("GS2C_CheckTokenResult",function (linkobj,message)
		local request = message.request
		local status = request.status
		local code = request.code
		if status ~= 200 or code ~= Answer.code.OK then
			fail("checktoken fail: status=%s,code=%s",status,code)
			return
		end
		linkobj:send_request("C2GS_EnterGame",{roleid=roleid})
		--[[
		linkobj:wait("GS2C_ReEnterGame",function (linkobj,message)
			linkobj:ignore_one("GS2C_EnterGameResult")
			local request = message.request
			local token = request.token
			local roleid = request.roleid
			local go_serverid = request.go_serverid
			local ip = request.ip
			local new_linkobj
			if linkobj.linktype == "tcp" then
				new_linkobj = connect(ip,request.tcp_port)
			elseif linkobj.linktype == "kcp" then
				new_linkobj = kcp_connect(ip,request.kcp_port)
			end
			linkobj.child = new_linkobj
			entergame(new_linkobj,account,roleid,token,callback)
		end)
		]]
		linkobj:wait("GS2C_EnterGameResult",function (linkobj,message)
			linkobj:ignore_one("GS2C_ReEnterGame")
			local request = message.request
			local status = request.status
			local code = request.code
			if status ~= 200 or (code ~= Answer.code.OK and code ~= Answer.code.ROLE_NOEXIST) then
				fail("entergame fail: status=%s,code=%s",status,code)
				return
			end
			if code == Answer.code.ROLE_NOEXIST then
				linkobj:send_request("C2GS_CreateRole",{account=account,name=name,roleid=roleid})
				linkobj:wait("GS2C_CreateRoleResult",function (linkobj,message)
					local request = message.request
					local status = request.status
					local code = request.code
					if status ~= 200 or code ~= Answer.code.OK then
						fail("createrole fail: status=%s,code=%s",status,code)
						return
					end
					local role = request.role
					roleid = assert(role.roleid)
					skynet.error(string.format("op=createrole,linkid=%s,account=%s,roleid=%s",linkobj.linkid,account,roleid))
					entergame(linkobj,account,roleid,token,callback)
				end)
				return
			end
			linkobj.account = request.account
			if callback then
				callback(linkobj)
			end
		end)
	end)
end

-- 类似entergame,但是会先进行账密校验,账号不存在还会自动注册账号
local function quicklogin(linkobj,account,roleid,callback)
	local function fail(fmt,...)
		fmt = string.format("[linkid=%s,account=%s,roleid=%s] %s",linkobj.linkid,linkobj.account or account,roleid,fmt)
		skynet.error(string.format(fmt,...))
	end
	local passwd = "1"
	local name = roleid
	local accountcenter = string.format("%s:%s",config.accountcenter.ip,config.accountcenter.port)
	local appid = config.appid
	local url = "/api/account/login"
	local req = make_request({
		appid = appid,
		account = account,
		passwd = passwd,
	})
	local status,response = httpc.postx(accountcenter,url,req)
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
			account = account,
			passwd = passwd,
			sdk = "my",
			platform = "my",
		})
		local status,response = httpc.postx(accountcenter,url,req)
		if status ~= 200 then
			fail("register fail: status=%s",status)
			return
		end
		response = unpack_response(response)
		local code = response.code
		if code ~= Answer.code.OK then
			fail("register fail: code=%s,message=%s",code,response.message)
			return
		end
		quicklogin(linkobj,account,roleid,callback)
		return
	elseif code ~= Answer.code.OK then
		fail("login fail: code=%s,message=%s",code,response.message)
		return
	end
	local token = response.data.token
	account = response.data.account or account
	entergame(linkobj,account,roleid,token,callback)
end

return {
	entergame = entergame,
	quicklogin = quicklogin,
}
