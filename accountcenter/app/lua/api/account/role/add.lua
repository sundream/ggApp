---新增角色
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/role/add
--protocol:	http/https
--method:	post
--params:
--  type=table encode=json
--  {
--		sign		[required] type=string help=签名
--		appid		[required] type=string help=appid
--		account		[required] type=string help=账号
--		serverid	[required] type=string help=服务器ID
--		roleid		[optional] type=number help=角色ID,不指定则必选传genrolekey,minroleid,maxroleid
--		genrolekey	[optional] type=string help=为genroleid指定key
--		minroleid	[optional] type=number help=最小角色ID
--		maxroleid	[optional] type=number help=最大角色ID(不包括此值),区间为[minroleid,maxroleid)
--		role		[required] type=table encode=json help=角色数据
--					role = {
--						name =		[required] type=string help=名字
--						job =		[optional] type=number help=职业
--						sex =		[optional] type=number help=性别:0--男,1--女
--						shapeid =	[optional] type=number help=造型
--						lv =		[optional] type=number default=0 help=等级
--						gold =		[optional] type=number default=0 help=金币
--					}
--  }
--
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
--			role =	[required] type=table help=角色数据
--								role格式见/api/account/role/get
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/role/add' -d '{"appid":"appid","account":"lgl","serverid":"gamesrv_1","roleid":1000000,"role":"{\"name\":\"name\"}","sign":"debug"}'
--	curl -v 'http://127.0.0.1:8887/api/account/role/add' -d '{"appid":"appid","account":"lgl","serverid":"gamesrv_1","genrolekey":"appid","minroleid":1000000,"maxroleid":1000000000,"role":"{\"name\":\"name\"}","sign":"debug"}'

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
		serverid = {type="string"},
		role = {type="json"},
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
	local roleid
	if request.roleid then
		roleid = request.roleid
	else
		if not (request.genrolekey and
			request.minroleid and
			request.maxroleid) then
			local response = Answer.response(Answer.code.PARAM_ERR)
			response.message = string.format("%s|%s",response.message,"'genrolekey,minroleid,maxroleid' must appear at same time")
			util.response_json(ngx.HTTP_OK,response)
			return
		end
		roleid = accountmgr.genroleid(appid,request.genrolekey,request.minroleid,request.maxroleid)
		if not roleid then
			util.response_json(ngx.HTTP_OK,Answer.response(Answer.code.ROLE_OVERLIMIT))
			return
		end
	end
	role.roleid = roleid
	local code = accountmgr.addrole(account,appid,serverid,role)
	local response = Answer.response(code)
	if code == Answer.code.OK then
		response.data = {role=role}
	end
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
