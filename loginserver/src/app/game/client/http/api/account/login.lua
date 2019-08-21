---帐号+密码登录
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:      /api/account/login
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      sign        [required] type=string help=签名
--      appid       [required] type=string help=appid
--      account     [required] type=string help=账号
--      passwd      [requried] type=string help=密码(md5值)
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--      data = {
--          token =     [required] type=string help=认证TOKEN
--      }
--  }
--example:
--  curl -v 'http://127.0.0.1:8885/api/account/login' -d '{"sign":"debug","appid":"appid","account":"lgl","passwd":"1"}'

local handler = {}

function handler.exec(linkobj,header,args)
    local request,err = table.check(args,{
        sign = {type="string"},
        appid = {type="string"},
        account = {type="string"},
        passwd = {type="string"},
    })
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s",response.message,err)
        httpc.response_json(linkobj.linkid,200,response)
        return
    end
    local appid = request.appid
    local account = request.account
    local passwd = request.passwd
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
    local accountobj = accountmgr.getaccount(account)
    if not accountobj then
        httpc.response_json(linkobj.linkid,200,httpc.answer.response(httpc.answer.code.ACCT_NOEXIST))
        return
    end
    if passwd ~= accountobj.passwd then
        httpc.response_json(linkobj.linkid,200,httpc.answer.response(httpc.answer.code.PASSWD_NOMATCH))
        return
    end
    local token = accountmgr.gentoken()
    local data = {
        token = token,
        account = account,
    }
    accountmgr.addtoken(token,data)
    local response = httpc.answer.response(httpc.answer.code.OK)
    response.data = data
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