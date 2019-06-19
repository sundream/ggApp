local sproto = require "gg.codec.sproto"

local sprotox = {}

function sprotox.new(conf)
    local c2s = assert(conf.c2s)
    local s2c = assert(conf.s2c)
    local binary = conf.binary and true or false
    local self = {
        c2s = c2s,
        s2c = s2c,
        binary = binary,
        c2s_sproto = sproto.create(c2s,binary),
        s2c_sproto = sproto.create(s2c,binary),
    }
    return setmetatable(self,{__index=sprotox})
end

function sprotox:reload()
    self.c2s_sproto = sproto.create(self.c2s,self.binary)
    self.s2c_sproto = sproto.create(self.s2c,self.binary)
end

function sprotox:pack_message(message)
    return self.s2c_sproto:pack_message(message)
end

function sprotox:unpack_message(msg)
    return self.c2s_sproto:unpack_message(msg)
end

return sprotox
