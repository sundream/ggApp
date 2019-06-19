-- 双端队列
local cdeque = class("cdeque")

function cdeque:init(conf)
    self.objs = {}
    self.first = 0
    self.last = -1
end

function cdeque:save(savefunc)
    local data = {}
    data.first = self.first
    data.last = self.last
    local objs = {}
    for idx,obj in pairs(self.objs) do
        idx = tostring(idx)
        if savefunc then
            objs[idx] = savefunc(obj)
        else
            objs[idx] = obj
        end
    end
    data.objs = objs
    return data
end

function cdeque:load(data,loadfunc)
    if table.isempty(data) then
        return
    end
    self.first = data.first
    self.last = data.last
    for idx,objdata in pairs(data.objs) do
        idx = tonumber(idx)
        if loadfunc then
            self.objs[idx] = loadfunc(objdata)
        else
            self.objs[idx] = objdata
        end
    end
end

function cdeque:push(obj)
    self.last = self.last + 1
    self.objs[self.last] = obj
end

function cdeque:pushleft(obj)
    self.first = self.first - 1
    self.objs[self.first] = obj
end

function cdeque:clear()
    local objs = self.objs
    self.objs = {}
    self.first = 0
    self.last = -1
    for _,obj in pairs(objs) do
        if type(obj) == "table" and type(obj.clear) == "function" then
            obj:clear()
        end
    end
end

function cdeque:count()
    return self.last - self.first + 1
end

function cdeque:extend(tbl)
    if not table.isarray(tbl) then
        return
    end
    for _,obj in ipairs(tbl) do
        self:push(obj)
    end
end

function cdeque:extendleft(tbl)
    if not table.isarray(tbl) then
        return
    end
    for _,obj in ipairs(tbl) do
        self:pushleft(obj)
    end
end

function cdeque:pop()
    assert(self.first <= self.last,"deque is empty")
    local obj = self.objs[self.last]
    self.objs[self.last] = nil
    self.last = self.last - 1
    return obj
end

function cdeque:popleft()
    assert(self.first <= self.last,"deque is empty")
    local obj = self.objs[self.first]
    self.objs[self.first] = nil
    self.first = self.first + 1
    return obj
end

function cdeque:del(target)
    local del_idx
    for idx,obj in pairs(self.objs) do
        if self:isequal(obj,target) then
            del_idx = idx
            break
        end
    end
    if del_idx then
        self:delbyidx(del_idx)
    end
end

function cdeque:isequal(obj1,obj2)
    return obj1 == obj2
end

function cdeque:has(target)
    for idx,obj in pairs(self.objs) do
        if self:isequal(obj,target) then
            return idx
        end
    end
    return nil
end

function cdeque:delbyidx(idx)
    if not self.objs[idx] then
        return
    end
    self.objs[idx] = nil
    for i = idx + 1,self.last do
        local obj = self.objs[i]
        self.objs[i] = nil
        self.objs[i - 1] = obj
    end
    self.last = self.last - 1
end

function cdeque:getbyidx(idx)
    return self.objs[idx]
end

function cdeque:getobjs()
    return self.objs
end

function cdeque:getobjs_byorder()
    local tbl = {}
    for idx = self.first,self.last do
        tbl.insert(self.objs[idx])
    end
    return tbl
end

function cdeque:reverse()
    local count = self:count()
    local obj,idx1,idx2
    for i = 0,math.floor(count / 2) - 1 do
        idx1 = self.first + i
        idx2 = self.last - i
        obj = self.objs[idx1]
        self.objs[idx1] = self.objs[idx2]
        self.objs[idx2] = obj
    end
end

-- 向右旋转step步，如果step小于0则向左旋转
function cdeque:rotate(step)
    step = step or 1
    local count = self:count()
    local step = step % count
    local oldobjs = self.objs
    self.objs = {}
    for oldidx = self.first,self.last do
        local offset = (oldidx - self.first + step) % count
        local newidx = self.first + offset
        self.objs[newidx] = oldobjs[oldidx]
    end
end

return cdeque
