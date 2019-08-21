local redis = require "skynet.db.redis"
local rediscluster = require "skynet.db.redis.cluster"
local mongo = require "skynet.db.mongo"

local cdbmgr = class("cdbmgr")

function cdbmgr:init()
    self.db_type = skynet.getenv("db_type")
    self.db_is_cluster = skynet.getenv("db_is_cluster")
    self.dbs = {}       -- db_id-> {conf=配置,db=db实例}
end

function cdbmgr:new_db(db_config)
    local db_type = self.db_type
    local db_is_cluster = self.db_is_cluster
    if db_type == "redis" then
        if not db_is_cluster then
            return redis.connect(db_config)
        else
            return rediscluster.new(db_config.startup_nodes,db_config.opt)
        end
    else
        return mongo.client(db_config)
    end
end

function cdbmgr:getdb(db_id)
    db_id = db_id or skynet.getenv("id")
    local ok,obj = gg.sync:once_do(db_id,function ()
        return self:_getdb(db_id)
    end)
    assert(ok,obj)
    local db = obj.db
    local conf = obj.conf
    -- 指定了数据库名?
    if conf.db then
        db = db[conf.db]
    end
    return db
end

function cdbmgr:_getdb(db_id)
    if not self.dbs[db_id] or not self.dbs[db_id].db then
        local conf = self:get_db_conf(db_id)
        local db = self:new_db(conf)
        self.dbs[db_id] = {
            conf = conf,
            db = db,
        }
    end
    return self.dbs[db_id]
end

function cdbmgr:get_db_conf(db_id)
    -- db_nodes中需要存放所有需要连接的db的配置,如果服务器只需要连本服数据库,
    -- 则可以不提供db_nodes,以第二种形式提供本服数据库配置即可
    local db_nodes = skynet.getenv("db_nodes")
    if db_nodes then
        return db_nodes[db_id]
    end
    if db_id == skynet.getenv("id") then
        return skynet.getenv("db_config")
    end
end

function cdbmgr:shutdown()
    for db_id,obj in pairs(self.dbs) do
        local db = obj.db
        obj.db = nil
        if self.db_type == "redis" then
            if self.db_is_cluster then
                db:close_all_connection()
            else
                db:disconnect()
            end
        else
            db:disconnect()
        end
    end
end

return cdbmgr
