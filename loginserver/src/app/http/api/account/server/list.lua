---获取服务器列表
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--api:      /api/account/server/list
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      sign        [required] type=string help=签名
--      appid       [required] type=string help=appid
--      version     [required] type=string help=版本
--      platform    [required] type=string help=平台
--      devicetype  [required] type=string help=设备类型
--      account     [optional] type=string help=账号
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--      data = {
--          serverlist =    [required] type=list help=服务器列表,服务器格式见api/account/server/add
--          zonelist =      [required] type=list help=区列表
--      }
--  }
--example:
--  curl -v 'http://127.0.0.1:8885/api/account/server/list' -d '{"sign":"debug","appid":"appid","version":"0.0.1","platform":"local","devicetype":"ios","account":"lgl"}'


local handler = {}

function handler.exec(linkobj,header,args)
    local request,err = table.check(args,{
        sign = {type="string"},
        appid = {type="string"},
        version = {type="string"},              -- 版本
        platform = {type="string"},             -- 平台
        devicetype = {type="string"},           -- 设备类型
        account = {type="string",optional=true},
    })
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s",response.message,err)
        httpc.response_json(linkobj.linkid,200,response)
        return
    end
    local appid = request.appid
    local version = request.version
    local platform = request.platform
    local devicetype = request.devicetype
    local account = request.account
    local ip = linkobj.ip
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
    local serverlist,zonelist = util.filter_serverlist(appid,version,ip,account,platform,devicetype)
    local response = httpc.answer.response(httpc.answer.code.OK)
    response.data = {serverlist=serverlist,zonelist=zonelist}
    httpc.response_json(linkobj.linkid,200,response)
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
