--- table扩展
--@script gg.base.util.table
--@author sundream
--@release 2018/12/25 10:30:00

-- comptiable with lua51
unpack = unpack or table.unpack
table.unpack = unpack
if table.pack == nil then
	function table.pack(...)
		return {n=select("#",...),...}
	end
end

--- 判定集合: 是否有一个元素符合条件
--@param[type=table] set 集合
--@param[type=func] func 判定函数
--@return[type=bool] 是否成立
function table.any(set,func)
	for k,v in pairs(set) do
		if func(k,v) then
			return true,k,v
		end
	end
	return false
end

--- 判定集合: 是否所有元素符合条件
--@param[type=table] set 集合
--@param[type=func] func 判定函数
--@return[type=bool] 是否成立
function table.all(set,func)
	for k,v in pairs(set) do
		if not func(k,v) then
			return false,k,v
		end
	end
	return true
end

--- 过滤字典
--@param[type=table] tbl 字典
--@param[type=func] func 过滤函数
--@return[type=table] 过滤后的新字典
function table.filter_dict(tbl,func)
	local newtbl = {}
	for k,v in pairs(tbl) do
		if func(k,v) then
			newtbl[k] = v
		end
	end
	return newtbl
end

--- 过滤列表
--@param[type=table] list 列表
--@param[type=func] func 过滤函数
--@return[type=table] 过滤后的新列表
function table.filter(list,func)
	local new_list = {}
	for i,v in ipairs(list) do
		if func(v) then
			table.insert(new_list,v)
		end
	end
	return new_list
end

--- 从序列中找最大元素
function table.max(func,...)
	if type(func) ~= "function" then
		return math.max(...)
	end
	local args = table.pack(...)
	local max
	for i,arg in ipairs(args) do
		local val = func(arg)
		if not max or val > max then
			max = val
		end
	end
	return max
end

--- 从序列中找最小元素
function table.min(func,...)
	if type(func) ~= "function" then
		return math.min(...)
	end
	local args = table.pack(...)
	local min
	for i,arg in ipairs(args) do
		local val = func(arg)
		if not min or val < min then
			min = val
		end
	end
	return min
end

function table.map(func,...)
	local args = table.pack(...)
	assert(#args >= 1)
	func = func or function (...)
		return {...}
	end
	local maxn = table.max(function (tbl)
			return #tbl
		end,...)
	local len = #args
	local newtbl = {}
	for i=1,maxn do
		local list = {}
		for j=1,len do
			table.insert(list,args[j][i])
		end
		local ret = func(table.unpack(list))
		table.insert(newtbl,ret)
	end
	return newtbl
end

--- 从表中查找符合条件的元素
--@param[type=table] tbl 表
--@param[type=func] func 匹配函数/值
--@return k,v 找到的键值对
function table.find(tbl,func)
	local isfunc = type(func) == "function"
	for k,v in pairs(tbl) do
		if isfunc then
			if func(k,v) then
				return k,v
			end
		else
			if func == v then
				return k,v
			end
		end
	end
end

--- 获取表的所有键
--@param[type=table] t 表
--@return[type=table] 所有键构成的列表
function table.keys(t)
	local ret = {}
	for k,v in pairs(t) do
		table.insert(ret,k)
	end
	return ret
end

--- 获取表的所有值
--@param[type=table] t 表
--@return[type=table] 所有值构成的列表
function table.values(t)
	local ret = {}
	for k,v in pairs(t) do
		table.insert(ret,v)
	end
	return ret
end

--- 将表dump成字符串(便于人类阅读的格式,支持环状引用)
--@param[type=table] t 表
--@return[type=string] dump成的字符串
function table.dump(t,space,name)
	if type(t) ~= "table" then
		return tostring(t)
	end
	space = space or ""
	name = name or ""
	local cache = { [t] = "."}
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
			else
				table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return table.concat(temp,"\n"..space)
	end
	return _dump(t,space,name)
end

--- 根据键从表中获取值
--@param[type=table] tbl 表
--@param[type=string] attr 键
--@return[type=any] 该键对于的值
--@raise 分层键不存在时会报错
--@usage local val = table.getattr(tbl,"key")
--@usage local val = table.getattr(tbl,"k1.k2.k3")
function table.getattr(tbl,attr)
	local attrs = type(attr) == "table" and attr or string.split(attr,".")
	local root = tbl
	for i,attr in ipairs(attrs) do
		root = root[attr]
	end
	return root
end

--- 判断表中是否有键
--@param[type=table] tbl 表
--@param[type=string] attr 键
--@return[type=bool] 键是否存在
--@return[type=any] 该键对于的值
--@usage local exist,val = table.hasattr(tbl,"key")
--@usage local exist,val = table.hasattr(tbl,"k1.k2.k3")
function table.hasattr(tbl,attr)
	local attrs = type(attr) == "table" and attr or string.split(attr,".")
	local root = tbl
	local len = #attrs
	for i,attr in ipairs(attrs) do
		root = root[attr]
		if i ~= len and type(root) ~= "table" then
			return false
		end
	end
	return true,root
end

--- 向表中设置键值对
--@param[type=table] tbl 表
--@param[type=string] attr 键
--@param[type=any] val 值
--@return[type=any] 该键对应的旧值
--@usage table.setattr(tbl,"key",1)
--@usage table.setattr(tbl,"k1.k2.k3","hi")
function table.setattr(tbl,attr,val)
	local attrs = type(attr) == "table" and attr or string.split(attr,".")
	local lastkey = table.remove(attrs)
	local root = tbl
	for i,attr in ipairs(attrs) do
		if nil == root[attr] then
			root[attr] = {}
		end
		root = root[attr]
	end
	local oldval = root[lastkey]
	root[lastkey] = val
	return oldval
end

--- 根据键从表中获取值
--@param[type=table] tbl 表
--@param[type=string] attr 键
--@return[type=any] 该键对于的值,键不存在返回nil
--@usage local val = table.query(tbl,"key")
--@usage local val = table.query(tbl,"k1.k2.k3")
function table.query(tbl,attr)
	local exist,value = table.hasattr(tbl,attr)
	if exist then
		return value
	else
		return nil
	end
end

--- 判断是否为空表
--@param[type=table] tbl 表
--@return[type=bool] 是否为空表
function table.isempty(tbl)
	if cjson and cjson.null == tbl then -- int64:0x0
		return true
	end
	if not tbl or not next(tbl) then
		return true
	end
	return false
end

--- 判断是否为空表(递归整个表,嵌套的空表，包括值为0/""的都是空值)
--@param[type=table] tbl 表
--@return[type=bool] 是否为空表
function table.isempty_ex(tbl)
	if table.isempty(tbl) then
		return true
	end
	local isempty = true
	for k,v in pairs(tbl) do
		local typ = type(v)
		if typ == "table" then
			if not table.isempty_ex(v) then
				isempty = false
			end
		elseif typ == "string" then
			if v ~= "" then
				isempty = false
			end
		elseif typ == "number" then
			if v ~= 0 and v ~= 0.0 then
				isempty = false
			end
		else
			isempty = false
		end
	end
	return isempty
end

--- 将一个列表的所有元素都尾追到另一个列表
--@param[type=table] tbl1 被扩展的列表
--@param[type=table] tbl2 元素来源列表
--@return[type=table] 扩展后的列表
function table.extend(tbl1,tbl2)
	for i,v in ipairs(tbl2) do
		table.insert(tbl1,v)
	end
	return tbl1
end

--- 将一个字典的所有键值对都更新到另一个字典
--@param[type=table] tbl1 被更新的字典
--@param[type=table] tbl2 键值对来源的字典
--@return[type=table] 扩展后的字典
function table.update(tbl1,tbl2)
	for k,v in pairs(tbl2) do
		tbl1[k] = v
	end
	return tbl1
end

--- 统计一个表的元素个数
--@param[type=table] tbl 表
--@return[type=int] 元素个数
function table.count(tbl)
	local cnt = 0
	for k,v in pairs(tbl) do
		cnt = cnt + 1
	end
	return cnt
end

--- 从表中删除特定值
--@param[type=table] t 表
--@param[type=any] val 删除的值
--@param[type=int,opt] maxcnt 最大删除个数,不指定则无限制
--@return[type=table] 删除元素的所有键构成的列表
function table.del_value(t,val,maxcnt)
	local delkey = {}
	for k,v in pairs(t) do
		if v == val then
			if not maxcnt or #delkey < maxcnt then
				delkey[#delkey] = k
			else
				break
			end
		end
	end
	for _,k in pairs(delkey) do
		t[k] = nil
	end
	return delkey
end

--- 从列表中删除元素
--@param[type=table] list 列表
--@param[type=any] val 删除的元素
--@param[type=int,opt] maxcnt 最大删除个数,不指定则无限制
--@return[type=table] 删除元素的所有位置构成的列表
function table.remove_value(list,val,maxcnt)
	local len = #list
	maxcnt = maxcnt or len
	local delpos = {}
	for pos=len,1,-1 do
		if list[pos] == val then
			table.remove(list,pos)
			table.insert(delpos,pos)
			if #delpos >= maxcnt then
				break
			end
		end
	end
	return delpos
end

--- 将字典的所有元素的值构成列表
--@param[type=table] t 字典
--@return[type=table] 所有元素的值构成的列表
function table.tolist(t)
	local ret = {}
	for k,v in pairs(t) do
		ret[#ret+1] = v
	end
	return ret
end

local function less_than(lhs,rhs)
	return lhs < rhs
end

--- 在[1,#t+1)区间找第一个>=val的位置
function table.lower_bound(t,val,cmp)
	cmp = cmp or less_than
	local len = #t
	local first,last = 1,len + 1
	while first < last do
		local pos = math.floor((last-first) / 2) + first
		if not cmp(t[pos],val) then
			last = pos
		else
			first = pos + 1
		end
	end
	if last > len then
		return nil
	else
		return last
	end
end

--- 在[1,#t+1)区间找第一个>val的位置
function table.upper_bound(t,val,cmp)
	cmp = cmp or less_than
	local len = #t
	local first,last = 1,len + 1
	while first < last do
		local pos = math.floor((last-first)/2) + first
		if cmp(val,t[pos]) then
			last = pos
		else
			first = pos + 1
		end
	end
	if last > len then
		return nil
	else
		return last
	end
end

--- 判断两个对象是否相等
--@param[type=any] lhs 对象1
--@param[type=any] rhs 对象2
--@return[type=bool] true--相等,false--不相等
function table.equal(lhs,rhs)
	if lhs == rhs then
		return true
	end
	if type(lhs) == "table" and type(rhs) == "table" then
		if table.count(lhs) ~= table.count(rhs) then
			return false
		end
		local issame = true
		for k,v in pairs(lhs) do
			if not table.equal(v,rhs[k]) then
				issame = false
				break
			end
		end
		return issame
	end
	return false
end

--- 从列表中获取一个切片列表
--@param[type=table] list 列表
--@param[type=int] b 开始位置
--@param[type=int opt] e 结束位置(包括这位置),如果为nil,则为b的值,而b变成1
--@param[type=int opt=1] step 步长
--@return[type=table] 新的切片列表
--@usage
--local list = {1,2,3,4,5}
--local new_list = table.slice(list,1,3)  -- {1,2,3}
--local new_list = table.slice(list,1,5,2)  -- {1,3,5}
--local new_list = table.slice(list,-1,-5,-1)  -- {5,4,3,2,1}
function table.slice(list,b,e,step)
	step = step or 1
	if not e then
		e = b
		b = 1
	end
	e = math.min(#list,e)
	local new_list = {}
	local len = #list
	local idx
	for i = b,e,step do
		idx = i >= 0 and i or len + i + 1
		table.insert(new_list,list[idx])
	end
	return new_list
end


--- 将字典所有值构成一个集合
--@param[type=table] tbl 字典
--@return[type=table] 集合
function table.toset(tbl)
	tbl = tbl or {}
	local set = {}
	for i,v in ipairs(tbl) do
		set[v] = true
	end
	return set
end

--- 计算2个集合的交集
--@param[type=table] set1 集合1
--@param[type=table] set2 集合2
--@return[type=table] 交集
function table.intersect_set(set1,set2)
	local set = {}
	for k in pairs(set1) do
		if set2[k] then
			set[k] = true
		end
	end
	return set
end

--- 计算2个集合的并集
--@param[type=table] set1 集合1
--@param[type=table] set2 集合2
--@return[type=table] 并集
function table.union_set(set1,set2)
	local set = {}
	for k in pairs(set1) do
		set[k] = true
	end
	for k in pairs(set2) do
		if not set1[k] then
			set[k] = true
		end
	end
	return set
end

--- 计算2个集合的差集
--@param[type=table] set1 集合1
--@param[type=table] set2 集合2
--@return[type=table] set1-set2
function table.diff_set(set1,set2)
	local ret = {}
	local set = table.intersect_set(set1,set2)
	for k in pairs(set1) do
		if not set[k] then
			ret[k] = true
		end
	end
	return ret
end

--- 判断一个表是否为数组
--@param[type=table] tbl 表
--@return[type=bool] true--是数组,false--不是数组
function table.isarray(tbl)
	if type(tbl) ~= "table" then
		return false
	end
	local k = next(tbl)
	if k == nil then -- empty table
		return true
	end
	if k ~= 1 then
		return false
	else
		k = next(tbl,#tbl)
		return k == nil and true or false
	end
end

function table.simplify(o,seen)
	local typ = type(o)
	if typ ~= "table" then return o end
	seen = seen or {}
	if seen[o] then return seen[o] end
	local newtable = {}
	seen[o] = newtable
	for k,v in pairs(o) do
		--k = tostring(k)
		local tbl = table.simplify(v,seen)
		if type(tbl) ~= "table" then
			newtable[k] = tbl
		else
			for k1,v1 in pairs(tbl) do
				newtable[k.."_"..k1] = v1
			end
		end
	end
	return newtable
end

--- 根据约束判断参数列表是否非法
--@param[type=table] args 参数列表
--@param[type=table] descs 约束表
--@param[type=bool,opt=false] strict 是否严格检查(严格检查时多余的参数也视为非法)
--@return[type=table|nil] table--参数合法,经过约束处理后的新参数列表,nil--参数非法
--@return[type=string] 第一个参数返回nil时才返回,表示参数非法原因
--@usage:
--	local args,err = table.check(args,{
--		sign = {type="string"},
--		appid = {type="string"},
--		roleid = {type="number"},
--		image = {type="string"},
--	})
function table.check(args,descs,strict)
	local cjson = require "cjson"
	local new_args = {}
	for name,value in pairs(args) do
		local desc = descs[name]
		if desc then
			if desc.type == "number" then
				local new_value = tonumber(value)
				if new_value == nil then
					return nil,string.format("<%s,%s>: 非法类型,expect '%s',got '%s'",name,value,desc.type,type(value))
				end
				new_args[name] = new_value
			elseif desc.type == "boolean" then
				local new_value
				if value == true or value == 1 or value == "true" or value == "on" or value == "yes" then
					new_value = true
				else
					new_value = false
				end
				new_args[name] = new_value
			elseif desc.type == "json" then
				local isok,new_value = pcall(cjson.decode,value)
				if not isok then
					return nil,string.format("<%s,%s>: 非法类型,expect '%s',got '%s'",name,value,desc.type,type(value))
				end
				new_args[name] = new_value
			else
				local types = string.split(desc.type,"|")
				if not table.find(types,type(value)) then
					return nil,string.format("<%s,%s>: 非法类型,expect '%s',got '%s'",name,value,desc.type,type(value))
				end
				new_args[name] = value
			end
		else
			if strict then
				return nil,string.format("<%s,%s>: 多余参数",name,value)
			else
				new_args[name] = value
			end
		end
		descs[name] = nil
	end
	if next(descs) then
		for name,desc in pairs(descs) do
			if not desc.optional then
				return nil,string.format("缺少参数: %s",name)
			else
				new_args[name] = desc.default
			end
		end
	end
	return new_args,nil
end

--- 从列表中随机选择一个值
--@param[type=table] list 列表
--@return[type=any] 命中的值
--@return[type=int] 命中值的位置
function table.choose(list)
	local len = #list
	assert(len > 0,"list length need > 0")
	local pos = math.random(1,len)
	return list[pos],pos
end

--- 根据字典的键来排序(键为字符串则用字典序排),排完后再拼接成字符串
--@param[type=table] dict 字典
--@param[type=string,opt="&"] join_str 拼接时用的连接字符
--@param[type=table,opt={}] exclude_keys 排除的键
--@param[type=table,opt={}] exclude_values 排除的值
--@return[type=string] 排序+拼接后的最终字符串
--@usage
--local dict = {k1 = 1,k2 = 2}
--local str = table.ksort(dict,"&")	-- k1=1&k2=2
function table.ksort(dict,join_str,exclude_keys,exclude_values)
	join_str = join_str or "&"
	exclude_keys = exclude_keys or {}
	exclude_values = exclude_values or {}
	local list = {}
	for k,v in pairs(dict) do
		if (not exclude_keys or not exclude_keys[k]) and
			(not exclude_values or not exclude_values[v]) then
			table.insert(list,{k,v})
		end
	end
	table.sort(list,function (lhs,rhs)
		return lhs[1] < rhs[1]
	end)
	local list2 = {}
	for i,item in ipairs(list) do
		table.insert(list2,string.format("%s=%s",item[1],item[2]))
	end
	return table.concat(list2,join_str)
end

--- 清空表
--@param[type=table] tbl 表
function table.clear(tbl)
	for k,v in pairs(tbl) do
		rawset(tbl,k,nil)
	end
end

