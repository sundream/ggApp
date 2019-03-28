---删除角色
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/role/del
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		appid		[required] type=string help=appid
--		sign		[required] type=string help=签名
--		roleid		[required] type=number help=角色ID
--	}
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/role/del' -d '{"sign":"debug","appid":"appid","roleid":1000000}'

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
		roleid = {type="number"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local roleid = request.roleid
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
	local code = accountmgr.delrole(appid,roleid)
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
