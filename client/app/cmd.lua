local http = require "socket.http"
local cjson = require "cjson"
local crypt = require "crypt"
local Answer = require "app.answer"

function exit()
	os.exit(0)
end

function help()
	print([=[
connect(ip,port,[master_linkid]) ->
	tcp connect to ip:port and return a linkobj
	e.g:
		linkobj = connect("127.0.0.1",8888)
kcp_connect(ip,port,[master_linkid]) ->
	kcp connect to ip:port and return a kcpobj
	e.g:
		linkobj = kcp_connect("127.0.0.1",8889)
websocket_connect(ip,port,[master_linkid]) ->
	websocket connect to ip:port and return a kcpobj
	e.g:
		linkobj = websocket_connect("127.0.0.1",8890)
quicklogin(linkobj,account,roleid) ->
	use account#roleid to login,if account donn't exist,auto register it
	if account's role donn't exist,auto create role(roleid may diffrence)
	e.g:
		quicklogin(linkobj,"lgl",1000000)
entergame(linkobj,account,roleid) ->
	use roleid to debuglogin,if role donn't exist,auto create role
	debuglogin's features:
		1. client can control the roleid when create role
		2. do not communicate with account center when create role,
		so donn't use it except you really understand
	e.g:
		entergame(linkobj,"lgl",1000000)
linkobj:send_request(proto,request,[callback]) ->
	use linkobj to send a request
	e.g:
		linkobj:send_request("C2GS_Ping",{str="hello,world!"})
linkobj:send_response(proto,response,session) ->
	use linkobj to send a response
linkobj:quite() ->
	stop/start print linkobj receive message
	]=])
end

function connect(ip,port,master_linkid)
	local tcp = require "app.client.tcp"
	local tcpobj = tcp.new()
	tcpobj.master_linkid = master_linkid
	tcpobj:connect(ip,port)
	return tcpobj
end

function kcp_connect(ip,port,master_linkid)
	local kcp = require "app.client.kcp"
	local kcpobj = kcp.new()
	kcpobj.master_linkid = master_linkid
	kcpobj:connect(ip,port)
	return kcpobj
end

function websocket_connect(ip,port,master_linkid)
	local websocket = require "app.client.websocket"
	local wbobj = websocket.new()
	wbobj.master_linkid = master_linkid
	wbobj:connect(ip,port)
	return wbobj
end

-- 使用特定角色进入游戏,角色不存在会自动创建,不传递token默认为debug登录,
-- debug登录特点:
--	1. 创建角色时客户端可以控制角色ID
--	2. 创建角色时不经过账号中心(即不会校验账号的存在性)
function entergame(linkobj,account,roleid,token)
	local function fail(fmt,...)
		fmt = string.format("[linktype=%s,account=%s,roleid=%s] %s",linkobj.linktype,linkobj.account or account,roleid,fmt)
		print(string.format(fmt,...))
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
			entergame(new_linkobj,account,roleid,token)
		end)
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
					print(string.format("op=createrole,account=%s,roleid=%s",account,roleid))
					entergame(linkobj,account,roleid,token)
				end)
				return
			end
			linkobj.account = request.account
			fail("login success")
		end)
	end)
end

local function escape(s)
	return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function signature(str,secret)
	if type(str) == "table" then
		str = table.ksort(str,"&",{sign=true})
	end
	return crypt.base64encode(crypt.hmac_sha1(secret,str))
end

local function make_request(request,secret)
	secret = secret or app.config.accountcenter.secret
	request.sign = signature(request,secret)
	return cjson.encode(request)
	--[[
	local list = {}
	for k,v in pairs(request) do
		table.insert(list,string.format("%s=%s",escape(k),escape(v)))
	end
	return table.concat(list,"&")
	]]
end

local function unpack_response(response)
	response = cjson.decode(response)
	return response
end

-- 类似entergame,但是会先进行账密校验,账号不存在还会自动注册账号
function quicklogin(linkobj,account,roleid)
	local function fail(fmt,...)
		fmt = string.format("[linktype=%s,account=%s,roleid=%s] %s",linkobj.linktype,linkobj.account or account,roleid,fmt)
		print(string.format(fmt,...))
	end
	local passwd = "1"
	local name = roleid
	local accountcenter = app.config.accountcenter
	local appid = app.config.appid
	local url = string.format("http://%s:%s/api/account/login",accountcenter.ip,accountcenter.port)
	local req = make_request({
		appid = appid,
		account = account,
		passwd = passwd,
	})
	local response,status = http.request(url,req)
	if not response or status ~= 200 then
		fail("login fail,status:%s",status)
		return
	end
	response = unpack_response(response)
	local code = response.code
	if code == Answer.code.ACCT_NOEXIST then
		-- register account
		local url = string.format("http://%s:%s/api/account/register",accountcenter.ip,accountcenter.port)
		local req = make_request({
			appid = appid,
			account = account,
			passwd = passwd,
			sdk = "my",
			platform = "my",
		})
		local response,status = http.request(url,req)
		if not response or status ~= 200 then
			fail("register fail: status=%s",status)
			return
		end
		response = unpack_response(response)
		local code = response.code
		if code ~= Answer.code.OK then
			fail("register fail: code=%s,message=%s",code,response.message)
			return
		end
		quicklogin(linkobj,account,roleid)
		return
	elseif code ~= Answer.code.OK then
		fail("login fail: code=%s,message=%s",code,response.message)
		return
	end
	local token = response.data.token
	account = response.data.account or account
	entergame(linkobj,account,roleid,token)
end
