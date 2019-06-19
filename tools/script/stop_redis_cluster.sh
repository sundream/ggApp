#!/bin/sh
usage="Usage:
	sh stop_redis_cluster.sh\n
	e.g: sh stop_redis_cluster.sh\n
	e.g: sh stop_redis_cluster.sh -i 127.0.0.1"

host="127.0.0.1"
while getopts a:i: opt; do
	case "$opt" in
	i)
		host="$OPTARG";;
	[?])
		echo $usage
		exit 0;;
	esac
done
ports="7001 7002 7003 7004 7005 7006"
for port in $ports; do
	redis-cli -h $host -p $port shutdown
done
