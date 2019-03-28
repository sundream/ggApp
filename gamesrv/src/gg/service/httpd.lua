local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

local function response(linkid, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(linkid), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("linktype=http,linkid=%s,err=%s",linkid,err))
	end
end

skynet.start(function()
	skynet.dispatch("lua", function (session,source,watchdog,linkid,ip,port,msg_max_len)
		socket.start(linkid)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(linkid), msg_max_len)
		if code then
			if code ~= 200 then
				response(linkid, code)
			else
				local agent = {
					linkid = linkid,
					ip = ip,
					port = port,
					method = method,
				}
				if header["x-real-ip"] then
					agent.ip = header["x-real-ip"]
				end
				local uri, query = urllib.parse(url)
				-- uri may include http://host:port ?
				if uri:sub(1,1) ~= "/" then
					uri = string.match(uri,"http[s]?://.-(/.+)")
				end
				-- 使用call保证http回复发送出去后才关闭连接!
				local ok = pcall(skynet.call,watchdog,"lua","service","http",agent,uri,header,query,body)
				if not ok then
					-- server internal error
					response(linkid,500)
				end
			end
		else
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(linkid)
	end)
end)
