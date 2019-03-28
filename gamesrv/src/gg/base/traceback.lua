--[[
Path : ltrace.lua
Author : Roc <RocAltair@gmail.com>
CreateTime : 2016-01-21 19:15:34
Description : Description
--]]

local IS_LUAJIT = jit and true or false

local ltrace_getenv
local getstack_from
local getstack
local dumpvalue
local dumptable
local dumpframe
local dumpstack
local getfulltrace

local mTABLE_MAX_DEEP = 3
local mVALUE_MAX_LEN = 5120
local traceback = {}

local setfenv = _G.setfenv or function(f, t)
	f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
	local name
	local up = 0 
	repeat
		up = up + 1 
		name = debug.getupvalue(f, up) 
	until name == '_ENV' or name == nil 
	if name then
		debug.upvaluejoin(f, up, function() return name end, 1)  -- use unique upvalue
		debug.setupvalue(f, up, t)
	end 
	return f
end

local getfenv = _G.getfenv or function(f)
	f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
	local name, val 
	local up = 0 
	repeat
		up = up + 1 
		name, val = debug.getupvalue(f, up) 
	until name == '_ENV' or name == nil 
	return val 
end

local function canPrint(k, v)
	if type(v) ~= "table" then
		return true
	end
	if v == _G then
		return false
	end
	return true
end

function ltrace_getenv(realframe)
	local env = {}
	local indexmap = {}
	local i = 1
	local funcinfo = debug.getinfo(realframe, "nlSf")
	if not funcinfo then
		return
	end
	local k, v = debug.getlocal(realframe, i)
	while k do
		indexmap[k] = i
		env[k] = v
		i = i + 1
		k, v = debug.getlocal(realframe, i)
	end

	setmetatable(env, {__index = getfenv(funcinfo.func)})
	return env, funcinfo, indexmap
end

function getstack_from(callfile, callline, maxframesz)
	assert(callfile and callline)
	local realframe = 0
	local framestack = {}
	local env, funcinfo, indexmap = ltrace_getenv(realframe)
	while funcinfo do
		if funcinfo.currentline == callline and funcinfo.short_src == callfile then
			break
		end
		realframe = realframe + 1
		env, funcinfo, indexmap = ltrace_getenv(realframe)
	end
	while funcinfo do
		realframe = realframe + 1
		env, funcinfo, indexmap = ltrace_getenv(realframe)
		if not funcinfo then
			break
		end
		table.insert(framestack, {
			realframe = realframe,
			env = env,
			funcinfo = funcinfo,
			indexmap = indexmap,
		})
		if maxframesz and #framestack >= maxframesz then
			break
		end
	end
	return framestack
end

local function get_params(func)
	if not IS_LUAJIT or _VERSION <= "Lua 5.1" then
		return {}, -1, false
	end
	local info = debug.getinfo(func, "u")
	if not info then return end
	local argNameList = {}
	for i = 1, info.nparams do
		local name = debug.getlocal(func, i)
		table.insert(argNameList, name)
	end
	if info.isvararg then
		table.insert(argNameList, "...")
	end
	return argNameList, info.nparams, info.isvararg
end

local uncomparedTypeMap = {
	["table"] = true,
	["userdata"] = true,
	["function"] = true,
	["boolean"] = true,
	["thread"] = true,
}

local function compare(a, b)
	local ta = type(a)
	local tb = type(b)
	if ta ~= tb or uncomparedTypeMap[ta] or uncomparedTypeMap[tb] then
		return tostring(a) < tostring(b)
	end
	return a < b
end

local function pairs_orderly(t, comp)
	comp = comp or compare
	local keys = {}
	for k, v in pairs(t) do
		table.insert(keys, k)
	end
	local size = #keys
	table.sort(keys, comp)

	local i = 0
	return function(tbl, k)
		i = i + 1
		if i > size then
			return
		end
		return keys[i], t[keys[i]]
	end
end

local ignoreMap = {
}

function dumptable(value, depth)
	assert(type(value) == "table")
	local tostr
	local meta = getmetatable(value)
	if meta and meta.__tostring then
		tostr = meta.__tostring
	elseif value.__tostring then
		tostr = value.__tostring
	end
	if tostr then
		return tostr(value)
	end
	local rettbl = {}
	depth = (depth or 0) + 1
	if depth > mTABLE_MAX_DEEP then
		return "{...}"
	end

	table.insert(rettbl, '{')
	local content = {}
	for k, v in pairs_orderly(value) do
		if not ignoreMap[k] and canPrint(k, v) then
			local line = {}
			table.insert(line, dumpkey(k, depth) .. "=")
			table.insert(line, dumpvalue(v, depth))
			table.insert(content, table.concat(line))
		end
	end
	table.insert(rettbl, table.concat(content, ", "))
	table.insert(rettbl, '}')
	return table.concat(rettbl)
end

function dumpkey(key, depth)
	local vtype = type(key)
	if vtype == "table" then
		return "[" .. dumptable(key, depth) .. "]"
	elseif vtype == "string" then
		if key:match("^%d") or  key:match("%w+") ~= key then
			return "[" .. string.format("%q", key) .. "]"
		end
		return tostring(key)
	end
	return "[" .. tostring(key) .. "]"
end

function dumpvalue(v, depth)
	local vtype = type(v)
	if vtype == "table" then
		return dumptable(v, depth)
	elseif vtype == "string" then
		return string.format("%q", v)
	elseif vtype == "number" or vtype == "boolean" then
		return tostring(v)
	end
	return string.format("<%s>", tostring(v))
end


function dumpframe(frameidx, env, funcinfo, indexmap)
	local fix = -1
	if funcinfo.what ~= "Lua" then
		return string.format("%d[C] : in <%s>",
			     frameidx + fix,
			     funcinfo.name or funcinfo.what or funcinfo.namewhat
			     )
	end

	local out = {}
	local args = get_params(funcinfo.func)
	local funcstr = ""
	if funcinfo.name then
		funcstr = string.format("in <%s(%s)>",
					funcinfo.name,
					table.concat(args, ","))
	end
	table.insert(out,
		     string.format("%d @%s:%d %s",
		     frameidx + fix,
		     funcinfo.short_src or "<stdin>",
		     funcinfo.currentline,
		     funcstr))

	local valuelines = {}
	local function compare(k1, k2)
		return indexmap[k1] < indexmap[k2]
	end
	for k, v in pairs_orderly(env, compare) do
		if canPrint(k, v) then
			local vs = dumpvalue(v)
			if #vs > mVALUE_MAX_LEN then
				vs = vs:sub(1, mVALUE_MAX_LEN) .. "..."
			end
			-- table.insert(valuelines, string.format("\t%s<%s>:%s", k, indexmap[k] or "", vs))
			table.insert(valuelines, string.format("\t%s:%s", k, vs))
		end
	end

	table.insert(out, table.concat(valuelines, "\n"))
	return table.concat(out, "\n")
end

function dumpstack(stack)
	local list = {}
	for i, v in pairs(stack) do
		local s = dumpframe(i, v.env, v.funcinfo, v.indexmap)
		table.insert(list, s)
	end
	return list
end

function getstack(level, maxframesz)
	level = level or 2
	local info = debug.getinfo(level, "nlSf")
	local stacklist = getstack_from(info.short_src, info.currentline, maxframesz)
	return stacklist
end

function getfulltrace(level, maxframesz)
	local fullstack = getstack(level, maxframesz)
	local list = dumpstack(fullstack)
	local ret = {}
	for i, v in pairs(list) do
		table.insert(ret, v)
	end
	return table.concat(ret, "\n")
end

function settdmaxdeep(depth)
	mTABLE_MAX_DEEP = depth or mTABLE_MAX_DEEP
end

function setvdmaxlen(len)
	mVALUE_MAX_LEN = len or mVALUE_MAX_LEN
end

traceback.setvdmaxlen = setvdmaxlen
traceback.settdmaxdeep = settdmaxdeep
traceback.getenv = getenv
traceback.getstack_from = getstack_from
traceback.getstack = getstack
traceback.dumpvalue = dumpvalue
traceback.dumptable = dumptable
traceback.dumpframe = dumpframe
traceback.dumpstack = dumpstack
traceback.getfulltrace = getfulltrace

return traceback
