ggApp
=====
ggApp是一个基于[gg](https://github.com/sundream/ggApp/tree/master/gameserver/src/gg)的游戏服务器示例,
引擎使用[skynet](https://github.com/cloudwu/skynet),上层使用Lua开发。

Table of Contents
=================

* [名字](#ggApp)
* [状态](#状态)
* [特点](#特点)
* [服务器](#服务器)
* [客户端](#客户端)
* [压测工具](#压测工具)
* [服务器结构](#服务器结构)
* [目录结构](#目录结构)
* [开发环境](#开发环境)
* [文档](#文档)
* [一键部署](#一键部署)
* [社区](#社区)
* [证书](#证书)

状态
===
stable(Make it better)

特点
====
* 对skynet引擎无任何修改
* 结构简单,易于使用

服务器
======
* 检出
	```
	cd ~ && git clone https://github.com/sundream/ggApp --recursive
	```
* 依赖项
	* 工具/库
	  * ubuntu18.04
		```
		# in ubuntu 16.04,you need change readline-dev to libreadline-dev
		sudo apt install -y protobuf-compiler protobuf-c-compiler readline-dev autoconf git subversion telnet netcat libcurl4-openssl-dev
		```
	  * centos
		```
		sudo yum install -y protobuf-compiler protobuf-c-compiler readline-devel autoconf git subversion telnet nc libcurl-devel
		```

	* 其他工具(非必要安装)
		* [lua-5.3.5](https://www.lua.org/download.html)
		* python-2.7.16
			```
			curl -R -O https://www.python.org/ftp/python/2.7.15/Python-2.7.16.tgz
			tar -zxvf Python-2.7.16.tgz
			cd Python-2.7.16
			./configure
			make
			sudo make install
			```
		* luarocks for lua5.3
			```
			git clone https://github.com/luarocks/luarocks
			cd luarocks
			./configure --lua-version=5.3 --with-lua-include=/usr/local/include
			make build
			sudo make install
			```

* 安装DB(框架默认使用mongodb)
	* [安装mongodb](https://github.com/sundream/ggApp/blob/master/tools/db/mongodb/README.md)
	* [安装redis](https://github.com/sundream/ggApp/blob/master/tools/db/redis/README.md)
	* [启动mongodb](https://github.com/sundream/ggApp/blob/master/tools/db/mongodb/README.md)
    * [启动redis](https://github.com/sundream/ggApp/blob/master/tools/db/redis/README.md)

* 编译loginserver
	```
	cd ~/ggApp/loginserver
	make linux
	# make macosx
	```

* 编译gameserver
	```
	cd ~/ggApp/gameserver
	make linux
	# make macosx
	```

* 运行loginserver
	* 首次启动准备工作
		```
		cd ~/ggApp
		mkdir -p loginserver/log
		```
	* 直接启动
		```
		cd ~/ggApp/loginserver
		./skynet src/app/config/loginserver.config
		// 启动后成功后控制台会提示start,另外log/game/game$DATE.log会记录启服/关服日志
		// 你也可以在控制台中执行任何lua代码
		```

	* shell管理
		```
		cd ~/ggApp/loginserver/shell
		sh status.sh	# 查看状态
		sh start.sh		# 启动
		sh stop.sh		# 关闭
		sh restart.sh	# 重启
		sh kill.sh		# 强制关闭
		```
* 导入app
    ```
	# 首次启动/app有变动时执行
	python tools/script/add_app.py --app=tools/script/app.config --loginserver="127.0.0.1:8885"
    ```

* 导入服务器列表
	```
	# 首次启动/服务器配置有变动时执行
	python tools/script/import_servers.py --appid=appid --config=tools/script/servers.dev.config --loginserver="127.0.0.1:8885"
	```

* 生成服务器配置文件
	```
	# 服务器配置有变动时执行
	python tools/script/generate_gameserver_config.py --config=tools/script/servers.dev.config --out=~/ggApp/gameserver/src/app/config
	```

* 运行gameserver
	* 首次启动准备工作
		```
		cd ~/ggApp
		# gameserver_1为服务器名
		ln -s gameserver gameserver_1
		mkdir -p gameserver_1/log
		```
	* 直接启动
		```
		cd ~/ggApp/gameserver_1
		./skynet src/app/config/gameserver_1.config
		// 启动后成功后控制台会提示start,另外log/game/game$DATE.log会记录启服/关服日志
		// 你也可以在控制台中执行任何lua代码
		```

	* shell管理
		```
		cd ~/ggApp/gameserver_1/shell
		sh status.sh	# 查看状态
		sh start.sh		# 启动
		sh stop.sh		# 关闭
		sh restart.sh	# 重启
		sh kill.sh		# 强制关闭
		```

	* 执行gm指令
		```
		cd ~/ggApp/gameserver_1/shell
		sh gm.sh #提示用法
		sh gm.sh 0 help help
		sh gm.sh 0 exec 'print(\"hello\")'
		curl 'http://127.0.0.1:18888/call/8 "gm","0 exec print(\"hello\")"'
		```


[Back to TOC](#table-of-contents)

客户端
======
see [client/README.md](https://github.com/sundream/ggApp/blob/master/client/README.md)

[Back to TOC](#table-of-contents)

压测工具
========
see [robot/README.md](https://github.com/sundream/ggApp/blob/master/robot/README.md)

[Back to TOC](#table-of-contents)

服务器结构
==========
* 节点结构  
![节点结构](node_structure.png)
	```
	登录服: 负责账密验证，充值回调验证等
	游戏服: 负责游戏玩法逻辑(根据不同需求可划分成不同功能服)
	DB: 示例使用mongodb,你也可以使用redis集群/mongo集群
	```
* 内部结构  
![内部结构](node_inner_structure.png)
	```
	说明: 这里的结构并不包括skynet本身启动的服务
	网关服务: 管理客户端连接,协议编码,协议加解密等。目前支持tcp,kcp,websocket网关,可选择使用/混合使用
	主服务: 负责游戏主要玩法逻辑,我们推荐大部分玩法在主服务实现,特定玩法可自定义服务实现
	Logger服务: 日志处理
	```

[Back to TOC](#table-of-contents)

目录结构
========
* 大致目录结构
```
+~/ggApp  
    +gg                         // 公共代码
	+loginserver				// 登陆服
	+gameserver					// 游戏服
		+src
			+gg					// -> ../../gg
			+app				// 游戏逻辑
			+proto				// 协议
		+shell					// 启服/关服等脚本
	+client						// 简易客户端(如可用来给服务器发送协议,快速登录等)
	+robot						// 压测工具
	+tools						// 其他工具
        +db                     // db配置示例
		+script					// 部分管理脚本
+~/db							// db(包含示例配置)
	+redis					// redis数据库
	+mongodb				// mongo数据库
```

[Back to TOC](#table-of-contents)

开发环境
========
* centos运行服务器+window开发  
```
	1. 安装samba
		sudo yum install -y samba samba-client

	2. 在/etc/samba/smb.conf下增加以下配置
	#$USER为你的用户名
	[$USER]
		comment = samba share folder
		path = /home/$USER
		available = yes
		browseable = yes
		public = yes
		writable = yes
		force user = $USER
		force group = $USER
		create mask = 0664
		directory mask = 0775

	3. 增加samba账户
		sudo touch /etc/samba/smbpasswd
		sudo smbpasswd -a $USER
		执行上面命令后会提示输入密码,输入两次密码创建samba账户

	4. 重启samba服务
		sudo systemctl restart smb nmb

	5. window下连接samba
		在资源管理器地址栏输入: \\$IP即可看到共享文件$USER
		右键$USER文件夹,点击<映射为网络驱动>,以便以后方便访问
```

文档
====
* 生成文档
	```
	如果没有安装ldoc,可用以下指令安装
	sudo luarocks install ldoc
	// sudo apt install lua-doc		# ubuntu下也可以用这种方式安装
	目前loginserver和gameserver进行了文档注释,可以用ldoc工具导出html文档,如:
	cd loginserver
	ldoc .
	执行后将会生成doc目录,用浏览器打开doc/index.html即可查看文档
	```
* 查看[Wiki](https://github.com/sundream/ggApp/wiki)来了解更多细节

* 静态代码检查
	```
	提前安装luacheck
	sudo luarocks install luacheck
	// sudo apt install lua-check	# ubuntu下也可以用这种方式安装
	目前loginserver和gameserver进行了配置了luacheck静态检查规则,可以用luacheck进行检查,如:
	cd gameserver
	luacheck . | tee /tmp/luacheck.out
	```
	

[Back to TOC](#table-of-contents)

一键部署
========
使用[ggApp-ansible](https://github.com/sundream/ggApp-ansible)一键部署，他会自动帮我们
安装必要软件,安装依赖,生成db配置文件等.

社区
====

[Back to TOC](#table-of-contents)


证书
====
ggApp is licensed under the MIT License,Version 0.0.1. See [LICENSE](https://github.com/sundream/ggApp/blob/master/LICENSE) for the full license text.

[Back to TOC](#table-of-contents)
