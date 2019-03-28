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
	logger.logf("debug","http","op=send,linkid=%s,status=%s,body=%s,header=%s",
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

--- 扩展httpc.post,支持传入header,并根据header中指定content-type对form编码
--@param[type=string] host 主机地址,如:127.0.0.1:8887
--@param[type=string] url url
--@param[type=string|table] form 请求的body数据,传table时默认根据header中指定的content-type编码
--@param[type=table,opt] header 请求头,默认为application/json编码
--@param[type=table,opt] recvheader 如果指定时会记录回复收到的header信息
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

return httpc
