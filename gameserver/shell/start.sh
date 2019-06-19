#!/bin/sh

SKYNET_ROOT=../
PID_ROOT=../log
if [ $# -lt 1 ]; then
	current_dirname=`pwd`
	parent_dirname=`dirname $current_dirname`
	servername=`basename $parent_dirname`
else
	servername=$1
fi

config=$servername.config
if [ ! -f ../src/app/config/$config ]; then
	echo "config file not exist: ../src/app/config/$config"
	exit 0;
fi

status=`sh status.sh`
if [ "$status" = "start" ]; then
	echo $servername "aready start"
	exit;
elif [ "$status" = "killed" ]; then
	rm $PID_ROOT/skynet.pid
fi

mkdir -p ../log
cd $SKYNET_ROOT
chmod +x skynet
./skynet src/app/config/$config >/dev/null &
