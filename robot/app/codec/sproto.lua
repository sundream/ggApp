---扩展sproto模块
--@script gg.codec.sproto
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--一个完整的sproto包格式如下
-- -------------
-- |header|body|
-- -------------
-- header是消息头,是一个sproto消息,一般包含消息ID,会话ID等数据
-- body是消息体,是一个sproto消息(消息ID在header中指定)

local core = require "sproto.core"
local sproto = require "sproto"

local header_tmp = {}

function sproto:queryproto(pname)
	local v = self.__pcache[pname]
	if not v then
		local tag, req, resp = core.protocol(self.__cobj, pname)
		assert(tag, pname .. " not found")
		if tonumber(pname) then
			pname, tag = tag, pname
		end
		v = {
			request = req,
			response = resp,
			name = pname,
			tag = tag,
		}
		self.__pcache[pname] = v
		self.__pcache[tag]  = v
	end
	return v
end

function sproto:unpack_message(msg,sz)
	self:packagename()
	local bin = core.unpack(msg,sz)
	header_tmp.type = nil
	header_tmp.session = nil
	header_tmp.ud = nil
	local header,size = core.decode(self.__package,bin,header_tmp)
	local content = bin:sub(size+1)
	if header.type then
		-- request
		local proto = self:queryproto(header.type)
		local request
		if proto.request then
			request = core.decode(proto.request,content)
		end
		return {
			type = "REQUEST",
			proto = proto.name,
			--tag = header.type,
			session = header.session,
			ud = header.ud,
			request = request,
		}
	else
		-- response
		local session = assert(header.session,"session not found")
		local tag = assert(self.__session[session],"Unknown session")
		self.__session[session] = nil
		local proto = self:queryproto(tag)
		local response
		if proto.response then
			response = core.decode(proto.response,content)
		end
		return {
			type = "RESPONSE",
			proto = proto.name,
			--tag = tag,
			session = header.session,
			ud = header.ud,
			response = response,
		}
	end
end

function sproto:pack_message(message)
	local is_request = message.type == "REQUEST"
	local protoname = message.proto
	local session = message.session
	local ud = message.ud
	if is_request then
		return self:pack_request(protoname,message.request,session,ud)
	else
		return self:pack_response(protoname,message.response,session,ud)
	end
end

function sproto:pack_request(protoname,request,session,ud)
	self:packagename()
	if session == 0 then
		session = nil
	end
	local proto = self:queryproto(protoname)
	if session then
		self.__session[session] = proto.tag
	end
	header_tmp.type = proto.tag
	header_tmp.session = session
	header_tmp.ud = ud
	local header = core.encode(self.__package,header_tmp)
	if proto.request and request then
		local content = core.encode(proto.request,request)
		return core.pack(header .. content)
	else
		return core.pack(header)
	end
end

function sproto:pack_response(protoname,response,session,ud)
	self:packagename()
	local proto = self:queryproto(protoname)
	header_tmp.type = nil
	header_tmp.session = session
	header_tmp.ud = ud
	local header = core.encode(self.__package,header_tmp)
	if proto.response and response then
		local content = core.encode(proto.response,response)
		return core.pack(header .. content)
	else
		return core.pack(header)
	end
end

function sproto.create(filename,binary)
	local fp,err = io.open(filename,"rb")
	assert(fp,err)
	local proto_str = fp:read("*a")
	fp:close()
	if binary then
		return sproto.new(proto_str)
	else
		return sproto.parse(proto_str)
	end
end

function sproto:packagename(packagename)
	if self.__package then
		return
	end
	packagename = packagename or "package"
	self.__package = assert(core.querytype(self.__cobj,packagename),"type package not found")
end

return sproto

