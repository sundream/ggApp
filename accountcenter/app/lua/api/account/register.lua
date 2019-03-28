---注册帐号
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/register
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		sign		[required] type=string help=签名
--		appid		[required] type=string help=appid
--		account		[required] type=string help=账号
--		passwd		[requried] type=string help=密码(md5值)
--		sdk			[required] type=string help=接入的SDK
--		platform		[required] type=string help=平台
--	}
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/register' -d '{"sign":"debug","appid":"appid","account":"lgl","passwd":"1","sdk":"my","platform":"my"}'

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
		passwd = {type="string"},
		sdk = {type="string"},
		platform = {type="string"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local account = request.account
	local passwd = request.passwd
	local sdk = request.sdk
	local platform = request.platform
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
	if #account == 0 then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ACCT_FMT_ERR))
		return
	end
	if #passwd == 0 then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.PASSWD_FMT_ERR))
		return
	end
	local accountobj = accountmgr.getaccount(account)
	if accountobj then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ACCT_EXIST))
		return
	end
	local code = accountmgr.addaccount({
		account = account,
		passwd = passwd,
		sdk = sdk,
		platform = platform,
	})
	util.response_json(ngx.HTTP_OK,Answer.response(code))
	return
end

function handler.post()
	ngx.req.read_body()
	local args = ngx.req.get_body_data()
	args = cjson.decode(args)
	handler.exec(args)
end

return handler
