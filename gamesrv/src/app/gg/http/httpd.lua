local httpd = require "http.httpd"

httpd.webagents = {}

function httpd.start(conf)
	local ip = conf.ip or "0.0.0.0"
	local port = assert(conf.port)
	local watchdog = assert(conf.watchdog)
	local msg_max_len = conf.msg_max_len or 8*1024
	local agent_num = conf.agent_num or 16
	skynet.start(function ()
		for i=1,agent_num do
			httpd.webagents[i] = skynet.newservice("gg/service/httpd")
		end
		local balance = 1
		local id = socket.listen(ip,port)
		skynet.error(string.format("Listen web port %s:%s",ip,port))
		socket.start(id , function(linkid, addr)
			skynet.error(string.format("%s connected, pass it to agent :%08x", addr, httpd.webagents[balance]))
			skynet.send(httpd.webagents[balance], "lua", watchdog,linkid,ip,port,msg_max_len)
			balance = balance + 1
			if balance > agent_num then
				balance = 1
			end
		end)
	end)
end
