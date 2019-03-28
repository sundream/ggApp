---rpc调用,仅用于内部调试
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/rpc
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		modname		[optional] type=string help=模块名,不指定则从_G中寻找指令
--		cmd			[required] type=string help=指令
--		args		[required] type=list encode=json help=参数列表
--	}
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
--			ret =	[required] type=list help=执行指令返回的参数列表
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/api/account/rpc' -d '{"cmd":"tonumber","args":["10"]}'

local Answer = require "answer"
local util = require "server.account.util"
local cjson = require "cjson"

local handler = {}

-- TODO: args如何传入nil值?
function handler.exec(args)
	local request,err = table.check(args,{
		modname = {type="string",optional=true},
		cmd = {type="string"},
		args = {type="table"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local modname = request.modname
	local cmd = request.cmd
	local args = request.args
	if modname == nil then
		modname = _G
	end
	local response = Answer.response(Answer.code.OK)
	response.data = {
		ret = {exec(modname,cmd,table.unpack(args))},
	}
	util.response_json(ngx.HTTP_OK,response)
end

function handler.post()
	local config = util.config()
	if config.env ~= "dev" then
		util.response_json(ngx.HTTP_FORBIDDEN)
		return
	end
	ngx.req.read_body()
	local args = ngx.req.get_body_data()
	args = cjson.decode(args)
	handler.exec(args)
end

return handler
