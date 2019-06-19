local crandom = class("crandom")

---gg.class.crandom.new的构造函数
--@param[type=int,opt] 随机种子
--@usage
--线性同余方法生成伪随机数
--参考: https://zh.wikipedia.org/wiki/伪随机性
function crandom:init(seed)
    seed = seed or os.time()
    self.next_value = seed
end

---设置随机种子
--@param[type=int] seed 随机种子
function crandom:seed(seed)
    self.next_value = seed
end

function crandom:_random()
	self.next_value = self.next_value * 1103515245 + 12345
	return ((self.next_value / 65536) % 32768) / 32768
end

---在指定范围内随机,类似于math.random
--@param[type=int,opt] min 最小区间
--@param[type=int,opt] max 最大区间
--@return[type=int|double] 随机值
--@usage
--如果不指定min,max,则在[0,1]之间随机,如果不指定m,则在[1,n]之间随机,
--否则在[min,max]之间随机.传入的min,max必须为正整数值并且max>=min
function crandom:random(min,max)
    if min == nil and max == nil then
        min = 0
        max = 1
    elseif max == nil then
        min = 1
        max = min
    end
    assert(type(min) == "number")
    assert(type(max) == "number")
    local value = self:_random()
    if not (min == 0 and max == 1) then
        assert(min >= 0)
        assert(max >= min)
        local diff = max - min + 1
        value = math.floor(value * diff + min)
    end
    return value
end

-- 扩展函数

function crandom:choose(list)
    return table.choose(list,function (min,max)
        return self:random(min,max)
    end)
end

function crandom:ishit(num,limit)
    return gg.ishit(num,limit,function (min,max)
        return self:random(min,max)
    end)
end

function crandom:shuffle(list,num)
    return gg.shuffle(list,num,function (min,max)
        return self:random(min,max)
    end)
end

function crandom:choosekey(dct,func)
    return gg.choosekey(dct,func,function (min,max)
        return self:random(min,max)
    end)
end

function crandom:choosevalue(dct,func)
    return gg.choosevalue(dct,func,function (min,max)
        return self:random(min,max)
    end)
end

return crandom
