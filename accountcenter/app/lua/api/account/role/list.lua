---获取角色列表
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/role/list
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		sign		[required] type=string help=签名
--		appid		[required] type=string help=appid
--		account		[required] type=string help=账号
--		serverid	[optional] type=string help=服务器ID
--	}
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
--			rolelsit =	[optional] type=list help=角色列表,角色格式见api/role/get
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/role/list' -d '{"sign":"debug","appid":"appid","account":"lgl"}'
--	curl -v 'http://127.0.0.1:8887/api/account/role/list' -d '{"sign":"debug","appid":"appid","account":"lgl","serverid":"gamesrv_1"}'

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
		serverid = {type="string",optional=true},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local account = request.account
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
	if not accountmgr.getaccount(account) then
		util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ACCT_NOEXIST))
		return
	end
	local rolelist = accountmgr.getrolelist(account,appid)
	print(table.dump(rolelist),account,appid)
	if serverid then
		rolelist = table.filter(rolelist,function (v)
			return v.create_serverid == serverid
		end)
	end
	local response = Answer.response(Answer.code.OK)
	response.data = {rolelist=rolelist}
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
