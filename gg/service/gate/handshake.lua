local crypt = require "skynet.crypt"
local chandshake = {}
chandshake.__index = chandshake

function chandshake.new()
    local self = {}
    self.step = 0
    self.result = nil
    self.encryptkey = nil
    self.master_linkid = nil            -- 绑定的主连接ID
    return setmetatable(self,chandshake)
end

function chandshake:unpack_request(msg)
    local tbl = {}
    for m in msg:gmatch("([^,]+)") do
        local k,v = m:match("([^|]+)|([^|]+)")
        k = crypt.base64decode(k)
        v = crypt.base64decode(v)
        tbl[k] = v
    end
    return tbl
end

function chandshake:pack_request(tbl)
    local list = {}
    for k,v in pairs(tbl) do
        table.insert(list,string.format("%s|%s",crypt.base64encode(k),crypt.base64encode(v)))
    end
    return table.concat(list,",")
end


--第一步: [GS2C]发送挑战码challenge(用于校验后续协商出的密钥是否一致)+服务端随机串serverkey
function chandshake:pack_challenge(linkid,encrypt_algorithm)
    assert(self.step == 0)
    self.step = 1
    local challenge = nil
    if encrypt_algorithm ~= "nil" then
        challenge = crypt.randomkey()
    else
        self.result = "OK"
    end
    local serverkey = crypt.dhexchange(crypt.randomkey())
    self.challenge = challenge
    self.serverkey = serverkey
    local msg = self:pack_request({
        proto = "GS2C_HandShake_Challenge",
        -- challenge为nil控制客户端不加密
        challenge = challenge,
        serverkey = serverkey,
        linkid = linkid,
        encrypt_algorithm = encrypt_algorithm,
    })
    return msg
end

function chandshake:_do_handshake(msg)
    local request = self:unpack_request(msg)
    local proto = request.proto
    assert(not self.result)
    if proto == "C2GS_HandShake_ClientKey" then
        --第二步: [C2GS]收到客户端发过来的随机串clientkey,根据clientkey+serverkey计算出密钥
        if self.step ~= 1 then
            return false,"skip handshake step 1?"
        end
        self.step = 2
        local clientkey = request.clientkey
        local master_linkid = request.master_linkid
        self.clientkey = clientkey
        self.master_linkid = tonumber(master_linkid)
        local serverkey = self.serverkey
        self.encryptkey = crypt.dhsecret(clientkey,serverkey)
    elseif proto == "C2GS_HandShake_CheckSecret" then
        --第三步: [C2GS]客户端根据clientkey+serverkey计算出相同秘钥,加密challenge后发送给服务器,要求校验秘钥
        if self.step ~= 2 then
            return false,"skip handshake step 2?"
        end
        self.step = 3
        local challenge = self.challenge
        local encryptkey = self.encryptkey
        local client_encrypt = request.encrypt
        local server_encrypt = crypt.hmac64(challenge,encryptkey)
        self.result = client_encrypt == server_encrypt and "OK" or "FAIL"
        if self.result ~= "OK" then
            return false,"check secret fail"
        end
    else
        return false,"handshake first!"
    end
    return true
end

function chandshake:do_handshake(msg)
    local call_ok,ok,err = pcall(self._do_handshake,self,msg)
    if not call_ok then
        err = ok
        ok = false
    end
    return ok,err
end

--第四步: [GS2C]发送密钥校验结果
function chandshake:pack_result()
    assert(self.step == 3)
    self.step = 4
    local msg = self:pack_request({
        proto = "GS2C_HandShake_Result",
        result = self.result
    })
    return msg
end

--- 加密
--@param[type=string] message 铭文
--@return[type=string] 密文
function chandshake:encrypt(message)
    local chipher = message
    if self.encryptkey then
        chipher = crypt.xor_str(chipher,self.encryptkey)
    end
    return chipher
end

--- 解密
--@param[type=string] chipher 密文
--@param[type=string] 明文
function chandshake:decrypt(chipher)
    local message = chipher
    if self.encryptkey then
        message = crypt.xor_str(message,self.encryptkey)
    end
    return message
end

return chandshake
