---热更模块
--@script gg.base.hotfix
--@author sundream
--@release 2018/12/25 10:30:00
hotfix = hotfix or {}

---热更模块
--@param[type=string] modname 模块名
--@return 热更成功返回true,失败返回false和错误消息
--@usage hotfix.hotfix("gg.base.hotfix")
--热更完毕后会执行模块中定义(如果有)的__hotfix全局函数
--只支持简单热更,无法更新模块级别定义的local变量
function hotfix.reload(modname)
	local chunk,err
	local env = _ENV or _G
	env.__hotfix = nil
	local filename = package.searchpath(modname,package.path)
	if filename then
		--chunk,err = loadfile(filename,"bt",env)
		local fp = io.open(filename,"rb")
		local module = fp:read("*a")
		fp:close()
		chunk,err = load(module,filename,"bt",env)
	else
		err = "no such file"
	end
	if not chunk then
		return false,err
	end
	local oldmod = package.loaded[modname]
	local ok,newmod = pcall(chunk)
	if not ok then
		return false,newmod
	end
	if newmod ~= nil then
		package.loaded[modname] = newmod
	else
		package.loaded[modname] = true
	end
	if type(env.__hotfix) == "function" then
		env.__hotfix(oldmod)
	end
	return true
end

return hotfix
