local function collect_uv(func_id,func,uv)
    local i = 1
    while true do
        local name,value = debug.getupvalue(func,i)
        if name == nil then
            return
        end
        if name ~= "_ENV" then
            if not uv[func_id] then
                uv[func_id] = {"function",}
            end
            uv[func_id][name] = {
                func = func,
                upvalueid = debug.upvalueid(func,i),
                index = i,
            }
        end
        i = i + 1
    end
end

local function collect_all_uv(module,uv,mark)
    mark = mark or {}
    if mark[module] then
        return
    end
    mark[module] = true
    for k,v in pairs(module) do
        local typ = type(v)
        if typ == "function" then
            collect_uv(k,v,uv)
        elseif typ == "table" then
            uv[k] = {}
            collect_all_uv(v,uv[k],mark)
        end
    end
end

-- 将uv2中函数的upvalue值绑定为uv1中同名函数的旧值
-- 即upvalue值都不会热更(因此尽量避免在模块级别定义local函数)
local function merge_uv(uv1,uv2,name)
    for k,upvalue_info2 in pairs(uv2) do
        local upvalue_info1 = uv1[k]
        if upvalue_info1 then
            if upvalue_info2[1] == "function" then
                if upvalue_info1[1] ~= "function" then
                    return false,string.format("[merge_uv] mismatch,name=%s,key=%s",name,k)
                end
                for func_id,upvalue2 in pairs(upvalue_info2) do
                    if func_id ~= 1 then
                        local upvalue1 = upvalue_info1[func_id]
                        if upvalue1 and upvalue1.func ~= upvalue2.func then
                            debug.upvaluejoin(upvalue2.func,upvalue2.index,upvalue1.func,upvalue1.index)
                        end
                    end
                end
            else
                local ok,errmsg = merge_uv(upvalue_info1,upvalue_info2,name .. "." .. k)
                if not ok then
                    return false,errmsg
                end
            end
        end
    end
    return true
end

-- 将tbl2中函数替换tbl1中函数(递归进行),其他属性不替换
-- 另外tbl2中新增的属性直接复制到tbl1中
local function merge_func(tbl1,tbl2,name,cache)
    -- 返回的模块是全局定义/被全局管理时会相等
    if tbl1 == tbl2 then
        return true
    end
    cache = cache or {[tbl2] = name}
    for k,v2 in pairs(tbl2) do
        local v1 = tbl1[k]
        local typ1 = type(v1)
        local typ2 = type(v2)
        if typ1 == "nil" then
            tbl1[k] = v2
        elseif typ1 == "function" then
            if typ2 ~= "function" then
                return false,string.format("[merge_func] mismatch func type,name=%s,key=%s",name,k)
            end
            tbl1[k] = v2
        elseif typ1 == "table" then
            if typ2 ~= "table" then
                return false,string.format("[merge_func] mismatch table type,name=%s,key=%s",name,k)
            end
            if not cache[v2] then
                local ok,errmsg = merge_func(v1,v2,name .. "." .. k,cache)
                if not ok then
                    return false,errmsg
                end
            end
        end
    end
    return true
end

---热更模块
--@param[type=string] modname 模块名
--@return 热更成功返回true,失败返回false和错误消息
--@usage gg.reload("gg.base.reload")
--只支持简单热更,主要策略是: 只更新模块的函数,其他数据
--不更新,函数绑定的upvalue值也不更新,因此上层代码需要按
--一定规范书写,比如模块定义要么无返回,要么返回table,当
--模块为一个table时,模块所用到的数据均应放到模块变量内,
--另外我们不鼓励在模块级别定义local函数,因为upvalue都不
--更新,我们假定函数绑定的upvalue都应该是数据,upvalue中的
--函数是热更不了的,另外如果模块内定义了全局函数__hotfix,
--热更后会自动回调(传递旧模块对象),你可以在该函数内自定义
--热更后的逻辑
function gg.reload(module_name)
    local chunk,err
    local env = _ENV or _G
    env.__hotfix = nil
    local filename = package.searchpath(module_name,package.path)
    if filename then
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
    local ok,new_module = pcall(chunk)
    if not ok then
        return false,new_module
    end
    -- 模块无返回值时,lua会在package.loaded中存true
    if new_module == nil then
        new_module = true
    end
    local old_module = package.loaded[module_name]
    if old_module == nil or old_module == true then
        old_module = new_module
        package.loaded[module_name] = old_module
        if type(env.__hotfix) == "function" then
            env.__hotfix(old_module)
        end
        return true
    end
    if type(old_module) ~= type(new_module) then
        return false,"[reload_module] mismatch module type"
    end
    -- 不是返回table,说明模块中只有全局定义才能被外界访问
    if type(old_module) ~= "table" then
        if type(env.__hotfix) == "function" then
            env.__hotfix(old_module)
        end
        return true
    end
    -- 将新模块所有函数的upvalue值绑定旧模块相同函数的对应upvalue值
    local uv1 = {}
    local uv2 = {}
    collect_all_uv(old_module,uv1)
    collect_all_uv(new_module,uv2)
    local ok,errmsg = merge_uv(uv1,uv2,module_name)
    if not ok then
        return false,errmsg
    end
    local ok,errmsg
    if gg.safe_reloads and gg.safe_reloads[module_name] then
        -- 如果已被标记为,则全量覆盖
        ok = true
        for k,v in pairs(new_module) do
            old_module[k] = v
        end
    else
        -- 否则,保留旧模块对象,将新模块非数据属性(函数)覆盖旧模块
        ok,errmsg = merge_func(old_module,new_module,module_name)
    end
    if not ok then
        return false,errmsg
    end
    if type(env.__hotfix) == "function" then
        env.__hotfix(old_module)
    end
    return true
end
