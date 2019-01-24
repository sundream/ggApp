---重新绑定角色所属的服务器
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/role/rebindsrv
--protocol:	http/https
--method:
--	get		just support in debug mode
--	post
--params:
--	sign			[required] type=string help=签名
--	appid			[required] type=string help=appid
--	acct			[required] type=string help=账号
--	new_serverid	[required] type=string help=新服务器ID
--	old_roleid		[required] type=string help=旧角色ID
--	new_roleid		[required] type=string help=新角色ID
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/role/rebindsrv?sign=debug&appid=appid&acct=lgl&old_roleid=1000000&new_roleid=1000000&new_serverid=gamesrv_2'
--	curl -v 'http://127.0.0.1:8887/api/account/role/rebindsrv' -d 'sign=debug&appid=appid&acct=lgl&old_roleid=1000000&new_roleid=1000000&new_serverid=gamesrv_2'

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
		new_serverid = {type="string"},
		old_roleid = {type="string"},
		new_roleid = {type="string"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local acct = request.acct
	local new_serverid = request.new_serverid
	local old_roleid = request.old_roleid
	local new_roleid = request.new_roleid
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
	local code = acctmgr.rebindsrv(acct,appid,new_serverid,old_roleid,new_roleid)
	util.response_json(ngx.HTTP_OK,Answer.response(code))
	return
end

function handle.get()
	local config = util.config()
	if config.env ~= "dev" then
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
