local util = require "server.account.util"
local resty_mongo = require "resty.mongol"

local _M = {}

function _M:new(config)
	config = config or util.config().db.config
	local db = resty_mongo:new()
	if config.timeout then
		db:set_timeout(config.timeout)
	end
	local ok,err = db:connect(config.host,config.port)
	assert(ok,err)
	if config.username and config.password then
		ok,err = db:auth(config.username,config.password)
		assert(ok,err)
	end
	return db
end

function _M:close(db)
	db:set_keepalive(10000,100)
end

function _M:pack_doc(doc)
	doc._id = nil
	return doc
end

function _M:pack_docs(docs)
	for i,doc in ipairs(docs) do
		self:pack_doc(doc)
	end
	return docs
end

return _M
