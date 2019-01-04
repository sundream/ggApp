#!/bin/sh
pidfile=../skynet/skynet.pid
if ! [ -f $pidfile ]; then
	echo "stop"
	exit;
fi
pid=`cat $pidfile`
if ps -p $pid >/dev/null 2>&1; then
	echo "start"
else
	# unsafe stop
	echo "killed"
fi
