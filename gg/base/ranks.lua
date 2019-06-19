local cranks = class("cranks")

--- 排行榜,插入排序实现,关键字和比较字段只支持整数、字符串,10000以内排名效率较好
--@usage
--创建一个以pid字段为关键字,score降序,lv降序的排行榜
--local rank = gg.class.cranks.new("test",{"pid"},{
-- {key="score",desc=true,}
-- {key="lv",desc=true,},
--})
function cranks:init(name,ids,sortids,param)
    self.name = name
    self.ids = ids
    assert(#sortids >= 1 and sortids[1].key)
    self.sortids = sortids
    if param then
        -- 无limit表示排行榜大小不受限制
        if param.limit then
            self.limit = param.limit
            self.maxlimit = param.maxlimit or self.limit * 2
        end
        if param.callback then
            self:register(param.callback)
        end
    end
    self.length = 0
    self.ranks = {}    -- pos:rank
    self.id_rank = {} -- id:rank
end

function cranks:__id(ids)
    return table.concat(ids,"#")
end

function cranks:get_ids(rank)
    local tbl = {}
    for i,key in ipairs(self.ids) do
        local v = assert(self:getattr(rank,key))
        table.insert(tbl,v)
    end
    return tbl
end

function cranks:id(rank)
    local tbl = self:get_ids(rank)
    return self:__id(tbl)
end

-- 支持带"."的级联字段
function cranks:getattr(rank,attrs)
    local mod = rank
    for attr in string.gmatch(attrs,"([^.]+)%.?") do
        if mod[attr] ~= nil then
            mod = mod[attr]
        else
            return
        end
    end
    local typ = type(mod)
    assert(typ=="number" or typ=="string")
    return mod
end

-- <0--rank1需要排在rank2前面，0--rank1和rank2相等,>0--rank1需要排在rank2后面
function cranks:cmp(rank1,rank2)
    local cmpvals1 = {}
    for i,sortinfo in ipairs(self.sortids) do
        table.insert(cmpvals1,self:getattr(rank1,sortinfo.key) or false)
    end
    local cmpvals2 = {}
    for i,sortinfo in ipairs(self.sortids) do
        table.insert(cmpvals2,self:getattr(rank2,sortinfo.key) or false)
    end
    local length = #cmpvals1

    for i = 1,length do
        if not cmpvals1[i] then
            return 1
        elseif not cmpvals2[i] then
            return -1
        else
            local sortinfo = assert(self.sortids[i])
            if sortinfo.desc then
                if cmpvals1[i] > cmpvals2[i] then
                    return -1
                elseif cmpvals1[i] < cmpvals2[i] then
                    return 1
                end
            else
                if cmpvals1[i] < cmpvals2[i] then
                    return -1
                elseif cmpvals1[i] > cmpvals2[i] then
                    return 1
                end
            end
        end
    end
    return 0
end

--[[
    ranks = cranks.new(...)
    ranks:register({
        onadd = xxx,
        ondel = xxx,
        onupdate = xxx,
    })
]]
function cranks:register(callback)
    for k,func in pairs(callback) do
        if k == "onadd" or
            k == "ondel" or
            k == "onupdate" or
            k == "onclear" or
            k == "id" or
            k == "cmp" then
            assert(type(func) == "function")
            self[k] = func
        end
    end
end

function cranks:len()
    return self.length
end

-- 对外简洁接口
function cranks:addorupdate(rank)
    local id = self:id(rank)
    if self:__get(id) then
        return self:update(rank)
    else
        return self:add(rank)
    end
end

-- 根据id获取
-- 格式:1. ranks:get(id1,id2,...) 2. ranks:get({id1,id2,...})
function cranks:get(...)
    local id1 = ...
    local ids = table.pack(...)
    if type(id1) == "table" then
        assert(#ids==1)
        ids=id1
    end
    return self:__get(self:__id(ids))
end

function cranks:getbypos(pos)
    return self.ranks[pos]
end

function cranks:__get(id,ispos)
    return ispos and self.ranks[id] or self.id_rank[id]
end

function cranks:add(rank)
    local id = self:id(rank)
    assert(self.id_rank[id]==nil,"Exists id:" .. tostring(id))
    local length = self:len()
    if length > 0 and self:cmp(self.ranks[length],rank) <= 0 then
        if self.maxlimit and length >= self.maxlimit then
            return
        end
    else
        if self.maxlimit and length >= self.maxlimit then
            self:delbypos(length)
        end
        length = self:len()
    end
    self.id_rank[id] = rank
    self.length = length + 1
    rank.pos = self.length
    self.ranks[rank.pos] = rank
    self:__sort(rank.pos,1)
    if self.onadd then
        self:onadd(rank)
    end
    return rank
end

function cranks:del(...)
    local id1 = ...
    local ids = table.pack(...)
    if type(id1) == "table" then
        assert(#ids==1)
        ids=id1
    end
    local id = self:__id(ids)
    local rank = self.id_rank[id]
    if rank then
        return self:__del(rank)
    end
end

function cranks:delbypos(pos)
    local rank = self.ranks[pos]
    if rank then
        return self:__del(rank)
    end
end

function cranks:__del(rank)
    local id = self:id(rank)
    local length = self:len()
    local pos = rank.pos
    self.id_rank[id] = nil
    for i=pos,length-1 do
        self.ranks[i+1].pos = i
        self.ranks[i] = self.ranks[i+1]
    end
    self.ranks[length] = nil
    self.length = length - 1
    if self.ondel then
        self:ondel(rank)
    end
    return rank
end

function cranks:update(newrank)
    local id = self:id(newrank)
    local rank = self.id_rank[id]
    if not rank then
        return
    end
    local oldpos = rank.pos
    for k,v in pairs(newrank) do
        if k ~= "pos" then
            rank[k] = v
        end
    end
    -- 插入排序
    if self.ranks[oldpos-1] and self:cmp(self.ranks[oldpos-1],rank) > 0 then -- 尝试前移
        self:__sort(oldpos,1)
    elseif self.ranks[oldpos+1] and self:cmp(self.ranks[oldpos+1],rank) < 0 then -- 尝试后移
        self:__sort(oldpos,self:len())
    end
    if self.onupdate then
        self:onupdate(rank,oldpos)
    end
    return rank
end

function cranks:__sort(startpos,endpos)
    --print(startpos,endpos)
    local isgohead = startpos >= endpos
    local rank = self.ranks[startpos]
    assert(rank.pos==startpos,string.format("%s ~= %s",rank.pos,startpos))
    local newpos = endpos
    if isgohead then
        for i = startpos-1,endpos,-1 do
            if self:cmp(self.ranks[i],rank) > 0 then
                self.ranks[i].pos = i+1
                self.ranks[i+1] = self.ranks[i]
            else
                newpos = i + 1
                break
            end
        end
    else
        for i = startpos,endpos-1 do
            if self:cmp(self.ranks[i+1],rank) < 0 then
                self.ranks[i+1].pos = i
                self.ranks[i] = self.ranks[i+1]
            else
                newpos = i
                break
            end
        end
    end
    if newpos ~= rank.pos then
        rank.pos = newpos
        self.ranks[rank.pos] = rank
    end
end

function cranks:clear()
    self.length = 0
    self.ranks = {}    -- pos:rank
    self.id_rank = {} -- id:rank
    if self.onclear then
        self:onclear()
    end
end

-- 存盘相关
function cranks:unserilize(data)
    if not data or not next(data) then
        return
    end
--  self.name = data.name
--  self.ids = data.ids
--  self.sortids = data.sortids
    self.ranks = data.ranks
    self.length = #self.ranks
    for i,rank in ipairs(self.ranks) do
        local id = self:id(rank)
        self.id_rank[id] = rank
    end
end

function cranks:serialize()
    local data = {}
    data.name = self.name
    data.ids = self.ids
    data.sortids = self.sortids
    data.ranks = self.ranks
    return data
end

return cranks
