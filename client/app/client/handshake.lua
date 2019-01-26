local crypt = require "crypt"
local handshake = {}

function handshake.unpack_request(msg)
	local tbl = {}
	for m in msg:gmatch("([^,]+)") do
		local k,v = m:match("([^|]+)|([^|]+)")
		k = crypt.base64decode(k)
		v = crypt.base64decode(v)
		tbl[k] = v
	end
	return tbl
end

function handshake.pack_request(tbl)
	local list = {}
	for k,v in pairs(tbl) do
		table.insert(list,string.format("%s|%s",crypt.base64encode(k),crypt.base64encode(v)))
	end
	return table.concat(list,",")
end

function handshake._do_handshake(agent,msg)
	local request = handshake.unpack_request(msg)
	local proto = request.proto
	assert(not agent.handshake_result)
	if proto == "GS2C_HandShake_Challenge" then
		--第一步: [GS2C]发送挑战码challenge(用于校验后续协商出的密钥是否一致)+服务端随机串serverkey
		if agent.handshake_step ~= nil then
			return false,"challenge first"
		end
		agent.handshake_step = 1
		local challenge = request.challenge
		local serverkey = request.serverkey
		local linkid = request.linkid
		agent.sessionid = linkid
		if not challenge then
			agent.secret = nil
			agent.handshake_result = "OK"
			return true
		end
		local clientkey = crypt.randomkey()
		local secret = crypt.dhsecret(clientkey,serverkey)
		agent.secret = secret
		--第二步: [C2GS]收到客户端发过来的随机串clientkey,根据clientkey+serverkey计算出密钥
		agent.handshake_step = 2
		local msg = handshake.pack_request({
			proto="C2GS_HandShake_ClientKey",
			clientkey = clientkey,
			master_linkid = agent.master_linkid,
		})
		agent:send(msg)
		--第三步: [C2GS]客户端根据clientkey+serverkey计算出相同秘钥,加密challenge后发送给服务器,要求校验秘钥
		agent.handshake_step = 3
		local encrypt = crypt.hmac64(challenge,secret)
		local msg = handshake.pack_request({
			proto = "C2GS_HandShake_CheckSecret",
			encrypt = encrypt,
		})
		agent:send(msg)
	elseif proto == "GS2C_HandShake_Result" then
		if agent.handshake_step ~= 3 then
			return false,"skip handshake step 3?"
		end
		--第四步: [GS2C]发送密钥校验结果
		agent.handshake_step = 4
		local result = request.result
		agent.handshake_result = result
		if result == "FAIL" then
			return false,"check secret fail"
		end
	else
		return false,"handshake first!"
	end
	return true
end

function handshake.do_handshake(agent,msg)
	local call_ok,ok,errmsg = pcall(handshake._do_handshake,agent,msg)
	if not call_ok then
		errmsg = ok
		ok = false
	end
	return ok,errmsg
end

return handshake
