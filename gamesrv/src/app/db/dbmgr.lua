local redis = require "skynet.db.redis"
local rediscluster = require "skynet.db.redis.cluster"
local mongo = require "skynet.db.mongo"

dbmgr = dbmgr or {}

function dbmgr.init(conf)
	conf = conf or {}
	dbmgr.db = nil
	dbmgr.db_type = assert(conf.db_type or skynet.getenv("db_type"))
	dbmgr.db_config = assert(conf.db_config or skynet.getenv("db_config"))
	dbmgr.db_is_cluster = conf.db_is_cluster or skynet.getenv("db_is_cluster")
end

function dbmgr.getdb()
	-- 所有服务器共用单个redis集群
	if dbmgr.db then
		return dbmgr.db
	end
	local id = "db"
	if dbmgr.db_type == "redis" then
		if not dbmgr.db_is_cluster then
			local ok,db = sync.once.Do(id,function ()
				local db = redis.connect(dbmgr.db_config)
				dbmgr.db = db
				return db
			end)
			assert(ok,db)
			return db
		else
			local ok,db = sync.once.Do(id,function ()
				local db = rediscluster.new(dbmgr.db_config.startup_nodes,dbmgr.db_config.opt)
				dbmgr.db = db
				return db
			end)
			assert(ok,db)
			return db
		end
	else
		local ok,db = sync.once.Do(id,function ()
			local db = mongo.client(dbmgr.db_config)
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
		if dbmgr.db_is_cluster then
			dbmgr.db:close_all_connection()
		else
			dbmgr.db:disconnect()
		end
	else
		dbmgr.db:disconnect()
	end
end

return dbmgr
