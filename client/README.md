* 依赖项
	* [lua-5.3.5](https://www.lua.org/download.html)
	* [luarocks for lua5.3](https://github.com/luarocks/luarocks)
	* luarocks安装的库
		```
		sudo luarocks install luasocket lpeg
		```

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
	cd ~/ggApp
	lua client/app/app.lua
	// 执行后你将会看到如下提示
	Game Client 0.0.1 Welcome!
	exit() -> exit app
	help() -> show help doc
	// 输入help()即可查看帮助文档。另外客户端控制台可以输入任何lua脚本
	```

