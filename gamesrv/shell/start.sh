#!/bin/sh

if [ $# -lt 1 ]; then
	current_dirname=`pwd`
	parent_dirname=`dirname $current_dirname`
	srvname=`basename $parent_dirname`
else
	srvname=$1
fi

config=../src/app/config/$srvname.config
if [ ! -f $config ]; then
	echo "config file not exist: $config" 
	exit 0;
fi

status=`sh status.sh`
if [ "$status" = "start" ]; then
	echo $srvname "aready start"
	exit;
elif [ "$status" = "killed" ]; then
	rm ../skynet/skynet.pid
fi

pwd
mkdir -p ../log
cd ../skynet
chmod +x skynet
./skynet $config >/dev/null &
