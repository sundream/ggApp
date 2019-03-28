---重新绑定角色所属的服务器
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/role/rebindserver
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		sign			[required] type=string help=签名
--		appid			[required] type=string help=appid
--		account			[required] type=string help=账号
--		new_serverid	[required] type=string help=新服务器ID
--		old_roleid		[required] type=number help=旧角色ID
--		new_roleid		[required] type=number help=新角色ID(和旧角色ID相同表示角色ID不变)
--	}
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/role/rebindserver' -d '{"sign":"debug","appid":"appid","account":"lgl","old_roleid":1000000,"new_roleid":1000000,"new_serverid":"gamesrv_2"}'

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
		new_serverid = {type="string"},
		old_roleid = {type="number"},
		new_roleid = {type="number"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local account = request.account
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
	local code = accountmgr.rebindserver(account,appid,new_serverid,old_roleid,new_roleid)
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
