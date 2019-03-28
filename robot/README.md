* 编译
	```
	# 删除第三方库
	make delete3rd
	# 检出第三方库
	make update3rd
	# 编译
	make linux
	# make macosx
	# 清除编译
	make clean
	```
* 运行
	```
	cd ~/ggApp/robot/3rd/skynet
	# 首次运行创建log目录
	mkdir -p ../../log
	./skynet ../../app/config/robot.config &
	telnet 127.0.0.1 6666
	启动若干机器人:
	start app/service/newrobot 100 1000001  <=> 从1000001角色ID开始启动100个机器人
	start app/service/newrobot 100 1000101  <=> 继续从1000101角色ID开始启动100个机器人
	// app/config/robot.config中有gate_type,ip,port配置,更改这些字段即可改变测试服务器
	// 日志可见log/skynet.log
	// 现在默认压测逻辑是发送心跳包,你可以在app/service/robot.lua#onlogin中自定义压测逻辑
	```

* 关闭
	```
	ps -ef | grep robot
	kill -9 找到的robot进程pid
	```
