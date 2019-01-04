router+configsvr+shard建立mongo分片集群
=======================================

* 环境
	* ubuntu: 18.04.1 LTS
	* mongod: 4.0.5

* 安装
	```
	# see https://docs.mongodb.com/manual/installation
	python tools/script/install_mongo.py --help
	e.g: python tools/script/install_mongo.py
	```

* 工作目录
```
mkdir ~/db
cp -R tools/db/* ~/db
```

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
	sh tools/script/startallmongo.sh
	// 首次启动,执行下面脚本初始化集群(等mongodb启动完毕后在执行)
	sh ~/db/mongodb/js/initCluster.sh
	```
