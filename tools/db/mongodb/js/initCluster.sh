#!/bin/sh
# sh ~/db/mongodb/js/initCluster.sh
# 建立副本集
mongo --host 127.0.0.1 --port 28017 ~/db/mongodb/js/initReplSet_configsvr.js
mongo --host 127.0.0.1 --port 27017 ~/db/mongodb/js/initReplSet_shard0001.js
mongo --host 127.0.0.1 --port 27027 ~/db/mongodb/js/initReplSet_shard0002.js
mongo --host 127.0.0.1 --port 27037 ~/db/mongodb/js/initReplSet_shard0003.js

# 告知router各个shard的信息
mongo --host 127.0.0.1 --port 29017 ~/db/mongodb/js/addShard.js
# 配置各个集合的分片规则
mongo --host 127.0.0.1 --port 29017 ~/db/mongodb/js/enableSharding.js
