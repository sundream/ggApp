--- 协议编解码
--@script app.codec.codec
--@author sundream
--@release 2018/12/25 10:30:00

local sproto = require "app.codec.sprotox"
local protobuf = require "app.codec.protobuf"
local json = require "app.codec.jsonx"

local codec = {}

--- 新建codec实例
--@param[type=table] conf 配置
--@usage
--  -- sproto
--  local codecobj = codec.new({
--      type = "sproto",
--      c2s = "src/proto/sproto/all.spb",
--      s2c = "src/proto/sproto/all.spb",
--      binary = true,
--  })
--  -- protobuf
--  local codecobj = codec.new({
--      type = "protobuf",
--      pbfile = "src/proto/protobuf/all.pb",
--      idfile = "src/proto/protobuf/message_define.lua",
--  })
--
--  -- json
--  local codecobj = codec.new({
--      type = "json",
--  })
function codec.new(conf)
    local self = {}
    if conf.type == "protobuf" then
        self.proto = protobuf.new(conf)
    elseif conf.type == "sproto" then
        self.proto = sproto.new(conf)
    else
        assert(conf.type == "json")
        self.proto = json.new(conf)
    end
    return setmetatable(self,{__index=codec})
end

--- 重新更新协议
function codec:reload()
    self.proto:reload()
end

--- 打包一个消息
--@param[type=table] message 消息
--@return[type=string] 打包后的字符串
--@usage
--  -- 打包一个请求包
--  local bin = codecobj:pack_message({
--      type = 1,           -- 请求包
--      session = session,  -- 会话ID
--      ud = ud,            -- 自定义数据
--      cmd = cmd,          -- 协议名
--      args = args,        -- 协议参数(请求参数)
--  })
--
--  -- 打包一个回复包
--  local bin = codecobj:pack_message({
--      type = 2,           -- 回复包
--      session = session,  -- 会话ID
--      ud = ud,            -- 自定义数据
--      cmd = cmd,          -- 协议名
--      args = args,        -- 协议参数(回复参数)
--  })
function codec:pack_message(message)
    return self.proto:pack_message(message)
end

--- 解包消息
--@param[type=string] msg 消息二进制数据
--@return[type=table] 解出的消息,格式见pack_message#usage
function codec:unpack_message(msg)
    return self.proto:unpack_message(msg)
end

return codec
