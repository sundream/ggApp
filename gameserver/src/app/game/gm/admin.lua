local cgm = gg.class.cgm

---功能: 角色换服
---@usage
---用法: rebindserver 角色ID 目标服务器ID
function cgm:rebindserver(args)
	if self.master and not self.master:is_super_gm() then
		return self:say("禁用危险指令")
	end
	local isok,args = gg.checkargs(args,"int","string")
	if not isok then
		return self:say("用法: rebindserver 角色ID 目标服务器ID")
	end
	local roleid = args[1]
    local new_serverid = args[2]
	local ok,err = gg.playermgr:rebindserver(roleid,new_serverid)
	local msg
	if ok then
        local new_roleid = err
		msg = self:say(string.format("重绑服务器成功: 目标服务器ID=%s,角色ID=%s,新角色ID=%s",new_serverid,roleid,new_roleid))
	else
		msg = self:say(string.format("重绑服务器失败: %s",err))
	end
    return msg
end

---功能: 角色换绑帐号
---@usage
---用法: rebindaccount 角色ID 新账号
function cgm:rebindaccount(args)
	if self.master and not self.master:is_super_gm() then
		return self:say("禁用危险指令")
	end
	local isok,args = gg.checkargs(args,"int","string")
	if not isok then
		return self:say("用法: rebindaccount 角色ID 新账号")
	end
	local roleid = args[1]
	local new_account = args[2]
	local ok,err = gg.playermgr:rebindaccount(roleid,new_account)
	local msg
	if ok then
		msg = self:say(string.format("重绑帐号成功: 角色ID=%s,新账号=%s",roleid,new_account))
	else
		msg = self:say(string.format("重绑帐号失败: %s",err))
	end
	return msg
end

---功能: 删除一个角色
---@usage
---用法: delrole 角色ID [是否永久删除]
function cgm:delrole(args)
	if self.master and not self.master:is_super_gm() then
		return self:say("禁用危险指令")
	end
	local isok,args = gg.checkargs(args,"int","*")
	if not isok then
		return self:say("用法: delrole 角色ID [是否永久删除]")
	end
	local roleid = args[1]
    local forever = gg.istrue(args[2])
	local ok,err = gg.playermgr:delrole(roleid,forever)
	local msg
	if ok then
		msg = self:say(string.format("删除角色成功: 角色ID=%s",roleid))
	else
		msg = self:say(string.format("删除角色失败: %s",err))
	end
	return msg
end

---功能: 恢复一个角色
---@usage
---用法: recover_role 角色ID
function cgm:recover_role(args)
	if self.master and not self.master:is_super_gm() then
		return self:say("禁用危险指令")
	end
	local isok,args = gg.checkargs(args,"int")
	if not isok then
		return self:say("用法: recover_role 角色ID")
	end
	local roleid = args[1]
	local ok,err = gg.playermgr:recover_role(roleid)
	local msg
	if ok then
		msg = self:say(string.format("恢复角色成功: 角色ID=%s",roleid))
	else
		msg = self:say(string.format("恢复角色失败: %s",err))
	end
	return msg
end

---功能: 复制一个角色
---@usage
---用法: clone 角色ID [帐号]
function cgm:clone(args)
	if self.master and not self.master:is_super_gm() then
		return self:say("禁用危险指令")
	end
	local isok,args = gg.checkargs(args,"int","*")
	if not isok then
		return self:say("用法: clone 角色ID [帐号]")
	end
	local roleid = args[1]
	local account
	if not self.master and not args[2] then
		return self:say("用法: clone 角色ID [帐号]")
	else
		account = args[2] or self.master.account
	end
	local player = gg.playermgr:loadplayer(roleid)
    local role_data = gg.deepcopy(player:serialize())
	local ok,new_roleid = gg.playermgr:clone(role_data,account)
	local msg
	if ok then
		msg = self:say(string.format("复制角色成功: 新角色ID=%s,账号=%s",new_roleid,account))
	else
		local err = new_roleid
		msg = self:say(string.format("复制角色失败: %s",err))
	end
	return msg
end

---功能: 将角色数据序列化成到/tmp/角色ID.json
---@usage
---用法: serialize 角色ID
function cgm:serialize(args)
	if self.master and not self.master:is_super_gm() then
		return self:say("禁用危险指令")
	end
	local isok,args = gg.checkargs(args,"int")
	if not isok then
		return self:say("用法: serialize 角色ID")
	end
	local roleid = args[1]
	local player = gg.playermgr:loadplayer(roleid)
	local role_data = player:serialize()
	role_data = cjson.encode(role_data)
	local filename = string.format("/tmp/%s.json",roleid)
	local fd = io.open(filename,"wb")
	fd:write(role_data)
	fd:close()
	return filename
end

---功能: 从保存角色数据的文件中复制一个角色
---@usage
---用法: unserialize 文件名 [帐号]
function cgm:unserialize(args)
	if self.master and not self.master:is_super_gm() then
		return self:say("禁用危险指令")
	end
	local isok,args = gg.checkargs(args,"string","*")
	if not isok then
		return self:say("用法: unserialize 文件名 [帐号]")
	end
	local filename = args[1]
	local account
	if not self.master and not args[2] then
		return self:say("用法: unserialize 文件名 [帐号]")
	else
		account = args[2] or self.master.account
	end
	local fd = io.open(filename,"rb")
	local role_data = fd:read("*a")
	fd:close()
	role_data = cjson.decode(role_data)
	local ok,new_roleid = gg.playermgr:clone(role_data,account)
	local msg
	if ok then
		msg = self:say(string.format("复制角色成功: 新角色ID=%s,账号=%s",new_roleid,account))
	else
		local err = new_roleid
		msg = self:say(string.format("复制角色失败: %s",err))
	end
	return msg
end

return cgm