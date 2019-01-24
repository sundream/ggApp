-- 扩展httpc
httpc.answer = require "app.gg.http.answer"

function httpc.signature(str,secret)
	if type(str) == "table" then
		str = table.ksort(str,"&",{sign=true})
	end
	return crypt.base64encode(crypt.hmac_sha1(secret,str))
end

function httpc.make_request(request,secret)
	secret = secret or "secret"
	request.sign = httpc.signature(request,secret)
	return request
end

function httpc.unpack_response(response)
	response = cjson.decode(response)
	return response
end

-- 回复一个http请求
function httpc.response(linkid,status,body,header)
	logger.log("debug","http","op=send,linkid=%s,status=%s,body=%s,header=%s",
		linkid,status,body,header)
	local ok,err = httpd.write_response(sockethelper.writefunc(linkid),status,body,header)
	if not ok then
		skynet.error(string.format("linktype=http,linkid=%s,err=%s",linkid,err))
	end
end

-- 以json格式回复一个http请求
function httpc.response_json(linkid,status,body,header)
	if header and not header["content-type"] then
		header["content-type"] = "application/json;charset=utf-8"
	end
	if body then
		body = cjson.encode(body)
	end
	httpc.response(linkid,status,body,header)
end

---发送http/https请求
--@param[type=string] url url
--@param[type=table] get get请求参数
--@param[type=table] post post请求参数,存在该参数表示POST请求,否则为GET请求
--@return[type=number] status http状态码
--@return[type=string] response 回复数据
function httpc.req(url,get,post,no_reply)
	local address = httpc.webclient_address or ".webclient"
	if no_reply then
		skynet.send(address,"lua","request",url,get,post,no_reply)
	else
		local isok,response,info = skynet.call(address,"lua","request",url,get,post,no_reply)
		return info.response_code,response
	end
end
