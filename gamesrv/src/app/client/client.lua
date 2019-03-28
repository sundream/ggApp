client = client or {}

function client.init(conf)
	client.tcp_gate = conf.tcp_gate
	client.websocket_gate = conf.websocket_gate
	client.kcp_gate = conf.kcp_gate
	client.session = 0
	client.sessions = {}
	-- 连线对象
	client.linkobjs = ccontainer.new()
end

function client.onconnect(linktype,linkid,addr)
	local linkobj = clinkobj.new(linktype,linkid,addr)
	client.addlinkobj(linkobj)
end

-- 客户端连接断开,被动掉线
function client.onclose(linkid)
	local linkobj = client.getlinkobj(linkid)
	if not linkobj then
		return
	end
	local pid = linkobj.pid
	local player = playermgr.getplayer(pid)
	if player then
		player:disconnect("onclose")
	end
end

function client.onmessage(linkid,message)
	local linkobj = client.getlinkobj(linkid)
	if not linkobj then
		return
	end
	logger.logf("debug","client","op=recv,linkid=%s,linktype=%s,ip=%s,port=%s,pid=%s,message=%s",
		linkid,linkobj.linktype,linkobj.ip,linkobj.port,linkobj.pid,message)
	local player
	if linkobj.pid then
		player = assert(playermgr.getonlineplayer(linkobj.pid))
	else
		player = linkobj
	end
	if message.type == "REQUEST" then
		local func = net.cmd(message.proto)
		if func then
			func(player,message)
		end
	else
		local session = assert(message.session)
		local callback = client.sessions[session]
		if callback then
			callback(player,message)
		end
	end
end

function client._sendpackage(linkid,proto,request,callback)
	local linkobj = client.getlinkobj(linkid)
	if not linkobj then
		return
	end
	local is_response = type(callback) == "number"
	local message
	if not is_response then
		local session
		if callback then
			client.session = client.session + 1
			session = client.session
			client.sessions[session] = callback
		end
		message = {
			type = "REQUEST",
			session = session,
			proto = proto,
			request = request
		}
	else
		local session = callback
		local response = request
		message = {
			type = "RESPONSE",
			session = session,
			proto = proto,
			response = response,
		}
	end
	local pid = linkobj.pid
	local linktype = linkobj.linktype
	if not pid and linkobj.master then
		pid = linkobj.master.pid
	end
	logger.logf("debug","client","op=send,linkid=%s,linktype=%s,ip=%s,port=%s,pid=%s,message=%s",
		linkid,linktype,linkobj.ip,linkobj.port,pid,message)
	if linktype == "tcp" then
		skynet.send(client.tcp_gate,"lua","write",linkid,message)
	elseif linktype == "kcp" then
		skynet.send(client.kcp_gate,"lua","write",linkid,message)
	elseif linktype == "websocket" then
		skynet.send(client.websocket_gate,"lua","write",linkid,message)
	end
end

-- linkobj格式 table:linkobj number: pid
function client.send_request(linkobj,proto,request,callback)
	if type(linkobj) == "number" then
		local player = playermgr.getplayer(linkobj)
		linkobj = player.linkobj
	end
	if not linkobj then
		return
	end
	client._sendpackage(linkobj.linkid,proto,request,callback)
end

client.sendpackage = client.send_request

function client.send_response(linkobj,proto,response,session)
	if type(linkobj) == "number" then
		local player = playermgr.getplayer(linkobj)
		linkobj = player.linkobj
	end
	if not linkobj then
		return
	end
	client._sendpackage(linkobj.linkid,proto,response,session)
end

function client.dispatch(session,source,cmd,...)
	if cmd == "onconnect" then
		client.onconnect(...)
	elseif cmd == "onclose" then
		client.onclose(...)
	elseif cmd == "onmessage" then
		client.onmessage(...)
	elseif cmd == "slaveof" then
		client.slaveof(...)
	end
end

function client.getlinkobj(linkid)
	return client.linkobjs:get(linkid)
end

function client.addlinkobj(linkobj)
	local linkid = assert(linkobj.linkid)
	return client.linkobjs:add(linkobj,linkid)
end

function client.dellinkobj(linkid)
	local linkobj = client.linkobjs:del(linkid)
	if linkobj then
		if linkobj.linktype == "tcp" then
			skynet.send(client.tcp_gate,"lua","close",linkid)
		elseif linkobj.linktype == "websocket" then
			skynet.send(client.websocket_gate,"lua","close",linkid)
		else
			assert(linkobj.linktype == "kcp")
			skynet.send(client.kcp_gate,"lua","close",linkid)
		end
		if linkobj.slave then
			client.dellinkobj(linkobj.slave.linkid)
		elseif linkobj.master then
			client.unbind_slave(linkobj.master)
		end
	end
	return linkobj
end

function client.slaveof(master_linkid,slave_linkid)
	local master_linkobj = client.getlinkobj(master_linkid)
	local slave_linkobj = client.getlinkobj(slave_linkid)
	if not (master_linkobj and slave_linkobj) then
		return
	end
	assert(master_linkobj.slave == nil)
	assert(slave_linkobj.master == nil)
	master_linkobj.slave = slave_linkobj
	slave_linkobj.master = master_linkobj
end

function client.unbind_slave(master_linkobj)
	local slave_linkobj = master_linkobj.slave
	if not slave_linkobj then
		return
	end
	assert(slave_linkobj.master == master_linkobj)
	master_linkobj.slave = nil
	slave_linkobj.master = nil
end

function client.reload_proto()
	if client.tcp_gate then
		skynet.send(client.tcp_gate,"lua","reload")
	end
	if client.websocket_gate then
		skynet.send(client.websocket_gate,"lua","reload")
	end
	if client.kcp_gate then
		skynet.send(client.kcp_gate,"lua","reload")
	end
end

function client.forward(proto,address)
	if client.tcp_gate then
		skynet.send(client.tcp_gate,"lua","forward",proto,address)
	end
	if client.websocket_gate then
		skynet.send(client.websocket_gate,"lua","forward",proto,address)
	end
	if client.kcp_gate then
		skynet.send(client.kcp_gate,"lua","forward",proto,address)
	end
end

function client.http_onmessage(linkobj,uri,header,query,body)
	linkobj.method = string.lower(linkobj.method)
	logger.logf("debug","http","op=recv,linkid=%s,ip=%s,port=%s,method=%s,uri=%s,header=%s,query=%s,body=%s",
		linkobj.linkid,linkobj.ip,linkobj.port,linkobj.method,uri,header,query,body)

	local handler = net.http_cmd(uri)
	if handler then
		local func = handler[linkobj.method]
		if func then
			func(linkobj,header,query,body)
		else
			-- method not implemented
			httpc.response(linkobj.linkid,501)
		end
	else
		-- not found
		httpc.response(linkobj.linkid,404)
	end
	skynet.ret(nil)
end

return client
