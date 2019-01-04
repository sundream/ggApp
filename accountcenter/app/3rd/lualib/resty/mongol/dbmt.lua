local mod_name = (...):match ( "^(.*)%..-$" )

local misc = require ( mod_name .. ".misc" )
local attachpairs_start = misc.attachpairs_start

local setmetatable = setmetatable
local pcall = pcall

local colmt = require ( mod_name .. ".colmt" )
local gridfs = require ( mod_name .. ".gridfs" )

local dbmethods = { }
local dbmt = { __index = dbmethods }

function dbmethods:cmd(q)
    local collection = "$cmd"
    local col = self:get_col(collection)
    
    local c_id , r , t = col:query(q)

    if t.QueryFailure then
        return nil, "Query Failure"
    elseif not r[1] then
        return nil, "No results returned"
    elseif r[1].ok == 0 then -- Failure
        return nil , r[1].errmsg , r[1] , t
    else
        return r[1]
    end
end

function dbmethods:listcollections ( )
    local col = self:get_col("system.namespaces")
    return col:find( { } )
end

function dbmethods:dropDatabase ( )
    local r, err = self:cmd({ dropDatabase = true })
    if not r then
        return nil, err
    end
    return 1
end

local function pass_digest ( username , password )
    return ngx.md5(username .. ":mongo:" .. password)
end

function dbmethods:add_user ( username , password )
    local digest = pass_digest ( username , password )
    return self:update ( "system.users" , { user = username } , { ["$set"] = { pwd = password } } , true )
end

function dbmethods:auth(username, password)
    local r, err = self:cmd({ getnonce = true })
    if not r then
        return nil, err
    end
 
    local digest = ngx.md5( r.nonce .. username .. pass_digest ( username , password ) )

    r, err = self:cmd(attachpairs_start({
            authenticate = true ;
            user = username ;
            nonce = r.nonce ;
            key = digest ;
         } , "authenticate" ) )
    if not r then
        return nil, err
    end
    return 1
end

function dbmethods:get_col(collection)
    if not collection then
        return nil, "collection needed"
    end

    return setmetatable ( {
            conn = self.conn;
            db_obj = self;
            db = self.db ;
            col = collection;
        } , colmt )
end

function dbmethods:get_gridfs(fs)
    if not fs then
        return nil, "fs name needed"
    end

    return setmetatable({
            conn = self.conn;
            db_obj = self;
            db = self.db;
            file_col = self:get_col(fs..".files");
            chunk_col = self:get_col(fs..".chunks");
        } , gridfs)
end

return dbmt
