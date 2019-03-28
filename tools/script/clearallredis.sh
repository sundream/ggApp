#!/bin/sh
# 清空redis集群所有数据

if [ $# -lt 2 ]; then
	echo "usage: sh clearallredis.sh 集群某节点ip 集群某节点port"
	echo  "e.g: sh clearallredis.sh 127.0.0.1 7001"
	exit
fi

ip=$1
port=$2
REDIS_CLI=redis-cli
if [ $# -eq 3 ]; then
	REDIS_CLI=$3
fi
cluster_nodes=`redis-cli -h $ip -p $port cluster nodes | awk 'OFS=";" {print $2,$3}'`
#echo $cluster_nodes
for node in $cluster_nodes; do
	#echo node: $node
	node_ip_port=`echo $node | awk -F ';' '{print $1}'`
	node_ip=`echo $node_ip_port | cut -d: -f1`
	node_port=`echo $node_ip_port | cut -d: -f2 | cut -d@ -f1`
	# may master/slave/myself,master/myself,slave
	node_ismaster=`echo $node | awk -F ';' '{print $2}'`
	node_ismaster=`echo $node_ismaster | cut -d, -f2`

	#echo $node_ip,$node_port,$node_ismaster
	if [ "$node_ismaster" = "master" ]; then
		echo "clear $node_ip:$node_port $node_ismaster"
		$REDIS_CLI -h $node_ip -p $node_port flushall
		$REDIS_CLI -h $node_ip -p $node_port info keyspace
	fi
done
