---重新绑定角色所属的帐号
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:      /api/account/role/rebindaccount
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      sign        [required] type=string help=签名
--      appid       [required] type=string help=appid
--      new_account [required] type=string help=新账号
--      roleid      [required] type=number help=角色ID
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--  }
--example:
--  curl -v 'http://127.0.0.1:8885/api/account/role/rebindaccount' -d '{"sign":"debug","appid":"appid","new_account":"lgl2","roleid":1000000}'

local handler = {}

function handler.exec(linkobj,header,args)
    local request,err = table.check(args,{
        sign = {type="string"},
        appid = {type="string"},
        new_account = {type="string"},
        roleid = {type="number"},
    })
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s",response.message,err)
        httpc.response_json(linkobj.linkid,200,response)
        return
    end
    local appid = request.appid
    local new_account = request.new_account
    local roleid = request.roleid
    local app = util.get_app(appid)
    if not app then
        httpc.response_json(linkobj.linkid,200,httpc.answer.response(httpc.answer.code.APPID_NOEXIST))
        return
    end
    local appkey = app.appkey
    if not httpc.check_signature(args.sign,args,appkey) then
        httpc.response_json(linkobj.linkid,200,httpc.answer.response(httpc.answer.code.SIGN_ERR))
        return
    end
    local code = accountmgr.rebindaccount(new_account,appid,roleid)
    httpc.response_json(linkobj.linkid,200,httpc.answer.response(code))
    return
end

function handler.POST(linkobj,header,query,body)
    local args = cjson.decode(body)
    handler.exec(linkobj,header,args)
end

function __hotfix(module)
    gg.hotfix("app.game.client.client")
end

return handler
