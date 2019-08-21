---更新角色
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:      /api/account/role/update
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      sign        [required] type=string help=签名
--      appid       [required] type=string help=appid
--      roleid      [required] type=number help=角色ID
--      role        [required] type=table encode=json help=更新的角色数据
--                  role = {
--                      name =      [required] type=string help=名字
--                      job =       [optional] type=number help=职业
--                      sex =       [optional] type=number help=性别:0--男,1--女
--                      shapeid =   [optional] type=number help=造型
--                      lv =        [optional] type=number default=0 help=等级
--                      gold =      [optional] type=number default=0 help=金币
--                      now_serverid = [required] type=string help=当前所在服
--                      online = [required] type=boolean help=是否在线
--                  }
--  }
--
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--  }
--example:
--  curl -v 'http://127.0.0.1:8885/api/account/role/update' -d '{"appid":"appid","roleid":1000000,"role":"{\"name\":\"name\"}","sign":"debug"}'


local handler = {}

function handler.exec(linkobj,header,args)
    local request,err = table.check(args,{
        sign = {type="string"},
        appid = {type="string"},
        roleid = {type="number"},
        role = {type="json"},
    })
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s",response.message,err)
        httpc.response_json(linkobj.linkid,200,response)
        return
    end
    local appid = request.appid
    local roleid = request.roleid
    local role = request.role
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
    role.roleid = roleid
    --role.updatetime = os.time()
    local code = accountmgr.updaterole(appid,role)
    local response = httpc.answer.response(code)
    httpc.response_json(linkobj.linkid,200,response)
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
