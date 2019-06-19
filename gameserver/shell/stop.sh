#! /bin/sh

status=`sh status.sh`
if [ "$status" != "start" ]; then
	echo "aready stop"
	exit;
fi
sh gm.sh 0 stop "shutdown"
