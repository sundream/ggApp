#!/bin/sh
usage="Usage:
	sh stopallredis.sh -a 数据库密码(默认为redispwd)\n
	e.g: sh stopallredis.sh\n
	e.g: sh stopallredis.sh -a redispwd -i 127.0.0.1"

password="redispwd"
host="127.0.0.1"
while getopts a:i: opt; do
	case "$opt" in
	a)
		password="$OPTARG";;
	i)
		host="$OPTARG";;
	[?])
		echo $usage
		exit 0;;
	esac
done
redis-cli -h $host -p 6385 -a $password shutdown
ports="7001 7002 7003 7004 7005 7006"
for port in $ports; do
	redis-cli -h $host -p $port shutdown
done
