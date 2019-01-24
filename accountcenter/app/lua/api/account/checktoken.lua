---TOKEN认证
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/checktoken
--protocol:	http/https
--method:
--	get		just support in debug mode
--	post
--params:
--	sign		[required] type=string help=签名
--	appid		[required] type=string help=appid
--	acct		[required] type=string help=账号
--	token		[required] type=string help=认证TOKEN
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/checktoken?sign=debug&appid=appid&acct=lgl&token=03227b1bd2343ca956e891efc4831c09'
--	curl -v 'http://127.0.0.1:8887/api/account/checktoken' -d 'sign=debug&appid=appid&acct=lgl&token=03227b1bd2343ca956e891efc4831c09'

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
		token = {type="string"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local acct = request.acct
	local token = request.token
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
	local data = acctmgr.gettoken(token)
	if not data then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.TOKEN_TIMEOUT))
		return
	end
	if data.acct ~= acct then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.TOKEN_UNAUTH))
		return
	end
	util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.OK))
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
