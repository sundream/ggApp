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

function table.ksort(dict,join_str,exclude_keys,exclude_values)
    join_str = join_str or "&"
    exclude_keys = exclude_keys or {}
    exclude_values = exclude_values or {[""]=true}
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
