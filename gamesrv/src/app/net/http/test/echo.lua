---测试http
--@author sundream
--@release 2019/1/15 20:00:00
--@usage
--api:		/api/gamesrv/test/echo
--protocol:	http/https
--method:	post
--params:
--	type=table encode=json
--	{
--		number		[required] type=number help=测试数值
--		string		[required] type=string help=测试字符串
--		json		[optional] type=json encode=json help=测试json
--	}
--return:
--	type=table encode=json
--	{
--		code =		[required] type=number help=返回码
--		message =	[required] type=number help=返回码说明
--		data = {
----		number		[required] type=number help=测试数值
--			string		[required] type=string help=测试字符串
--			json		[optional] type=json encode=json help=测试json
--		}
--	}
--example:
--	curl -v 'http://127.0.0.1:8887/test/echo' -d '{"number":1,"string":"hello","json":"[1,2,3]"}'

local handler = {}
function handler.exec(linkobj,header,args)
	local request,err = table.check(args,{
		number = {type="number"},
		string = {type="string"},
		json = {type="json",optional=true},
	})
	if err then
		local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
		response.message = string.format("%s|%s",response.message,err)
		httpc.response_json(linkobj.linkid,200,response)
		return
	end
	local number = request.number
	local string = request.string
	local json = request.json
	local response = httpc.answer.response(httpc.answer.code.OK)
	response.data = {
		number = number,
		string = string,
		json = json,
	}
	httpc.response_json(linkobj.linkid,200,response)
end

function handler.post(linkobj,header,query,body)
	local args = cjson.decode(body)
	handler.exec(linkobj,header,args)
end

function __hotfix(oldmod)
	hotfix.hotfix("app.net.init")
end

return handler
