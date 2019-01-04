#!/bin/sh
# e.g: sh tools/script/startallmongo.sh
mongod -f ~/db/mongodb/configsvr_1/mongodb.conf &
mongod -f ~/db/mongodb/configsvr_2/mongodb.conf &
mongod -f ~/db/mongodb/configsvr_3/mongodb.conf &
sleep 5

mongod -f ~/db/mongodb/shard0001_1/mongodb.conf &
mongod -f ~/db/mongodb/shard0001_2/mongodb.conf &
mongod -f ~/db/mongodb/shard0001_3/mongodb.conf &
mongod -f ~/db/mongodb/shard0002_1/mongodb.conf &
mongod -f ~/db/mongodb/shard0002_2/mongodb.conf &
mongod -f ~/db/mongodb/shard0002_3/mongodb.conf &
mongod -f ~/db/mongodb/shard0003_1/mongodb.conf &
mongod -f ~/db/mongodb/shard0003_2/mongodb.conf &
mongod -f ~/db/mongodb/shard0003_3/mongodb.conf &
sleep 5

mongos -f ~/db/mongodb/router_1/mongodb.conf &
mongos -f ~/db/mongodb/router_2/mongodb.conf &
mongos -f ~/db/mongodb/router_3/mongodb.conf &
