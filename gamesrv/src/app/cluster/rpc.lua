rpc = rpc or {}

function rpc.init()
	-- 开启集群
	local serverid = skynet.getenv("id")
	local cluster_port = tonumber(skynet.getenv("cluster_port")) or serverid
	cluster.open(cluster_port)
end

local MAINSRV_NAME=".main"

function rpc.dispatch(session,source,SOURCE,protoname,cmd,...)
	local request = {...}
	logger.log("debug","cluster","op=recv,session=%s,source=%s,SOURCE=%s,protoname=%s,cmd=%s,request=%s",
		session,source,SOURCE,protoname,cmd,request)
	_G.SOURCE = SOURCE
	local dispatch = rpc.CMD[protoname]
	local response
	if dispatch then
		response = {xpcall(dispatch,onerror,cmd,...)}
	else
		response = {false,"no dispatch"}
	end
	_G.SOURCE = nil
	if session ~= 0 then
		local isok = table.remove(response,1)
		logger.log("debug","cluster","op=resp,session=%s,source=%s,SOURCE=%s,protoname=%s,cmd=%s,request=%s,response=%s,isok=%s",
			session,source,SOURCE,protoname,cmd,request,response,isok)
		if isok then
			skynet.retpack(table.unpack(response))
		else
			skynet.response()(false)
		end
	end
end


rpc.CMD = rpc.CMD or {}
function rpc.register(protoname,dispatch)
	rpc.CMD[protoname] = dispatch
end

rpc.register("rpc",function (cmd,...)
	return call(_G,cmd,...)
end)

rpc.register("playermethod",function (pid,method,...)
	local player = playermgr.getplayer(pid)
	if player then
		return call(player,method,...)
	end
end)

function rpc.call(node,protoname,cmd,...)
	local address
	if type(node) == "string" then
		address = MAINSRV_NAME
	else
		address = node.address
		node = node.node
	end
	assert(node,"nil-node")
	assert(address,"nil-address")
	local SOURCE = {
		node = skynet.getenv("id"),
		address = skynet.self(),
		call = true,
	}
	local request = {...}
	logger.log("debug","cluster","op=call,node=%s,address=%s,SOURCE=%s,protoname=%s,cmd=%s,request=%s",
		node,address,SOURCE,protoname,cmd,request)
	local response = {cluster.call(node,address,"cluster",SOURCE,protoname,cmd,...)}
	logger.log("debug","cluster","op=return,node=%s,address=%s,SOURCE=%s,protoname=%s,cmd=%s,request=%s,response=%s",
		node,address,SOURCE,protoname,cmd,request,response)
	return table.unpack(response)
end

function rpc.pcall(node,protoname,cmd,...)
	return pcall(rpc.call,node,protoname,cmd,...)
end

function rpc.xpcall(node,protoname,cmd,...)
	return xpcall(rpc.call,onerror,node,protoname,cmd,...)
end

function rpc.send(node,protoname,cmd,...)
	local address
	if type(node) == "string" then
		address = MAINSRV_NAME
	else
		address = node.address
		node = node.node
	end
	assert(node,"nil-node")
	assert(address,"nil-address")
	local SOURCE = {
		node = skynet.getenv("id"),
		address = skynet.self(),
	}
	local request = {...}
	logger.log("debug","cluster","op=send,node=%s,address=%s,SOURCE=%s,protoname=%s,cmd=%s,request=%s",
		node,address,SOURCE,protoname,cmd,request)
	return cluster.send(node,address,"cluster",SOURCE,protoname,cmd,...)
end

function __hotfix(oldmod)
	cluster.reload()
	logger.log("info","cluster","op=cluster.reload")
end

return rpc
