#!/bin/sh
# e.g: sh stop_mongo_cluster.sh
# See https://docs.mongodb.com/manual/tutorial/manage-mongodb-processes
pkill -2 mongos
pkill -2 mongod
