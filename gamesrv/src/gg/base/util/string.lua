--- string扩展
--@script gg.base.util.string
--@author sundream
--@release 2018/12/25 10:30:00

--- 剔除str的左侧空白字符,如果指定了charset，则剔除charset中的字符
--@param[type=string] str 字符串
--@param[type=table,opt] charset 待剔除的字符集,不指定则为空白字符集
--@return[type=string] 剔除后的字符串
function string.ltrim(str,charset)
	local patten
	if charset then
		patten = string.format("^[%s]+",charset)
	else
		patten = string.format("^[ \t\n\r]+")
	end
	return string.gsub(str,patten,"")
end

--- 剔除str的右侧空白字符,如果指定了charset，则剔除charset中的字符
--@param[type=string] str 字符串
--@param[type=table,opt] charset 待剔除的字符集,不指定则为空白字符集
--@return[type=string] 剔除后的字符串
function string.rtrim(str,charset)
	local patten
	if charset then
		patten = string.format("[%s]+$",charset)
	else
		patten = string.format("[ \t\n\r]+$")
	end

	return string.gsub(str,patten,"")
end

--- 剔除str的两侧空白字符,如果指定了charset，则剔除charset中的字符
--@param[type=string] str 字符串
--@param[type=table,opt] charset 待剔除的字符集,不指定则为空白字符集
--@return[type=string] 剔除后的字符串
function string.trim(str,charset)
	str = string.ltrim(str,charset)
	return string.rtrim(str,charset)
end

--- 判断是否为数字串
function string.isdigit(str)
	local ret = pcall(tonumber,str)
	return ret
end

--- 获取字符串的16进制表示
--@param[type=string] str 字符串
--@return[type=string] 16进制表示的字符串
function string.hexstr(str)
	assert(type(str) == "string")
	local len = #str
	return string.format("0x" .. string.rep("%02x",len),string.byte(str,1,len))
end

local NON_WHITECHARS_PAT = "%S+"
--- 根据分割符，将字符串拆分成字符串列表
--@param[type=string] str 字符串
--@param[type=string,opt] pat 拆分模式,默认按空白字符拆分
--@param[type=int,opt=-1] maxsplit 最大拆分次数,不指定或为-1则不受限制
--@return[type=table] 拆分后的字符串列表
--@usage
--local str = "a.b.c"
--local list = string.split(str,".",1)	-- {"a","b"}
--local list = string.split(str,".")	-- {"a","b","c"}
function string.split(str,pat,maxsplit)
	pat = pat and string.format("[^%s]+",pat) or NON_WHITECHARS_PAT
	maxsplit = maxsplit or -1
	local ret = {}
	local i = 0
	for s in string.gmatch(str,pat) do
		if not (maxsplit == -1 or i <= maxsplit) then
			break
		end
		table.insert(ret,s)
		i = i + 1
	end
	return ret
end

function string.urlencodechar(char)
	return string.format("%%%02X",string.byte(char))
end

function string.urldecodechar(hexchar)
	return string.char(tonumber(hexchar,16))
end

function string.urlencode(str,patten)
	patten = patten or "([^A-Za-z0-9.-_])"
	str = string.gsub(str,patten,string.urlencodechar)
	return str
end

function string.urldecode(str)
	str = string.gsub(str,"%%(%x%x)",string.urldecodechar)
	return str
end

local UTF8_LEN_ARR  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}

--- 获取utf8字符串中字符个数
--@param[type=string] input utf8字符串
--@return[type=int] utf8字符个数
function string.utf8len(input)
	local len  = string.len(input)
	local left = len
	local cnt  = 0
	local arr = UTF8_LEN_ARR
	while left ~= 0 do
		local tmp = string.byte(input, -left)
		local i   = #arr
		while arr[i] do
			if tmp >= arr[i] then
				left = left - i
				break
			end
			i = i - 1
		end
		cnt = cnt + 1
	end
	return cnt
end

--- 获取utf8字符串中字符构成的列表
--@param[type=string] input utf8字符串
--@return[type=table] utf8字符构成的列表
function string.utf8chars(input)
	local len  = string.len(input)
	local left = len
	local chars  = {}
	local arr  = UTF8_LEN_ARR
	while left ~= 0 do
		local tmp = string.byte(input, -left)
		local i = #arr
		while arr[i] do
			if tmp >= arr[i] then
				table.insert(chars,string.sub(input,-left,-(left-i+1)))
				left = left - i
				break
			end
			i = i - 1
		end
	end
	return chars
end

--- 将字符串格式时间转成时间戳
--@param[type=string] str 字符串,要求时间格式为:"YYYY-mm-dd HH:MM:SS"
--@return[type=int] 时间戳
function string.totime(str)
	local year,mon,day,hour,min,sec = string.match(str,"^(%d+)[/-](%d+)[/-](%d+)%s+(%d+):(%d+):(%d+)$")

	return os.time({
		year = tonumber(year),
		month = tonumber(mon),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec),
	})
end

function string.basename(path)
	local file = string.gsub(path,"^.*[/\\](.+)$","%1")
	local basename = string.gsub(file,"^(.+)%..+$","%1")
	return basename
end

function string.dirname(path)
	local dirname = string.gsub(path,"^(.*)[/\\].*$","%1")
	if dirname == path then
		return "."
	else
		return string.rtrim(dirname,"/\\")
	end
end

function string.extname(path)
	return path:match(".+%.(%w+)$")
end

-- a-zA-Z0-9
local CHAR_MAP = {}
local CHAR_LEN = 62
for i=0,CHAR_LEN-1 do
	local char
	if 10 <= i and i < 36 then
		char = string.char(97+i-10)
	elseif 36 <= i and i < 62 then
		char = string.char(65+i-36)
	else
		char = tostring(i)
	end
	CHAR_MAP[i] = char
	CHAR_MAP[char] = i
end

function string.randomkey(len)
	len = len or 32
	local ret = {}
	local maxlen = CHAR_LEN
	for i=1,len do
		table.insert(ret,CHAR_MAP[math.random(0,maxlen-1)])
	end
	return table.concat(ret,"")
end
