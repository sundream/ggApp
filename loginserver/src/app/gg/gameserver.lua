local cgameserver = class("cgameserver")

---cgameserver.new调用的构造函数
--@usage
--local loginserver = gg.class.cgameserver.new({
--  host = 游戏服ip:port,
--  appkey = 应用对应的加密键,
--})
function cgameserver:init(conf)
    self.host = assert(conf.host)
    self.appkey = assert(conf.appkey)
end

function cgameserver:signature(str)
    if type(str) == "table" then
        str = table.ksort(str,"&",{sign=true})
    end
    return crypt.base64encode(crypt.hmac_sha1(self.appkey,str))
end

function cgameserver:encode_request(request)
    request.sign = self:signature(request)
    return cjson.encode(request)
end

function cgameserver:decode_response(status,response)
    if status ~= 200 then
        return status,response
    end
    return status,cjson.decode(response)
end

function cgameserver:post(url,req)
    return httpc.postx(self.host,url,req)
end

---rpc调用
--@param[type=string] module 模块名
--@param[type=string] cmd 命令名
--@param[type=table] args 参数
--@return[type=int] status 返回的状态码
--@return[type=string] response 回复数据
function cgameserver:rpc(module,cmd,args)
    local url = "/api/rpc"
    local req = self:encode_request({
       module = module,
       cmd = cmd,
       args = cjson.encode(args or {}),
    })
    return self:decode_response(self:post(url,req))
end

return cgameserver
