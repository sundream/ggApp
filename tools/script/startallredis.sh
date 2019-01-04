#!/bin/sh
# e.g: sh tools/script//startallredis.sh
redis-server ~/db/redis/redis_1/redis.conf

redis-server ~/db/redis/rediscluster_1/redis.conf
redis-server ~/db/redis/rediscluster_2/redis.conf
redis-server ~/db/redis/rediscluster_3/redis.conf
redis-server ~/db/redis/rediscluster_4/redis.conf
redis-server ~/db/redis/rediscluster_5/redis.conf
redis-server ~/db/redis/rediscluster_6/redis.conf
