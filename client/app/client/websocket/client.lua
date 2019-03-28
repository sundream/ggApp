-- Copyright (C) Yichun Zhang (agentzh)


-- FIXME: this library is very rough and is currently just for testing
--        the websocket server.


local wbproto = require "app.client.websocket.protocol"
local socket = require "socket"
local crypt = require "crypt"


local _recv_frame = wbproto.recv_frame
local _send_frame = wbproto.send_frame
local new_tab = wbproto.new_tab
local tcp = socket.tcp
local encode_base64 = crypt.base64encode
local concat = table.concat
local char = string.char
local str_find = string.find
local rand = math.random
local setmetatable = setmetatable
local type = type
local ssl_support = false

local _M = new_tab(0, 13)
_M._VERSION = '0.07'

local function rshift(number,bits)
    return number >> bits
end

local function band(num1,num2)
    return num1 & num2
end

local function socket_connect(sock,host,port)
    return sock:connect(host,port)
end

local function socket_close(sock)
    return sock:close()
end

local function socket_write(sock,data)
    return sock:send(data)
end

local function socket_read(sock,opts)
    return sock:receive(opts)
end


local mt = { __index = _M }


function _M.new(self, opts)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end

    local max_payload_len, send_masked, timeout,force_masking
    if opts then
        max_payload_len = opts.max_payload_len
        send_masked = opts.send_masked
        timeout = opts.timeout
        force_masking = opts.force_masking

        if timeout then
            sock:settimeout(timeout)
        end
    end

    return setmetatable({
        sock = sock,
        max_payload_len = max_payload_len or 65535,
        send_masked = send_masked,
        force_masking = force_masking,
    }, mt)
end


function _M.connect(self, uri, opts)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local scheme,host,path = string.match(uri,[[^(wss?)://([^/]+)(.*)]])
    if not (scheme and host and path) then
        return nil, "bad websocket uri"
    end
    local port = 80

    local has_port = string.find(host,":")
    if has_port then
        host,port = string.match(host,"^(.+):(%d+)")
        port = tonumber(port)
        if not (host and port) then
            return nil, "bad websocket uri"
        end
    end

    if path == "" then
        path = "/"
    end

    local ssl_verify, proto_header, origin_header = false

    if opts then
        local protos = opts.protocols
        if protos then
            if type(protos) == "table" then
                proto_header = "\r\nSec-WebSocket-Protocol: "
                               .. concat(protos, ",")

            else
                proto_header = "\r\nSec-WebSocket-Protocol: " .. protos
            end
        end

        local origin = opts.origin
        if origin then
            origin_header = "\r\nOrigin: " .. origin
        end

        if opts.ssl_verify then
            if not ssl_support then
                return nil,"not support ssl"
            end
            ssl_verify = true
        end
    end

    local ok, err = socket_connect(sock,host, port)
    if not ok then
        return nil, "failed to connect: " .. err
    end

    if scheme == "wss" then
        if not ssl_support then
            return nil,"not support ssl"
        end
    end

    -- do the websocket handshake:

    local bytes = char(rand(256) - 1, rand(256) - 1, rand(256) - 1,
                       rand(256) - 1, rand(256) - 1, rand(256) - 1,
                       rand(256) - 1, rand(256) - 1, rand(256) - 1,
                       rand(256) - 1, rand(256) - 1, rand(256) - 1,
                       rand(256) - 1, rand(256) - 1, rand(256) - 1,
                       rand(256) - 1)

    local key = encode_base64(bytes)
    local req = "GET " .. path .. " HTTP/1.1\r\nUpgrade: websocket\r\nHost: "
                .. host .. ":" .. port
                .. "\r\nSec-WebSocket-Key: " .. key
                .. (proto_header or "")
                .. "\r\nSec-WebSocket-Version: 13"
                .. (origin_header or "")
                .. "\r\nConnection: Upgrade\r\n\r\n"

    local bytes, err = socket_write(sock,req)
    if not bytes then
        return nil, "failed to send the handshake request: " .. err
    end

    -- read until CR/LF
    local lines = {}
    while true do
        local line,err = socket_read(sock,"*l")
        assert(line,err)
        if line == "" then
            break
        end
        table.insert(lines,line)
    end
    local header = table.concat(lines,"\r\n") .. "\r\n\r\n"
    if not header then
        return nil, "failed to receive response header: " .. err
    end

    -- FIXME: verify the response headers
    local m = string.match(header, [[^%s*HTTP/1%.1%s+]])
    if not m then
        return nil, "bad HTTP response status line: " .. header
    end

    return 1
end


function _M.set_timeout(self, time)
    local sock = self.sock
    if not sock then
        return nil, nil, "not initialized yet"
    end

    return sock:settimeout(time)
end


function _M.recv_frame(self)
    if self.fatal then
        return nil, nil, "fatal error already happened"
    end

    local sock = self.sock
    if not sock then
        return nil, nil, "not initialized yet"
    end

    local data, typ, err =  _recv_frame(sock, self.max_payload_len, self.force_masking)
    if not data and not str_find(err, ": timeout", 1, true) then
        self.fatal = true
    end
    return data, typ, err
end


local function send_frame(self, fin, opcode, payload)
    if self.fatal then
        return nil, "fatal error already happened"
    end

    if self.closed then
        return nil, "already closed"
    end

    local sock = self.sock
    if not sock then
        return nil, "not initialized yet"
    end

    local bytes, err = _send_frame(sock, fin, opcode, payload,
                                   self.max_payload_len,self.send_masked)
    if not bytes then
        self.fatal = true
    end
    return bytes, err
end
_M.send_frame = send_frame


function _M.send_text(self, data)
    return send_frame(self, true, 0x1, data)
end


function _M.send_binary(self, data)
    return send_frame(self, true, 0x2, data)
end


local function send_close(self, code, msg)
    local payload
    if code then
        if type(code) ~= "number" or code > 0x7fff then
            return nil, "bad status code"
        end
        payload = char(band(rshift(code, 8), 0xff), band(code, 0xff))
                        .. (msg or "")
    end

    local bytes, err = send_frame(self, true, 0x8, payload)

    if not bytes then
        self.fatal = true
    end

    self.closed = true

    return bytes, err
end
_M.send_close = send_close


function _M.send_ping(self, data)
    return send_frame(self, true, 0x9, data)
end


function _M.send_pong(self, data)
    return send_frame(self, true, 0xa, data)
end


function _M.close(self,code,msg)
    if self.fatal then
        return nil, "fatal error already happened"
    end

    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    if not self.closed then
        local bytes, err = send_close(self,code,msg)
        if not bytes then
            return nil, "failed to send close frame: " .. err
        end
    end

    return socket_close(sock)
end

return _M
