---重新绑定角色所属的服务器
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:      /api/account/role/rebindserver
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      sign            [required] type=string help=签名
--      appid           [required] type=string help=appid
--      account         [required] type=string help=账号
--      new_serverid    [required] type=string help=新服务器ID
--      old_roleid      [required] type=number help=旧角色ID
--      new_roleid      [required] type=number help=新角色ID(和旧角色ID相同表示角色ID不变)
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--  }
--example:
--  curl -v 'http://127.0.0.1:8885/api/account/role/rebindserver' -d '{"sign":"debug","appid":"appid","account":"lgl","old_roleid":1000000,"new_roleid":1000000,"new_serverid":"gameserver_2"}'

local handler = {}

function handler.exec(linkobj,header,args)
    local request,err = table.check(args,{
        sign = {type="string"},
        appid = {type="string"},
        account = {type="string"},
        new_serverid = {type="string"},
        old_roleid = {type="number"},
        new_roleid = {type="number"},
    })
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s",response.message,err)
        httpc.response_json(linkobj.linkid,200,response)
        return
    end
    local appid = request.appid
    local account = request.account
    local new_serverid = request.new_serverid
    local old_roleid = request.old_roleid
    local new_roleid = request.new_roleid
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
    local code = accountmgr.rebindserver(account,appid,new_serverid,old_roleid,new_roleid)
    httpc.response_json(linkobj.linkid,200,httpc.answer.response(code))
    return
end

function handler.POST(linkobj,header,query,body)
    local args = cjson.decode(body)
    handler.exec(linkobj,header,args)
end

function __hotfix(module)
    gg.hotfix("app.net.net")
end

return handler
