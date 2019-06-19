* 环境
	* ubuntu: 18.04.1 LTS
	* redis: 5.0.2

* [安装](https://redis.io/topics/quickstart)

* 工作目录
```
mkdir ~/db
cp -R tools/db/* ~/db
sed -i "s|/root|$HOME|g" `grep /root -rl ~/db`
```

搭建redis集群
=============

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
	sh tools/script/start_redis_cluster.sh
	// 如果首次启动,我们需要构建集群,127.0.0.1为redis.conf中绑定的ip,如果有变动需要修改
	redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 --cluster-replicas 1
	// 低版本可以用源码目录下的redis-trib.rb工具
	./redis-trib.rb create --replicas 1 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006
	```

* 关闭
    ```
    sh tools/script/stop_redis_cluster.sh
    ```

搭建redis单例
=============
* 构成  
	```
    默认监听6000端口
	```

* 配置文件示例  
	```
	见db/redis_1/redis.conf
	```

* 启动
	```
    redis-server ~/db/redis/redis_1/redis.conf
    ```
* 关闭
    ```
    redis-cli -h 127.0.0.1 -p 6000 -a redispwd shutdown
    ```
