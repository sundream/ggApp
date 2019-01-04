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
