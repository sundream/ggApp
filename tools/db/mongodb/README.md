* 环境
	* ubuntu: 18.04.1 LTS
	* mongod: 4.0.5

* [安装](https://docs.mongodb.com/manual/installation)

* 工作目录
```
mkdir ~/db
cp -R tools/db/* ~/db
sed -i "s|/root|$HOME|g" `grep /root -rl ~/db`
```

router+configsvr+shard搭建mongo分片集群
=======================================
* 构成
	```
	1 configsvr replicaSet + 3 shard replicaSet + 3 router
	configsvr副本集用28017,28018,28019端口
	shard0001副本集用27017,27018,27019端口
	shard0002副本集用27027,27028,27029端口
	shard0003副本集用27037,27038,27039端口
	3个router分别用29017,29018,29019端口
	```

* 配置文件示例  
	```
	configsvr配置见~/db/mongodb/configsvr_[1:3]/mongodb.conf
	shard配置见~/db/mongodb/shard000[1:3]_[1:3]/mongodb.conf
	router配置见~/db/mongodb/router_[1:3]/mongodb.conf
	```

* 启动
	```
	sh tools/script/start_mongo_cluster.sh
	// 首次启动,执行下面脚本初始化集群(等mongodb启动完毕后在执行)
	sh ~/db/mongodb/js/initCluster.sh
	```

* 关闭
	```
	sh tools/script/stop_mongo_cluster.sh
	```

搭建mongo单例
=============
* 构成
	```
    默认监听26000端口
	```

* 配置文件示例  
	```
    见~/db/mongodb/mongodb/mongodb.conf
	```

* 启动
	```
    mongod -f ~/db/mongodb/mongodb/mongodb.conf &
	```

* 关闭
	```
	pkill -2 mongod
	```
