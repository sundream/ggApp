local crypt = require "skynet.crypt"
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


--第一步: [GS2C]发送挑战码challenge(用于校验后续协商出的密钥是否一致)+服务端随机串serverkey
function handshake.pack_challenge(agent,encrypt_key)
	assert(agent.handshake_step == nil)
	agent.handshake_step = 1
	local challenge = nil
	if encrypt_key ~= "nil" then
		challenge = crypt.randomkey()
	else
		agent.handshake_result = "OK"
	end
	local serverkey = crypt.dhexchange(crypt.randomkey())
	agent.challenge = challenge
	agent.serverkey = serverkey
	local msg = handshake.pack_request({
		proto = "GS2C_HandShake_Challenge",
		-- challenge为nil控制客户端不加密
		challenge = challenge,
		serverkey = serverkey,
		linkid = agent.linkid,
	})
	return msg
end

function handshake._do_handshake(agent,msg)
	local request = handshake.unpack_request(msg)
	local proto = request.proto
	assert(not agent.handshake_result)
	if proto == "C2GS_HandShake_ClientKey" then
		--第二步: [C2GS]收到客户端发过来的随机串clientkey,根据clientkey+serverkey计算出密钥
		if agent.handshake_step ~= 1 then
			return false,"skip handshake step 1?"
		end
		agent.handshake_step = 2
		local clientkey = request.clientkey
		local master_linkid = request.master_linkid
		agent.clientkey = clientkey
		agent.master_linkid = tonumber(master_linkid)
		local serverkey = agent.serverkey
		agent.secret = crypt.dhsecret(clientkey,serverkey)
	elseif proto == "C2GS_HandShake_CheckSecret" then
		--第三步: [C2GS]客户端根据clientkey+serverkey计算出相同秘钥,加密challenge后发送给服务器,要求校验秘钥
		if agent.handshake_step ~= 2 then
			return false,"skip handshake step 2?"
		end
		agent.handshake_step = 3
		local challenge = agent.challenge
		local secret = agent.secret
		local client_encrypt = request.encrypt
		local server_encrypt = crypt.hmac64(challenge,secret)
		agent.handshake_result = client_encrypt == server_encrypt and "OK" or "FAIL"
		if agent.handshake_result ~= "OK" then
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

--第四步: [GS2C]发送密钥校验结果
function handshake.pack_result(agent,result)
	assert(agent.handshake_step == 3)
	agent.handshake_step = 4
	local msg = handshake.pack_request({
		proto = "GS2C_HandShake_Result",
		result = result,
	})
	return msg
end

return handshake
