#!/bin/sh
usage="Usage:
	sh tools/stopallredis.sh -a 数据库密码(默认为redispwd)
	e.g: sh tools/stopallredis.sh
	e.g: sh tools/stopallredis.sh -a redispwd"

password="redispwd"
while getopts a: opt; do
	case "$opt" in
	a)
		password="$OPTARG";;
	[?])
		echo $usage
		exit 0;;
	esac
done
redis-cli -p 6385 -a $password shutdown
ports="7001 7002 7003 7004 7005 7006"
for port in $ports; do
	redis-cli -p $port shutdown
done
