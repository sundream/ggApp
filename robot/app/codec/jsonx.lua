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
