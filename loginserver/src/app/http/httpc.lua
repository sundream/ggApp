-- 扩展httpc
httpc.answer = require "app.http.answer"

function httpc.signature(str,secret)
    if type(str) == "table" then
        str = table.ksort(str,"&",{sign=true})
    end
    return crypt.base64encode(crypt.hmac_sha1(secret,str))
end

function httpc.check_signature(sign,str,secret)
    -- 密钥配置成nocheck,则不检查签名(https通信时可能会这样做)
    if secret == "nocheck" then
        return true
    end
    if skynet.getenv("env") == "dev" and sign == "debug" then
        return true
    end
    if httpc.signature(str,secret) ~= sign then
        return false
    end
    return true
end

function httpc.make_request(request,secret)
    secret = secret
    request.sign = httpc.signature(request,secret)
    return request
end

function httpc.unpack_response(response)
    response = cjson.decode(response)
    return response
end

-- 回复一个http请求
function httpc.response(linkid,status,body,header)
    if not header then
        header = {}
    end
    -- 小游戏客户端要求加这些字段
    header["Access-Control-Allow-Origin"] = "*"
    header["Access-Control-Allow-Headers"] = "X-Requested-With"
    header["Access-Control-Allow-Methods"] = "PUT,POST,GET,DELETE,OPTIONS"
    header["X-Powered-By"] = " 3.2.1"

    logger.logf("debug","http","op=send,linkid=%s,status=%s,body=%s,header=%s",
        linkid,status,body,header)
    local ok,err = httpd.write_response(sockethelper.writefunc(linkid),status,body,header)
    if not ok then
        skynet.error(string.format("op=httpc.response,linktype=http,linkid=%s,err=%s",linkid,err))
    end
end

-- 以json格式回复一个http请求
function httpc.response_json(linkid,status,body,header)
    if header then
        if not header["content-type"] then
            header["content-type"] = "application/json;charset=utf-8"
        end
    end
    if body and type(body) == "table" then
        body = cjson.encode(body)
    end
    httpc.response(linkid,status,body,header)
end

--- 扩展httpc.post,支持传入header,并根据header中指定content-type对form编码
--@param[type=string] host 主机地址,如:127.0.0.1:8885
--@param[type=string] url url
--@param[type=string|table] form 请求的body数据,传table时默认根据header中指定的content-type编码
--@param[type=table,opt] header 请求头,默认为application/json编码
--@param[type=table,opt] recvheader 如果指定时会记录回复收到的header信息
--@return[type=int] status 状态码
--@return[type=string] response 回复数据
function httpc.postx(host,url,form,header,recvheader)
    if not header then
        header = {
            ["content-type"] = "application/json;charset=utf-8"
        }
    end
    local content_type = header["content-type"]
    local body
    if string.find(content_type,"application/json") then
        if type(form) == "table" then
            body = cjson.encode(form)
        else
            body = form
        end
    else
        assert(string.find(content_type,"application/x-www-form-urlencoded"))
        if type(form) == "table" then
            body = string.urlencode(form)
        else
            body = form
        end
    end
    assert(type(body) == "string")
    return httpc.request("POST", host, url, recvheader, header, body)

end

---发送http/https请求
--@param[type=string] url url
--@param[type=table] get get请求参数
--@param[type=table|string] post post请求参数,存在该参数表示POST请求,否则为GET请求
--@param[type=bool,opt] no_replay 是否关心对方回复,true--不关心,false--关心,默认关心对方回复
--@param[type=table,opt] header http请求头
--@return[type=number] status http状态码,为0时表示超时返回,可能是域名解析超时(在/etc/hosts中增加域名解析即可)
--@return[type=string] response 回复数据
function httpc.req(url,get,post,no_reply,header)
    if not httpc.webclient_address then
        httpc.webclient_address = skynet.uniqueservice("webclient")
    end
    local address = httpc.webclient_address
    if not header then
        header = {
            ["content-type"] = "application/json;charset=utf-8",
        }
    end
    if no_reply then
        skynet.send(address,"lua","request",url,get,post,no_reply,header)
    else
        local starttime = skynet.now()
        local isok,response,info = skynet.call(address,"lua","request",url,get,post,no_reply,header)
        if info.response_code == 0 then
            skynet.error(string.format("op=httpc.req,linktype=http,url=%s,isok=%s,code=%s,response=%s,costtime=%s",url,isok,info.response_code,response,skynet.now()-starttime))
        end
        return info.response_code,response
    end
end

return httpc
