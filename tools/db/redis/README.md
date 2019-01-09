建立redis集群
=============

* 环境
	* ubuntu: 18.04.1 LTS
	* redis: 5.0.2

* [安装](https://redis.io/topics/quickstart)

* 工作目录
```
mkdir ~/db
cp -R tools/db/* ~/db
sed -i "s|/home/ubuntu|$HOME|g" `grep /home/ubuntu -rl ~/db`
```

* 构成  
	```
	3个master+3个slave
	3个master端口为7001,7002,7003
	3个slave端口为7004,7005,7006
	```

* 配置文件示例  
	```
	见db/redis/xxx/redis.conf
	```

* 启动
	```
	sh tools/script/startallredis.sh
	// 如果首次启动,我们需要构建集群
	redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 --cluster-replicas 1
	// 低版本可以用源码目录下的redis-trib.rb工具
	./redis-trib.rb create --replicas 1 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006
	```
