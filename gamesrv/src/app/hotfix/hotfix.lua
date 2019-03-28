hotfix.ignore_modules = {
	"gg%.service%.*",
	"gg%.like_skynet.*",
	"app%.service%.*",
}

function hotfix.hotfix(modname)
	local start = modname:sub(1,7)
	if start == "../src/" then
		modname = modname:sub(8)
	end
	local start = modname:sub(1,4)
	if start == "src/" or start == "src." then
		modname = modname:sub(5)
	end
	for i,pat in ipairs(hotfix.ignore_modules) do
		if modname == string.match(modname,pat) then
			return false,"ignore"
		end
	end
	local address = skynet.address(skynet.self())
	local is_proto = modname:sub(1,5) == "proto"
	-- 只允许游戏逻辑+协议更新
	if is_proto then
		local msg = string.format("op=hotfix,address=%s,module=%s",address,modname)
		logger.logf("info","hotfix",msg)
		print(msg)
		client.reload_proto()
		return true
	end
	local suffix = modname:sub(-4,-1)
	if suffix == ".lua" then
		modname = modname:sub(1,-5)
	end
	modname = string.gsub(modname,"/",".")
	modname = string.gsub(modname,"\\",".")
	local ok,err = hotfix.reload(modname)
	if not ok then
		local msg = string.format("op=hotfix,address=%s,module=%s,fail=%s",address,modname,err)
		logger.logf("error","hotfix",msg)
		print(msg)
		return false,msg
	end
	local msg = string.format("op=hotfix,address=%s,module=%s",address,modname)
	logger.logf("info","hotfix",msg)
	print(msg)
	return true
end

return hotfix
