---获取一个服务器信息
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/server/get
--protocol:	http/https
--	http
--	https
--method:
--	get		just support in debug mode
--	post
--params:
--	sign		[required] type=string help=签名
--	appid		[required] type=string help=appid
--	serverid	[required] type=string help=服务器ID
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
--			server =	[optional] type=table help=存在则返回该服务器数据,服务器格式见api/account/server/add
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/server/get?sign=debug&appid=appid&serverid=gamesrv_1'
--	curl -v 'http://127.0.0.1:8887/api/account/server/get' -d 'sign=debug&appid=appid&serverid=gamesrv_1'

local Answer = require "answer"
local util = require "server.account.util"
local acctmgr = require "server.account.acctmgr"
local servermgr = require "server.account.servermgr"


local handle = {}

function handle.exec(args)
	local request,err = table.check(args,{
		sign = {type="string"},
		appid = {type="string"},
		serverid = {type="string"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local acct = request.acct
	local serverid = request.serverid
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
	local server = servermgr.getserver(appid,serverid)
	local response = Answer.response(Answer.code.OK)
	response.data = {server=server}
	util.response_json(ngx.HTTP_OK,response)
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
