---注册帐号
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/register
--protocol:	http/https
--method:
--	get		just support in debug mode
--	post
--params:
--	sign		[required] type=string help=签名
--	appid		[required] type=string help=appid
--	acct		[required] type=string help=账号
--	passwd		[requried] type=string help=密码(md5值)
--	sdk			[required] type=string help=接入的SDK
--	platform		[required] type=string help=平台
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/register?sign=debug&appid=appid&acct=lgl&passwd=1&sdk=my&platform=my'
--	curl -v 'http://127.0.0.1:8887/api/account/register' -d 'sign=debug&appid=appid&acct=lgl&passwd=1&sdk=my&platform=my'

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
	local acct = request.acct
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
	if #acct == 0 then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ACCT_FMT_ERR))
		return
	end
	if #passwd == 0 then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.PASSWD_FMT_ERR))
		return
	end
	local acctobj = acctmgr.getacct(acct)
	if acctobj then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ACCT_EXIST))
		return
	end
	local code = acctmgr.addacct({
		acct = acct,
		passwd = passwd,
		sdk = sdk,
		platform = platform,
	})
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
