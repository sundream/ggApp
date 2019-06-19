---新增app
--@author sundream
--@release 2019/6/18 10:30:00
--@usage
--api:      /api/app/add
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      app = [required] type=json help=app
--  }
--  app格式如下
--  {
--      appid           [required] type=string help=模块名,不指定则从_G中寻找指令
--      appkey          [required] type=string help=指令
--      platform_whitelist  [required] type=table help=平台白名单
--      ip_whitelist    [optional] type=table help=ip白名单
--      account_whitelist [optional] type=table help=账号白名单
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--  }

local handler = {}

function handler.exec(linkobj,header,args)
    local request,err = table.check(args,{
        sign = {type="string"},
        app = {type="json"},
    })
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s",response.message,err)
        httpc.response_json(linkobj.linkid,200,response)
        return
    end
    local app = request.app
    local appid = assert(app.appid)
    local sign = request.sign
    local appkey = skynet.getenv("appkey")
    if not httpc.check_signature(args.sign,args,appkey) then
        httpc.response_json(linkobj.linkid,200,httpc.answer.response(httpc.answer.code.SIGN_ERR))
        return
    end
    local db = dbmgr:getdb()
    if dbmgr.db_type == "redis" then
        local key = string.format("app")
        db:hset(key,appid,cjson.encode(app))
    else
       db.app:update({appid=appid},app,true,false) 
    end
    local response = httpc.answer.response(httpc.answer.code.OK)
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
