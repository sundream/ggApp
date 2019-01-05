local rediscluster = require "skynet.db.redis.cluster"
local mongo = require "skynet.db.mongo"

dbmgr = dbmgr or {}

function dbmgr.init(db_type)
	dbmgr.db = nil
	dbmgr.db_type = db_type
end

function dbmgr.getdb()
	-- 所有服务器共用单个redis集群
	if dbmgr.db then
		return dbmgr.db
	end
	local id = "db"
	if dbmgr.db_type == "redis" then
		local ok,db = sync.once.Do(id,function ()
			local db = rediscluster.new({
						{host="127.0.0.1",port=7001},
						{host="127.0.0.1",port=7002},
						{host="127.0.0.1",port=7003},
					},{
						max_connections = 256,
						read_slave = true,
						auth = nil,
						db = 0,
					})
			dbmgr.db = db
			return db
		end)
		assert(ok,db)
		return db
	else
		local ok,db = sync.once.Do(id,function ()
			local db = mongo.client({
				rs = {
					{host = "127.0.0.1",port = 29017,username=nil,password=nil,authmod=nil,authdb=nil},
					{host = "127.0.0.1",port = 29018},
					{host = "127.0.0.1",port = 29019},
				}
			})
			dbmgr.db = db
			return db
		end)
		assert(ok,db)
		return db
	end
end

function dbmgr.disconnect()
	if not dbmgr.db then
		return
	end
	if dbmgr.db_type == "redis" then
		dbmgr.db:close_all_connection()
	else
		dbmgr.db:disconnect()
	end
end

return dbmgr
