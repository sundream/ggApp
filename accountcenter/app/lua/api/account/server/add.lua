---新增服务器
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/server/add
--protocol:	http/https
--method: post
--params:
--	type=table encode=json
--	{
--		sign		[required] type=string help=签名
--		appid		[required] type=string help=appid
--		serverid	[required] type=string help=服务器ID
--		server		[required] type=table encode=json help=服务器数据
--					server = {
--						//id =				[required] type=string help=服务器ID
--						ip =				[required] type=string help=ip
--						tcp_port =			[required] type=number help=tcp端口
--						kcp_port =			[required] type=number help=kcp端口
--						websocket_port =	[required] type=number help=websocket端口
--						debug_port =		[required] type=number help=debug端口
--						name =				[required] type=string help=服务器名字
--						type =				[required] type=string help=服务器类型
--						zoneid =			[required] type=string help=区ID
--						zonename =			[required] type=string help=区名
--						area =				[required] type=string help=大区ID
--						areaname =			[required] type=string help=大区名
--						env =				[required] type=string help=部署环境ID
--						envname =			[required] type=string help=部署环境名(如内网环境,外网测试环境,外网正式环境)
--						opentime =			[required] type=number help=预计开服时间
--						isopen =			[optional] type=number default=1 help=是否开放
--						busyness =			[optional] type=number default=0.0 help=负载
--						newrole =			[optional] type=number default=1 help=是否可以新建角色
--					}
--	}
--return:
--	type=table encode=json
--	{
--		code =		[requied] type=number help=返回码
--		message =	[required] type=string help=返回码说明
--	}
--example:
-- curl -v 'http://127.0.0.1:8887/api/account/server/add' -d '{"appid": "appid","serverid": "gamesrv_1", "sign": "debug", "server": "{\"zoneid\": \"dev1\", \"opentime\": 1536659100, \"name\": \"逻辑1服\", \"area\": \"dev\", \"kcp_port\": 8889, \"ip\": \"127.0.0.1\", \"websocket_port\": 8890, \"envname\": \"内网环境\", \"env\": \"dev\", \"tcp_port\": 8888, \"debug_port\": 18888, \"type\": \"gamesrv\", \"id\": \"gamesrv_1\", \"index\": 1,\"areaname\": \"内网\", \"zonename\": \"内网1区\"}"}'


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
		serverid = {type="string"},
		server = {type="json"},
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
	local server = request.server
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
	server.id = serverid
	local code = servermgr.addserver(appid,server)
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
