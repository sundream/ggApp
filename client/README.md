* 编译
	```
	# 删除第三方库
	make delete3rd
	# 检出第三方库
	make update3rd
	# 编译
	make linux
	# make macosx
	# make mingw
	# 清除编译
	make clean
	```
* 运行
	```
	cd ~/ggApp
	client/3rd/lua/5.3/bin/lua client/app/app.lua
	// 执行后你将会看到如下提示
	Game Client 0.0.1 Welcome!
	exit() -> exit app
	help() -> show help doc
	// 输入help()即可查看帮助文档。你也可以输入任何lua脚本

	// windows
	client/3rd/lua/5.3/bin/lua client/app/app.lua
	再通过telnet 127.0.0.1 6667连接来操作,telnet可以在安装mingw时一并安装
	```
