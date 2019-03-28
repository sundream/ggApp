---protobuf模块
--@script gg.codec.protobuf
--@author sundream
--@release 2018/12/25 10:30:00
--@usage
--一个完整的protobuf包格式如下
-- -----------------
-- |len|header|body|
-- -----------------
-- len为2字节大端,表示header的长度
-- header是消息头,是一个protobuf消息,一般包含消息ID,会话ID等数据
-- body是消息体,是一个protobuf消息(消息ID在header中指定)

local pb = require "pb"

protobuf = protobuf or setmetatable({},{__index=pb})
protobuf.__index = protobuf

function protobuf.new(conf)
	local pbfile = assert(conf.pbfile)
	local idfile = assert(conf.idfile)
	local self = {
		pbfile = pbfile,
		idfile = idfile,
		message_define = {}
	}
	self.MessageHeader = conf.MessageHeader or "MessageHeader"
	setmetatable(self,protobuf)
	self:reload()
	return self
end

function protobuf:reload()
	protobuf.clear()
	protobuf.loadfile(self.pbfile)
	self.message_define = {}
	local fd = io.open(self.idfile,"rb")
	for line in fd:lines() do
		local message_id,message_name = string.match(line,'%[(%d+)%]%s+=%s+"([%w_.]+)"')
		if message_id and message_name then
			message_id = assert(tonumber(message_id))
			assert(self.message_define[message_name] == nil)
			assert(self.message_define[message_id] == nil)
			self.message_define[message_name] = message_id
			self.message_define[message_id] = message_name
		end
	end
	fd:close()
end

local header_tmp = {}

function protobuf:unpack_message(msg)
	local MessageHeader = self.MessageHeader
	local header_bin,size = string.unpack(">s2",msg)
	local header,err = protobuf.decode(MessageHeader,header_bin)
	assert(err == nil,err)
	local message_id = header.type
	local message_name = assert(self.message_define[message_id],"unknow message_id:" .. message_id)
	local content
	if #msg >= size then
		local content_bin = string.sub(msg,size,#msg)
		content,err = protobuf.decode(message_name,content_bin)
		assert(err == nil,err)
	end
	if header.request then
		-- request
		return {
			type = "REQUEST",
			proto = message_name,
			--tag = message_id,
			session = header.session,
			ud = header.ud,
			request = content,
		}
	else
		-- response
		assert(header.session,"session not found")
		return {
			type = "RESPONSE",
			proto = message_name,
			--tag = message_id,
			session = header.session,
			ud = header.ud,
			response = content,
		}
	end
end

function protobuf:pack_message(message)
	local is_request = message.type == "REQUEST"
	local message_name = message.proto
	local session = message.session
	local ud = message.ud
	if is_request then
		return self:pack_request(message_name,message.request,session,ud)
	else
		return self:pack_response(message_name,message.response,session,ud)
	end
end

function protobuf:pack_request(message_name,request,session,ud)
	if session == 0 then
		session = nil
	end
	local message_id = assert(self.message_define[message_name],"unknow message_name: " .. message_name)
	header_tmp.type = message_id
	header_tmp.session = session
	header_tmp.ud = ud
	header_tmp.request = true
	local MessageHeader = self.MessageHeader
	local header = protobuf.encode(MessageHeader,header_tmp)
	if request then
		local body = protobuf.encode(message_name,request)
		return string.pack(">s2",header) .. body
	else
		return string.pack(">s2",header)
	end
end

function protobuf:pack_response(message_name,response,session,ud)
	local message_id = assert(self.message_define[message_name],"unknow message_name: " .. message_name)
	header_tmp.type = message_id
	header_tmp.session = session
	header_tmp.ud = ud
	header_tmp.request = false
	local MessageHeader = self.MessageHeader
	local header = protobuf.encode(MessageHeader,header_tmp)
	if response then
		local body = protobuf.encode(message_name,response)
		return string.pack(">s2",header) .. body
	else
		return string.pack(">s2",header)
	end
end

return protobuf
