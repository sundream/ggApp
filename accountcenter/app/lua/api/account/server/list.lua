---获取服务器列表
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/server/list
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		sign		[required] type=string help=签名
--		appid		[required] type=string help=appid
--		version		[required] type=string help=版本
--		platform		[required] type=string help=平台
--		devicetype	[required] type=string help=设备类型
--		account		[optional] type=string help=账号
--	}
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
--			serverlist =	[required] type=list help=服务器列表,服务器格式见api/account/server/add
--			zonelist =		[required] type=list help=区列表
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/server/list' -d '{"sign":"debug","appid":"appid","version":"0.0.1","platform":"my","devicetype":"ios","account":"lgl"}'

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
		version = {type="string"},				-- 版本
		platform = {type="string"},				-- 平台
		devicetype = {type="string"},			-- 设备类型
		account = {type="string",optional=true},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local version = request.version
	local platform = request.platform
	local devicetype = request.devicetype
	local account = request.account
	local ip = ngx.var.remote_addr
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
	local serverlist,zonelist = util.filter_serverlist(appid,version,ip,account,platform,devicetype)
	local response = Answer.response(Answer.code.OK)
	response.data = {serverlist=serverlist,zonelist=zonelist}
	util.response_json(ngx.HTTP_OK,response)
	return
end

function handler.post()
	ngx.req.read_body()
	local args = ngx.req.get_body_data()
	args = cjson.decode(args)
	handler.exec(args)
end

return handler
