---rpc调用
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:      /api/rpc
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      module     [optional] type=string help=模块名,不指定则从_G中寻找指令
--      cmd         [required] type=string help=指令
--      args        [required] type=list encode=json help=参数列表
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--      result =    [required] type=list help=执行指令返回的参数列表
--  }
--example:
--  curl -v 'http://127.0.0.1:8885/api/rpc' -d '{"sign":"debug","cmd":"tonumber","args":"[\"10\"]"}'
--  curl -v 'http://127.0.0.1:8885/api/rpc' -d '{"sign":"debug","cmd":"logger.log","args":"[\"error\",\"client_error\",\"msg\"]"}'

local handler = {}

function handler.exec(linkobj,header,args)
    local request,err = table.check(args,{
        sign = {type="string"},
        module = {type="string",optional=true},
        cmd = {type="string"},
        args = {type="json"},
    })
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s",response.message,err)
        httpc.response_json(linkobj.linkid,200,response)
        return
    end
    local sign = request.sign
    local appkey = skynet.getenv("appkey")
    if not httpc.check_signature(args.sign,args,appkey) then
        httpc.response_json(linkobj.linkid,200,httpc.answer.response(httpc.answer.code.SIGN_ERR))
        return
    end
    local module = request.module
    local cmd = request.cmd
    local args = request.args
    if module == nil then
        module = _G
    end
    local response = httpc.answer.response(httpc.answer.code.OK)
    response.result = {
        gg.exec(module,cmd,table.unpack(args)),
    }
    httpc.response_json(linkobj.linkid,200,response)
end

function handler.POST(linkobj,header,query,body)
    local args = cjson.decode(body)
    handler.exec(linkobj,header,args)
end

function __hotfix(module)
    gg.hotfix("app.net.net")
end

return handler
