local crypt = require "skynet.crypt"

local HandShake = {}
HandShake.__index = HandShake

function HandShake.new(agent,master_linkid)
    local self = {}
    self.agent = agent
    self.step = 0
    self.result = nil
    self.encryptKey = nil
    self.linkid = nil                   -- 本连接服务端连接ID
    self.master_linkid = master_linkid  -- 绑定的主连接ID(可选)
    return setmetatable(self,HandShake)
end

function HandShake:packRequest(tbl)
    local list = {}
    for k,v in pairs(tbl) do
        k = crypt.base64encode(k)
        v = crypt.base64encode(v)
        -- base64编码不会生成"|",但是会生成"="
        table.insert(list,string.format("%s|%s",k,v))
    end
    return table.concat(list,",")
end

function HandShake:unpackRequest(message)
    local tbl = {}
    for m in message:gmatch("([^,]+)") do
        local k,v = m:match("([^|]+)|([^|]+)")
        k = crypt.base64decode(k)
        v = crypt.base64decode(v)
        tbl[k] = v
    end
    return tbl
end

function HandShake:_doHandShake(message)
    local request = self:unpackRequest(message)
    local proto = request.proto
    if proto == "GS2C_HandShake_Challenge" then
        if self.step ~= 0 then
            return false,"challenge first"
        end
        -- 第一步: [GS2C]收到服务端发过来的挑战码challenge(用于校验后续协商出的密钥是否一致)+服务端随机串serverkey
        self.step = 1
        local challenge = request.challenge
        local serverkey = request.serverkey
        local linkid = request.linkid
        self.linkid = linkid
        if not challenge then
            self.encryptKey = nil
            self.result = "OK"
            return true
        end
        local clientkey = crypt.randomkey()
        local encryptKey = crypt.dhsecret(clientkey,serverkey)
        self.encryptKey = encryptKey
        -- 第二步: [C2GS]发送随机串clientkey
        self.step = 2
        local msg = self:packRequest({
            proto = "C2GS_HandShake_ClientKey",
            clientkey = clientkey,
            master_linkid = self.master_linkid,
        })
        self.agent:rawSend(msg)
        -- 第三步: [C2GS]客户端根据clientkey+serverkey计算出相同秘钥,加密challenge后发送给服务器,要求校验秘钥
        self.step = 3
        local encrypt = crypt.hmac64(challenge,encryptKey)
        local msg = self:packRequest({
            proto = "C2GS_HandShake_CheckSecret",
            encrypt = encrypt,
        })
        self.agent:rawSend(msg)
    elseif proto == "GS2C_HandShake_Result" then
        if self.step ~= 3 then
            return false,"skip handshake step 3?"
        end
        -- 第四步: [GS2C]发送密钥校验结果
        self.step = 4
        local result = request.result
        self.result = result
        if result == "FAIL" then
            return false,"check encryptKey fail"
        end
    else
        return false,"handshake first!"
    end
    return true
end

--- 握手
--@param[type=string] message 收到的握手包
--@return[type=bool] ok 握手是否成功
--@return[type=string] err 失败原因
function HandShake:doHandShake(message)
    local callOk,ok,err = pcall(self._doHandShake,self,message)
    if not callOk then
        err = ok
        ok = false
    end
    return ok,err
end

--- 加密
--@param[type=string] message 铭文
--@return[type=string] 密文
function HandShake:encrypt(message)
    local chipher = message
    if self.encryptKey then
        chipher = crypt.xor_str(chipher,self.encryptKey)
    end
    return chipher
end

--- 解密
--@param[type=string] chipher 密文
--@param[type=string] 明文
function HandShake:decrypt(chipher)
    local message = chipher
    if self.encryptKey then
        message = crypt.xor_str(message,self.encryptKey)
    end
    return message
end

return HandShake
