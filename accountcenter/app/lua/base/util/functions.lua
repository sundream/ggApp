--- 基础全局函数
--@script base.util.function
--@author sundream
--@release 2018/12/25 10:30:00

--- 浅复制(元表会共享)
--@param[type=any] o 对象
--@return[type=any] 经过浅复制后的对象
function copy(o)
	local typ = type(o)
	if typ ~= "table" then return o end
	local newtable = {}
	for k,v in pairs(o) do
		newtable[k] = v
	end
	return setmetatable(newtable,getmetatable(o))
end


--- 深复制(元表会共享)
--@param[type=any] o 对象
--@return[type=any] 经过深复制后的对象
--@usage
-- deepcopy解决了以下3个问题:
-- 1. table存在循环引用
-- 2. metatable(metatable都不参与复制)
-- 3. keys也是table
function deepcopy(o,seen)
	local typ = type(o)
	if typ ~= "table" then return o end
	seen = seen or {}
	if seen[o] then return seen[o] end
	local newtable = {}
	seen[o] = newtable
	for k,v in pairs(o) do
		newtable[deepcopy(k,seen)] = deepcopy(v,seen)
	end
	return setmetatable(newtable,getmetatable(o))
end

--- 概率是否命中
--@param[type=int] num 概率大小
--@param[type=int,opt=1000000] limit 概率基数
--@return[type=bool] true--概率命中,false--概率未命中
--@usage local ok = ishit(1,2)	-- 1/2概率命中
--@usage local ok = ishit(1)	-- 1/1000000概率命中
function ishit(num,limit)
	limit = limit or 1000000
	assert(limit >= num)
	return math.random(1,limit) <= num
end

--- 洗牌(注意:会直接修改list)
--@param[type=table] list 列表
--@return[type=table] 洗牌后的列表
function shuffle(list)
	local len = #list
	for i=1,len do
		local idx = math.random(i,len)
		local tmp = list[idx]
		list[idx] = list[i]
		list[i] = tmp
	end
	return list
end

--- 从概率表中选择值
--@param[type=table] dct 概率表,格式:{[概率1]=值1,[概率2]=值2,...}
--@param[type=func,opt] func 计算每项元素出现概率的函数,不指定每项元素的概率为他的键
--@return[type=any] 根据概率选择出来的值
--@usage
--	local dct = {[1]="one",[2]="two",[7]="seven"}		-- 总概率:1+2+7=10
--	-- one=1/10概率,two=2/10概率,seven=7/10概率
--	local val = choosevalue(dct)
--	-- 由于概率经过了修改,控制了"one"出现概率为0，故宗概率:2+7=9
--	-- 因此: one=0/9概率,two=2/9概率,seven=7/9概率
--	local val = choosevalue(dct,function (k,v) return v == "one" and 0 or k end)
function choosevalue(dct,func)
	local sum = 0
	for ratio,val in pairs(dct) do
		sum = sum + (func and func(ratio,val) or ratio)
	end
	local hit = math.random(1,sum)
	local limit = 0
	for ratio,val in pairs(dct) do
		limit = limit + (func and func(ratio,val) or ratio)
		if hit <= limit then
			return val
		end
	end
	return nil
end

--- 从概率表中选择键
--@param[type=table] dct 概率表,格式:{[键1]=概率1,[键2]=概率2,...}
--@param[type=func,opt] func 计算每项元素出现概率的函数,不指定每项元素的概率为他的值
--@return[type=any] 根据概率选择出来的键
--@usage
--	local dct = {one=1,two=2,seven=7}		-- 总概率:1+2+7=10
--	-- one=1/10概率,two=2/10概率,seven=7/10概率
--	local val = choosekey(dct)
--	-- 由于概率经过了修改,控制了"one"出现概率为0，故宗概率:2+7=9
--	-- 因此: one=0/9概率,two=2/9概率,seven=7/9概率
--	local val = choosekey(dct,function (k,v) return k == "one" and 0 or v end)
function choosekey(dct,func)
	local sum = 0
	for key,ratio in pairs(dct) do
		sum = sum + (func and func(key,ratio) or ratio)
	end
	assert(sum >= 1,"[choosekey] Invalid sum ratio:" .. tostring(sum))
	local hit = math.random(1,sum)
	local limit = 0
	for key,ratio in pairs(dct) do
		limit = limit + (func and func(key,ratio) or ratio)
		if hit <= limit then
			return key
		end
	end
	return nil
end

--- 根据规则检查参数列表
--@param[type=table] args 参数列表
--@param ... 检查规则
--@return[type=bool] true--检查通过,false--检查未通过
--@return[type=table|string] 检查通过时(table):经过规则修正后的参数列表,未通过(string):未通过原因
--@usage
-- -- 检查: 第一个参数为string,第二个参数为int/可以转成int
-- local isok,args = checkargs(args,"string","int")
-- -- 检查: 第一个参数为string,第二个参数为int/可以转成int,后续还允许0/多个参数
-- local isok,args = checkargs(args,"string","int","*")
-- -- 检查: 第一个参数为string,第二个参数为int/可以转成int,范围限制在[1,5]
-- local isok,args = checkargs(args,"string","int:[1,5]")
-- -- 检查: 第一个参数为string,第二个参数为double/可以转成double,范围限制在[3.5,5.5]
-- local isok,args = checkargs(args,"string","double:[3.5,5.5]")
function checkargs(args,...)
	local typs = {...}
	if #typs == 0 then
		return true,args
	end
	local ret = {}
	for i = 1,#typs do
		if typs[i] == "*" then -- ignore check
			for j=i,#args do
				table.insert(ret,args[j])
			end
			return true,ret
		end
		if not args[i] then
			return nil,string.format("argument not enough(%d < %d)",#args,#typs)
		end
		local typ = typs[i]
		local range_begin,range_end
		local val
		local pos = string.find(typ,":")
		if pos then
			local precision = typ:sub(pos+1)
			typ = typ:sub(1,pos-1)
			range_begin,range_end = string.match(precision,"%[([%d.]*),([%d.]*)%]")
			if not range_begin then
				range_begin = math.mininteger
			end
			if not range_end then
				range_end = math.maxinteger
			end
			range_begin,range_end = tonumber(range_begin),tonumber(range_end)
		end
		if typ == "int" or typ == "double" then
			val = tonumber(args[i])
			if not val then
				return false,"invalid number:" .. tostring(args[i])
			end
			if typ == "int" then
				val = math.floor(val)
			end
			if range_begin and range_end then
				if not (range_begin <= val and val <= range_end) then
					return false,string.format("%s not in range [%s,%s]",val,range_begin,range_end)
				end
			end
			table.insert(ret,val)
		elseif typ == "boolean" then
			typ = string.lower(typ)
			if not (typ == "true" or typ == "false" or typ == "1" or typ == "0") then
				return false,"invalid boolean:" .. tostring(typ)
			end
			val = (typ == "true" or typ == "1") and true or false
			table.insert(ret,val)
		elseif typ == "string" then
			val = tostring(args[i])
			table.insert(ret,val)
		else
			return false,"unknow type:" ..tostring(typ)
		end
	end
	return true,ret
end

--- 判断一个值是否为真
--@usage
--真的定义:
--	1. 对于数值: 非0--真,0--假
--	2. 对于字符串: true或者yes--真,其余--假
--	3. 对于布尔型: true--真,false--假
--	4. 其他类型: 均为假
function istrue(val)
	if val then
		if type(val) == "number" then
			return val ~= 0
		elseif type(val) == "string" then
			val = string.lower(val)
			return val == "true" or val == "yes"
		elseif type(val) == "boolean" then
			return val
		end
	end
	return false
end

-- pack_function/unpack_function [START]
local function getcmd(t,cmd)
	local _cmd = string.format("return %s",cmd)
	t[cmd] = load(_cmd,"=(load)","bt",_G)
	return t[cmd]
end
local compile_cmd = setmetatable({},{__index=getcmd})


--- 打包一个函数
--@param[type=string] cmd 获取函数的方式,如"string.len"
--@param ... 函数参数
--@return[type=table]
--@usage
--	local pack_data = pack_function("string.len","hello")
--	local func = unpack_function(pack_data)
--	local len = func()	-- string.len("hello") => 5
function pack_function(cmd,...)
	-- 保证最后一个参数为nil时不丢失
	local n = select("#",...)
	local args = {...}
	local pack_data = {
		cmd = cmd,
		args = args,
		n = n,
	}
	return pack_data
end

--- 解包成一个函数
--@param[type=table] pack_data 由pack_function生成的数据
--@return[type=func] 可执行的函数
--@usage
--	local pack_data = pack_function("string.len","hello")
--	local func = unpack_function(pack_data)
--	local len = func()	-- string.len("hello") => 5
function unpack_function(pack_data)
	local cmd = pack_data.cmd
	local attrname,sep,funcname = string.match(cmd,"^(.*)([.:])(.+)$")
	-- e.g: cmd = print
	if not sep then
		attrname = "_G"
		sep = "."
		funcname = cmd
	end
	local args = pack_data.args
	local n = pack_data.n
	--local loadstr = string.format("return %s",attrname)
	--local chunk = load(loadstr,"(=load)","bt",_G)
	local chunk = compile_cmd[attrname]
	local caller = chunk()
	if sep == "." then
		return function ()
			local method = caller[funcname]
			return method(table.unpack(args,1,n))
		end
	else
		assert(sep == ":")
		return function ()
			local method = caller[funcname]
			return method(caller,table.unpack(args,1,n))
		end
	end
end

-- pack_function/unpack_function [END]

--- 执行指定模块的指定方法
--@param[type=table|string] mod table:载入的模块,string:模块名
--@param[type=string] method 方法名(支持"."分层+":")
--@param ... 执行方法的参数
--@return 方法执行后的返回值
--@usage
--	local len = exec(_G,"string.len","hello") -- 5
function exec(mod,method,...)
	if type(mod) == "string" then
		mod = require (mod)
	end
	local attrname,sep,funcname = string.match(method,"^(.*)([.:])(.+)$")
	if sep == nil then
		attrname = ""
		sep = "."
		funcname = method
	end
	local caller
	if attrname ~= "" then
		local firstchar = attrname:sub(1,1)
		if firstchar == "." or firstchar == ":" then
			attrname = attrname:sub(2)
		else
			firstchar = "."
		end
		caller = table.getattr(mod,attrname)
		if not caller then
			local cmd = string.format("return _M%s%s",firstchar,attrname)
			local chunk = load(cmd,"=(load)","bt",{_M=mod})
			caller = chunk()
		end
	else
		caller = mod
	end
	local func = caller[funcname]
	if sep == "." then
		if type(func) == "function" then
			return func(...)
		else
			assert(select("#",...)==0,string.format("mod:%s,method:%s",mod,method))
			return func
		end
	else
		assert(sep == ":")
		return func(caller,...)
	end
end

--- 执行指定代码
--@param[type=string] code 代码
--@param[type=table] env 执行环境
--@return 执行这段代码后的返回值
--@usage
--	local code = "return string.len('hello')"
--	local len = execcode(code)	-- 5
function execcode(code,env)
	local chunk
	if env == nil then
		chunk = load(code,"=(load)","bt")
	else
		chunk = load(code,"=(load)","bt",env)
	end
	return chunk()
end
