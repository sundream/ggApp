local mod_name = (...):match ( "^(.*)%..-$" )

local ll = require ( mod_name .. ".ll" )
local num_to_le_uint = ll.num_to_le_uint
local num_to_le_int = ll.num_to_le_int
local le_uint_to_num = ll.le_uint_to_num
local le_bpeek = ll.le_bpeek


local getmetatable , setmetatable = getmetatable , setmetatable
local pairs = pairs
local next = next

do
    -- Test to see if __pairs is natively supported
    local supported = false
    local test = setmetatable ( { } , { __pairs = function ( ) supported = true end } )
    pairs ( test )
    if not supported then
        _G.pairs = function ( t )
            local mt = getmetatable ( t )
            if mt then
                local f = mt.__pairs
                if f then
                    return f ( t )
                end
            end
            return pairs ( t )
        end
        -- Confirm we added it
        _G.pairs ( test )
        assert ( supported )
    end
end


local pairs_start = function ( t , sk )
    local i = 0
    return function ( t , k , v )
        i = i + 1
        local nk, nv
        if i == 1 then
            return sk, t[sk]
        elseif i == 2 then
            nk, nv = next(t)
            -- fixbug: BSON field 'OperationSessionInfo.xxx' is a duplicate field
            if sk == nk then
                nk,nv = next(t,nk)
            end
        else
            nk, nv = next(t, k)
            if sk == nk then
                nk,nv = next(t,nk)
            end
        end
        return nk,nv
    end , t
end

local function attachpairs_start ( o , k )
    local mt = getmetatable ( o )
    if not mt then
        mt = { }
        setmetatable ( o , mt )
    end
    mt.__pairs = function ( t )
        return pairs_start ( t , k )
    end
    return o
end

return {
    pairs_start = pairs_start ;
    attachpairs_start = attachpairs_start ;
}

