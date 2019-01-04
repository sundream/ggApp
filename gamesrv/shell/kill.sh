#!/bin/sh

status=`sh status.sh`
if [ "$status" != "start" ]; then
	echo "aready stop"
	exit;
fi
pidfile=../skynet/skynet.pid
kill -9 `cat $pidfile`
