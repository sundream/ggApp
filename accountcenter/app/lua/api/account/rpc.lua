---rpc调用,仅用于内部调试
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:		/api/account/rpc
--protocol:	http/https
--method:
--	get		just support in debug mode
--	post	just support in debug mode
--params:
--	modname		[optional] type=string help=模块名,不指定则从_G中寻找指令
--	cmd			[required] type=string help=指令
--	arglist		[required] type=list encode=json help=参数列表
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
--	curl -v 'http://127.0.0.1:8887/api/account/rpc?cmd=print&arglist=\["string",10\]'
--	curl -v 'http://127.0.0.1:8887/api/account/rpc?cmd=tonumber&arglist=\["10"\]'
--	curl -v 'http://127.0.0.1:8887/api/account/rpc' -d 'cmd=tonumber&arglist=["10"]'
--	// '&' urlencode is %26
--	curl -v 'http://127.0.0.1:8887/api/account/rpc' -d 'modname=server.account.util&cmd=signature&arglist=["one=1%26two=2","secret"]'

local Answer = require "answer"
local util = require "server.account.util"

local handle = {}

-- TODO: arglist如何传入nil值?
function handle.exec(args)
	local request,err = table.check(args,{
		modname = {type="string",optional=true},
		cmd = {type="string"},
		arglist = {type="json"},
	})
	if err then
		local response = Answer.response(Answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		util.response_json(ngx.HTTP_OK,response)
		return
	end
	local modname = request.modname
	local cmd = request.cmd
	local arglist = request.arglist
	if modname == nil then
		modname = _G
	end
	local response = Answer.response(Answer.code.OK)
	response.data = {
		ret = {call(modname,cmd,table.unpack(arglist))},
	}
	util.response_json(ngx.HTTP_OK,response)
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
	local config = util.config()
	if config.mode ~= "debug" then
		util.response_json(ngx.HTTP_FORBIDDEN)
		return
	end
	ngx.req.read_body()
	local args = ngx.req.get_post_args()
	handle.exec(args)
end

return handle
