---帐号+密码登录
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/login
--protocol:	http/https
--method:
--	get		just support in debug mode
--	post
--params:
--	sign		[required] type=string help=签名
--	appid		[required] type=string help=appid
--	acct		[required] type=string help=账号
--	passwd		[requried] type=string help=密码(md5值)
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
--			token =		[required] type=string help=认证TOKEN
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/login?sign=debug&appid=appid&acct=lgl&passwd=1'
--	curl -v 'http://127.0.0.1:8887/api/account/login' -d 'sign=debug&appid=appid&acct=lgl&passwd=1'

local Answer = require "answer"
local util = require "server.account.util"
local acctmgr = require "server.account.acctmgr"
local servermgr = require "server.account.servermgr"
local banlogin = require "server.account.banlogin"


local handle = {}

function handle.exec(args)
	local request,err = table.check(args,{
		sign = {type="string"},
		appid = {type="string"},
		acct = {type="string"},
		passwd = {type="string"},
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
	local isok,detail = banlogin.isbanacct(appid,acct)
	if isok then
		local response = Answer.response(Answer.code.BAN_ACCT)
		response.data = detail
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local ip = ngx.var.remote_addr
	isok,detail = banlogin.isbanip(appid,ip)
	if isok then
		local response = Answer.response(Answer.code.BAN_IP)
		response.data = detail
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local acctobj = acctmgr.getacct(acct)
	if not acctobj then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ACCT_NOEXIST))
		return
	end
	if passwd ~= acctobj.passwd then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.PASSWD_NOMATCH))
		return
	end
	local token = acctmgr.gentoken()
	local data = {
		token = token,
		acct = acct,
	}
	acctmgr.addtoken(token,data)
	local response = Answer.response(Answer.code.OK)
	response.data = data
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
