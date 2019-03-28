---TOKEN认证
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/checktoken
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		sign		[required] type=string help=签名
--		appid		[required] type=string help=appid
--		account		[required] type=string help=账号
--		token		[required] type=string help=认证TOKEN
--  }
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/checktoken' -d '{"appid":"appid","account":"lgl","token":"0de3595c4666e9ce8c5b64534d811460","sign":"debug"}'

local Answer = require "answer"
local util = require "server.account.util"
local accountmgr = require "server.account.accountmgr"
local servermgr = require "server.account.servermgr"
local cjson = require "cjson"


local handler = {}

function handler.exec(args)
	local request,err = table.check(args,{
		sign = {type="string"},
		appid = {type="string"},
		account = {type="string"},
		token = {type="string"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local account = request.account
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
	local data = accountmgr.gettoken(token)
	if not data then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.TOKEN_TIMEOUT))
		return
	end
	if data.account ~= account then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.TOKEN_UNAUTH))
		return
	end
	util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.OK))
	return
end

function handler.post()
	ngx.req.read_body()
	local args = ngx.req.get_body_data()
	args = cjson.decode(args)
	handler.exec(args)
end

return handler
