---更新角色
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/role/update
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		sign		[required] type=string help=签名
--		appid		[required] type=string help=appid
--		roleid		[required] type=number help=角色ID
--		role		[required] type=table encode=json help=更新的角色数据
--					role = {
--						name =		[required] type=string help=名字
--						job =		[optional] type=number help=职业
--						sex =		[optional] type=number help=性别:0--男,1--女
--						shapeid =	[optional] type=number help=造型
--						lv =		[optional] type=number default=0 help=等级
--						gold =		[optional] type=number default=0 help=金币
--						now_serverid = [required] type=string help=当前所在服
--						online = [required] type=boolean help=是否在线
--					}
--	}
--
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/role/update' -d '{"appid":"appid","roleid":1000000,"role":"{\"name\":\"name\"}","sign":"debug"}'

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
		role = {type="json"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local appid = request.appid
	local roleid = request.roleid
	local role = request.role
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
	role.roleid = roleid
	--role.updatetime = os.time()
	local code = accountmgr.updaterole(appid,role)
	local response = Answer.response(code)
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
