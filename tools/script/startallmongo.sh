#!/bin/sh
# e.g: sh startallmongo.sh

configsvr="configsvr_1 configsvr_2 configsvr_3"
shard="shard0001_1 shard0001_2 shard0001_3 shard0002_1 shard0002_2 shard0002_3 shard0003_1 shard0003_2 shard0003_3"
router="router_1 router_2 router_3"

for name in $configsvr; do
	mkdir -p ~/db/mongodb/$name/data
	mongod -f ~/db/mongodb/$name/mongodb.conf &
done
sleep 5
for name in $shard; do
	mkdir -p ~/db/mongodb/$name/data
	mongod -f ~/db/mongodb/$name/mongodb.conf &
done
sleep 5
for name in $router; do
	mkdir -p ~/db/mongodb/$name/data
	mongos -f ~/db/mongodb/$name/mongodb.conf &
done
