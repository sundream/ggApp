#!/bin/sh

. ../skynet/debug_console.txt
cmdline=$@
if [ "$cmdline" = "" ]; then
	echo 'sh gm.sh 玩家ID 指令 参数...'
	echo '举例:'
	echo 'sh gm.sh #提示用法'
	echo 'sh gm.sh 0 help help'
	echo 'sh gm.sh 0 exec '"'"'print(\"hello\")'"'"
	echo 'curl '"'"'http://127.0.0.1:18888/call/8 "gm","0 exec print(\"hello\")"'"'"
	exit 0;
fi

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
