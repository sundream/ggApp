---新增角色
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/role/add
--protocol:	http/https
--method:
--	get		just support in debug mode
--	post
--params:
--	sign		[required] type=string help=签名
--	appid		[required] type=string help=appid
--	acct		[required] type=string help=账号
--	serverid	[required] type=string help=服务器ID
--	roleid		[optional] type=string help=角色ID,不指定则必选传genroleid,minroleid,maxroleid
--	genroleid	[optional] type=number help=标志自动生成角色ID,同时必须指定minroleid,maxroleid
--	minroleid	[optional] type=number help=最小角色ID
--	maxroleid	[optional] type=number help=最大角色ID(不包括此值),区间为[minroleid,maxroleid)
--	genrolekey	[optional] type=string help=为genroleid指定key,不发则为serverid
--	role		[required] type=table encode=json help=角色数据
--				role = {
--					name =		[required] type=string help=名字
--					job =		[required] type=number help=职业
--					sex =		[required] type=number help=性别:0--男,1--女
--					shapeid =	[required] type=number help=造型
--					lv =		[optional] type=number default=0 help=等级
--					gold =		[optional] type=number default=0 help=金币
--				}
--
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
--			role =	[required] type=table help=角色数据
--								role格式见/api/account/role/get
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/role/add?sign=debug&appid=appid&acct=lgl&serverid=gamesrv_1&role=role_json_data&roleid=1000000'
--	curl -v 'http://127.0.0.1:8887/api/account/role/add?sign=debug&appid=appid&acct=lgl&serverid=gamesrv_1&role=role_json_data&genroleid=1&minroleid=1000000&maxroleid=2000000'
--	curl -v 'http://127.0.0.1:8887/api/account/role/add' -d 'sign=debug&appid=appid&acct=lgl&serverid=gamesrv_1&role=role_json_data&roleid=1000000'
--	curl -v 'http://127.0.0.1:8887/api/account/role/add' -d 'sign=debug&appid=appid&acct=lgl&serverid=gamesrv_1&role=role_json_data&genroleid=1&minroleid=1000000&maxroleid=2000000'

local Answer = require "answer"
local util = require "server.account.util"
local acctmgr = require "server.account.acctmgr"
local servermgr = require "server.account.servermgr"

local handle = {}

function handle.exec(args)
	local request,err = table.check(args,{
		sign = {type="string"},
		appid = {type="string"},
		acct = {type="string"},
		serverid = {type="string"},
		role = {type="json"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		print(table.dump(response))
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local acct = request.acct
	local serverid = request.serverid
	local role = request.role
	local app = util.get_app(appid)
	if not app then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.APPID_NOEXIST))
		return
	end
	local secret = app.secret
	if not util.check_signature(args.sign,args,secret) then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.SIGN_ERR))
		return
	end
	local roleid
	if request.roleid then
		roleid = request.roleid
	else
		if not (request.genroleid and
			request.minroleid and
			request.maxroleid) then
			local response = Answer.response(Answer.code.PARAM_ERR)
			response.message = string.format("%s|%s",response.message,"'genroleid,minroleid,maxroleid' must appear at same time")
			util.response_json(ngx.HTTP_OK,response)
			return
		end
		local genrolekey = request.genrolekey or serverid
		roleid = acctmgr.genroleid(appid,genrolekey,request.minroleid,request.maxroleid)
		if not roleid then
			util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ROLE_OVERLIMIT))
			return
		end
	end
	role.roleid = roleid
	local code = acctmgr.addrole(acct,appid,serverid,role)
	local response = Answer.response(code)
	response.data = {role=role}
	util.response_json(ngx.HTTP_OK,response)
	return
end

function handle.get()
	local config = util.config()
	if config.mode ~= "debug" then
		util.response_json(ngx.HTTP_FORBIDDEN)
		return
	end
	local args = ngx.req.get_uri_args()
	handle.exec(args)
end

function handle.post()
	ngx.req.read_body()
	local args = ngx.req.get_post_args()
	handle.exec(args)
end

return handle
