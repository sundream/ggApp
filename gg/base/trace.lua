local debug = debug
local print = print
local ipairs = ipairs
local pairs = pairs
local string = string
local rawget = rawget

local info = { file = {} }

local trace = {}
trace.print = print

local function setname(level)
    info.filename = debug.getinfo(level + 1,"S").short_src
    if info.file[info.filename] == nil then
        info.file[info.filename] = {}
    end
    info.var = info.file[info.filename]
end

local function split(name)
    local keys = {}
    for key in name:gmatch("[^.]+") do
        keys[#keys+1] = key
    end
    return keys
end

local function get_table_field(tbl,keys)
    for i,key in ipairs(keys) do
        if type(tbl) == "table" and tbl[key] then
            tbl = tbl[key]
        else
            return nil
        end
    end
    return tbl
end

local function is_table_field(var_name,name,v)
    if type(v) == "table" then
        local len = #name
        if var_name:sub(1,len) == name and var_name:sub(len+1,len+1) == "." then
            return true
        end
    end
    return false
end

local function make_local(index,name,is_field)
    return function()
        local _ , value = debug.getlocal(4 , index)
        if not is_field then
            return name,"local",value
        else
            local keys = split(name)
            table.remove(keys,1)
            return name,"local",get_table_field(value,keys)
        end
    end
end

local function make_upvalue(func, index,name,is_field)
    return function()
        local _, value = debug.getupvalue(func, index)
        if not is_field then
            return name,"upvalue",value
        else
            local keys = split(name)
            table.remove(keys,1)
            return name,"upvalue",get_table_field(value,keys)
        end
    end
end

local function make_global(env, name)
    return function()
        if rawget(env,name) then
            return name,"global",rawget(env,name)
        else
            local keys = split(name)
            return name,"global",get_table_field(env,keys)
        end
    end
end

local function gen_var(var_name, level)
    local i = 1
    while true do
        local name,v = debug.getlocal(5,i)
        if name == var_name then
            return make_local(i,var_name)
        end
        if is_table_field(var_name,name,v) then
            return make_local(i,var_name,true)
        end
        if name == nil then
            break
        end
        i=i+1
    end
    i = 1
    local f = debug.getinfo(5, "f").func
    while true do
        local name = debug.getupvalue(f,i)
        if name == var_name then
            return make_upvalue(f,i,var_name)
        end
        if is_table_field(var_name,name,v) then
            return make_upvalue(f,i,var_name,true)
        end
        if name == nil then
            break
        end
        i=i+1
    end
    local name,env = debug.getupvalue(f,1)
    if name == '_ENV' then
        return make_global(env, var_name)
    end
end

local function gen_vars(var, call)
    local ret = {}
    for _,k in ipairs(var) do
        local f = gen_var(k, call)
        if f then
            table.insert(ret, f)
        end
    end
    return ret
end

local function hookline(var , call, line)
    trace.print(info.filename, ":" , line)
    if info.var[line] == nil then
        info.var[line] = gen_vars(var, call)
    end

    for _,v in ipairs(info.var[line]) do
        local name , type , value = v()
        if info.last[name] ~= value then
            trace.print(name , type, value)
            info.last[name] = value
        end
    end
end

local function hook(var , level)
    local call = 0
    local index = {}
    for w in string.gmatch(var, "%S+") do
        table.insert(index,w)
    end
    local function f (mode, line)
        if mode == 'return' then
            if call <= 0 then
                debug.sethook()
                trace.on = nil
                return
            end
            setname(3)
            call = call - 1
            if call == level then
                debug.sethook(f,'crl')
            end
        elseif mode == 'call' then
            setname(2)
            call = call + 1
            if call > level then
                debug.sethook(f,'cr')
            end
        elseif mode == 'line' then
            hookline(index , call, line)
        end
    end

    return f
end

local function up(level, f)
    local call = 0
    return function(mode)
        if mode == 'return' then
            call = call + 1
            if call == level then
                setname(3)
                debug.sethook(f,'crl')
            end
        elseif mode == 'call' then
            call = call - 1
        end
    end
end

---跟踪变量变动
--@param[type=string] var 变量列表
--@param[type=int,opt] level 跟踪的深度,默认为0,表示只跟踪和调用trace.trace同层的变量变动
--@usage
--trace.trace("a b c")
--trace.trace("a b t1.k1.k2",5)
function trace.trace(var , level)
    if trace.on then
        return
    end

    trace.on = true
    info.last = {}
    debug.sethook(up(2 , hook(var or  "" , level or 0)) , 'cr')
end

---跟踪函数调用
--@param[type=int,opt] level 最大跟踪深度,默认为1
--@usage
--trace.tracecall()       -- 跟踪与调用trace.tracecall同级的所有函数调用
--trace.tracecall(5)      -- 跟踪所有函数调用,最大深度为5
function trace.tracecall(level)
    if trace.on then
        return
    end
    trace.on = true
    local function up(level,f)
        local call = 0
        return function (mode)
            if mode == "call" then
                call = call - 1
            elseif mode == "return" then
                call = call + 1
                if call == level then
                    debug.sethook(f,"cr")
                end
            end
        end
    end
    local call = 0
    local function hook(level)
        return function (mode)
            local deepth
            if mode == "call" then
                call = call + 1
                deepth = call
            elseif mode == "return" then
                deepth = call
                call = call - 1
                if call < 0 then
                    -- 调用trace.tracecall的函数返回后停止追踪
                    debug.sethook()
                    trace.on = nil
                    return
                end
            else
                -- tail call
            end
            if deepth and deepth <= level then
                local indent = string.rep(" ",deepth)
                local frame = debug.getinfo(3)
                local my_frame = debug.getinfo(2)
                local funcname = my_frame.name or string.format("(%s)",my_frame.what)
                local log = string.format("%s%s%s:%s %s %s",deepth,indent,frame.short_src,frame.currentline,funcname,mode)
                trace.print(log)
            end
        end
    end
    debug.sethook(up(2,hook(level or 1)),"cr")
end

return trace
