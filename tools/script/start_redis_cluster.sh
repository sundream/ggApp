#!/bin/sh
# e.g: sh start_redis_cluster.sh

rediscluster="rediscluster_1 rediscluster_2 rediscluster_3 rediscluster_4 rediscluster_5 rediscluster_6"

for name in $rediscluster; do
	redis-server ~/db/redis/$name/redis.conf
done
