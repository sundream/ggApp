local cjson = require "cjson"

jsonx = jsonx or {}
jsonx.__index = jsonx

function jsonx.new(conf)
	local self = {}
	return setmetatable(self,jsonx)
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
