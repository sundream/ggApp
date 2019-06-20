---json协议编码模块
--@script gg.codec.jsonx
--@author sundream
--@release 2019/6/20 10:30:00
--@usage
--一个完整的json包格式如下
--{
--  "type" : 类别,1--请求包,2--回复包,
--  "cmd" : 指令(协议名),
--  "args" : 参数(具体和协议定义有关),
--  "session" : rpc会话ID,无需对方回复时发0,否则,保证唯一,
--  "ud" : 用户自定义数据
--}

local cjson = require "cjson"
-- 空表编码成[]
cjson.encode_empty_table_as_object(false)

local jsonx = {}

function jsonx.new(conf)
    local self = {}
    return setmetatable(self,{__index=jsonx})
end

function jsonx:reload()
end

function jsonx:pack_message(message)
    return cjson.encode(message)
end

function jsonx:unpack_message(msg)
    return cjson.decode(msg)
end

return jsonx
