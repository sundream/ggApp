local cloginserver = class("cloginserver")

---cloginserver.new调用的构造函数
--@usage
--local loginserver = gg.class.cloginserver.new({
--  host = 登录服ip:port,
--  appid = 应用id,
--  appkey = 应用对应的加密键,
--})
function cloginserver:init(conf)
    self.host = assert(conf.host)
    self.appid = assert(conf.appid)
    self.appkey = assert(conf.appkey)
end

function cloginserver:signature(str)
    if type(str) == "table" then
        str = table.ksort(str,"&",{sign=true})
    end
    return crypt.base64encode(crypt.hmac_sha1(self.appkey,str))
end

function cloginserver:encode_request(request)
    request.sign = self:signature(request)
    return cjson.encode(request)
end

function cloginserver:decode_response(status,response)
    if status ~= 200 then
        return status,response
    end
    return status,cjson.decode(response)
end

function cloginserver:post(url,req)
    return httpc.postx(self.host,url,req)
end

---换绑服务器
--@param[type=string] account 账号
--@param[type=string] new_serverid 新服务器ID
--@param[type=int] old_roleid 旧角色ID
--@param[type=int,opt] new_roleid 新角色ID,默认等于旧角色ID
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:rebindserver(account,new_serverid,old_roleid,new_roleid)
    new_roleid = new_roleid or old_roleid
    local url = "/api/account/role/rebindserver"
    local req = self:encode_request({
       appid = self.appid,
       account = account,
       old_roleid = old_roleid,
       new_roleid = new_roleid,
       new_serverid = new_serverid,
    })
    return self:decode_response(self:post(url,req))
end

---换绑账号
--@param[type=int] roleid 角色ID
--@param[type=string] new_account 新账号
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:rebindaccount(roleid,new_account)
    local url = "/api/account/role/rebindaccount"
    local req = self:encode_request({
       appid = self.appid,
       roleid = roleid,
       new_account = new_account,
    })
    return self:decode_response(self:post(url,req))
end

---恢复
--@param[type=int] roleid 角色ID
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:recover_role(roleid)
    local url = "/api/account/role/recover"
    local req = self:encode_request({
       appid = self.appid,
       roleid = roleid,
    })
    return self:decode_response(self:post(url,req))
end

---删除角色
--@param[type=int] roleid 角色ID
--@param[type=bool,optional] forever 是否永久删除
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:delrole(roleid,forever)
    local url = "/api/account/role/del"
    local req = self:encode_request({
       appid = self.appid,
       roleid = roleid,
       forever = forever,
    })
    return self:decode_response(self:post(url,req))
end

---新增角色
--@param[type=string] account 账号
--@param[type=string] serverid 服务器ID(在哪个服创建的角色)
--@param[type=table] role 角色数据
--@param[type=int,opt] roleid 如果指定,表示固定角色ID
--@param[type=string,opt] genrolekey 和roleid不能同时存在,指定时表示递增id存储键,必须和minroleid,maxroleid同时存在
--@param[type=string,opt] minroleid 限定的最小角色ID
--@param[type=string,opt] maxroleid 限定的最大角色ID(不包括此值),区间为[minroleid,maxroleid)
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:addrole(account,serverid,role,roleid,genrolekey,minroleid,maxroleid)
    local url = "/api/account/role/add"
    local req = self:encode_request({
       appid = self.appid,
       account = account,
       serverid = serverid,
       role = cjson.encode(role),
       roleid = roleid,
       genrolekey = genrolekey,
       minroleid = minroleid,
       maxroleid = maxroleid,
    })
    return self:decode_response(self:post(url,req))
end

---获取角色列表
--@param[type=string] account 账号
--@param[type=string,opt] serverid 服务器ID(可选,指定表示角色创建服限定为这个值)
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:rolelist(account,serverid)
    local url = "/api/account/role/list"
    local req = self:encode_request({
       appid = self.appid,
       account = account,
       serverid = serverid,
    })
    return self:decode_response(self:post(url,req))
end

---获取角色
--@param[type=int] roleid 角色ID
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:getrole(roleid)
    local url = "/api/account/role/get"
    local req = self:encode_request({
       appid = self.appid,
       roleid = roleid,
    })
    return self:decode_response(self:post(url,req))
end

---更新角色
--@param[type=int] roleid 角色ID
--@param[type=table] role 角色数据
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:updaterole(roleid,role)
    local url = "/api/account/role/update"
    local req = self:encode_request({
       appid = self.appid,
       roleid = roleid,
       role = cjson.encode(role),
    })
    return self:decode_response(self:post(url,req))
end

---增加服务器
--@param[type=string] serverid 服务器ID
--@param[type=table] server 服务器数据
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:addserver(serverid,server)
    local url = "/api/account/server/add"
    local req = self:encode_request({
       appid = self.appid,
       serverid = serverid,
       server = cjson.encode(server),
    })
    return self:decode_response(self:post(url,req))
end

---删除服务器
--@param[type=string] serverid 服务器ID
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:delserver(serverid)
    local url = "/api/account/server/del"
    local req = self:encode_request({
       appid = self.appid,
       serverid = serverid,
    })
    return self:decode_response(self:post(url,req))
end

---获得服务器
--@param[type=string] serverid 服务器ID
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:getserver(serverid)
    local url = "/api/account/server/get"
    local req = self:encode_request({
       appid = self.appid,
       serverid = serverid,
    })
    return self:decode_response(self:post(url,req))
end

---更新服务器
--@param[type=string] serverid 服务器ID
--@param[type=table] server 服务器数据
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:updateserver(serverid,server)
    local url = "/api/account/server/update"
    local req = self:encode_request({
       appid = self.appid,
       serverid = serverid,
       server = cjson.encode(server),
    })
    return self:decode_response(self:post(url,req))
end

---获取服务器列表
--@param[type=string] version 玩家当前版本
--@param[type=string] platform 平台
--@param[type=string] devicetype 设备类型(如:windows,ios,android等)
--@param[type=string,opt] account 账号
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:serverlist(version,platform,devicetype,account)
    local url = "/api/account/server/list"
    local req = self:encode_request({
       appid = self.appid,
       version = version,
       platform = platform,
       devicetype = devicetype,
       account = account,
    })
    return self:decode_response(self:post(url,req))
end

---校验token
--@param[type=string] account 账号
--@param[type=string] token 认证token
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:checktoken(account,token)
    local url = "/api/account/checktoken"
    local req = self:encode_request({
       appid = self.appid,
       account = account,
       token = token,
    })
    return self:decode_response(self:post(url,req))
end

---账号登录
--@param[type=string] account 账号
--@param[type=string] passwd 密码
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:login(account,passwd)
    local url = "/api/account/login"
    local req = self:encode_request({
       appid = self.appid,
       account = account,
       passwd = passwd,
    })
    return self:decode_response(self:post(url,req))
end

---账号注册
--@param[type=string] account 账号
--@param[type=string] passwd 密码
--@param[type=string] sdk 注册时用的sdk
--@param[type=string] platform 平台
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:register(account,passwd,sdk,platform)
    local url = "/api/account/register"
    local req = self:encode_request({
       appid = self.appid,
       account = account,
       passwd = passwd,
       sdk = sdk,
       platform = platform,
    })
    return self:decode_response(self:post(url,req))
end

---rpc调用
--@param[type=string] module 模块名
--@param[type=string] cmd 命令名
--@param[type=table] args 参数
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cloginserver:rpc(module,cmd,args)
    local url = "/api/rpc"
    local req = self:encode_request({
       appid = self.appid,
       module = module,
       cmd = cmd,
       args = args,
    })
    return self:decode_response(self:post(url,req))
end

return cloginserver
