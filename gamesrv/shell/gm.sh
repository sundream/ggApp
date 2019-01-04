#!/bin/sh

# sh gm.sh 玩家ID 指令 参数...
# eg: sh gm.sh 0 runcmd 'print(\"hello\")'
# eg: curl 'http://127.0.0.1:18888/call/8 "gm","0 runcmd print(\"hello\")"'

. ../skynet/debug_console.txt
cmdline=$@
ip=127.0.0.1

cmd="call $address \"gm\",\"$cmdline\""
os=`uname -s`
if [ "$os" = "Darwin" ]; then
	# macosx
	echo $cmd | nc -i 1 $ip $port
elif [ "$os" = "Linux" ]; then
	if [ -f /etc/redhat-release ]; then
		# centos
		echo $cmd | nc -d 1 $ip $port
	else
		# ubuntu
		echo $cmd | nc -q 1 $ip $port
	fi
fi
