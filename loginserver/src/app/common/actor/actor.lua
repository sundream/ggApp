local cactor = class("cactor")

function cactor:init()
    self.client = gg.class.cclient.new()
    self.cluster = gg.class.ccluster.new()
    self.internal = gg.class.cinternal.new()
    self.gm = gg.class.cgm.new()

    self.onerror = nil
    self.__tostring = nil
end

function cactor:start(callback)
    callback = callback or {}
    self.onerror = callback.onerror or gg.onerror
    self.__tostring = callback.__tostring
    skynet.dispatch("lua",function (...)
        self:dispatch(...)
    end)
    self:traceback()
end

function cactor:dispatch(session,source,typ,...)
    local ok,err
    local cmd = self:extract_cmd(typ,...)
    if cmd then
        local profile = gg.profile
        profile.cost[typ] = profile.cost[typ] or {__tostring=tostring,}
        ok,err = profile:stat(profile.cost[typ],cmd,self.onerror,self._dispatch,self,session,source,typ,...)
    else
        ok,err = xpcall(self._dispatch,self.onerror,self,session,source,typ,...)
    end
    -- 将错误传给引擎,这样被对方skynet.call报错后也会回复对方一个错误包
    assert(ok,err)
end

function cactor:_dispatch(session,source,typ,...)
    --skynet.trace()
    if typ == "client" then
        -- 客户端消息
        self.client:dispatch(session,source,...)
    elseif typ == "cluster" then
        -- 集群(服务器间）消息
        self.cluster:dispatch(session,source,...)
    elseif typ == "internal" then
        -- 同节点actor间通信
        self.internal:dispatch(session,source,...)
    elseif typ == "gm" then
        -- debug_console发过来的gm消息
        self.gm:dispatch(session,source,...)
    end
end

function cactor:extract_cmd(typ,...)
    if typ == "client" then
        local cmd = ...
        if cmd == "onmessage" then
            local message = select(3,...)
            return message.cmd
        elseif cmd == "http_onmessage" then
            local uri = select(3,...)
            return uri
        else
            return cmd
        end
        -- 客户端消息
    elseif typ == "cluster" then
        -- 集群(服务器间）消息
        local protoname,cmd,cmd2 = select(3,...)
        if protoname == "playerexec" then
            cmd = cmd2
        end
        if not self._cache then
            self._cache = {}
        end
        if not self._cache[protoname] then
            self._cache[protoname] = {}
        end
        if not self._cache[protoname][cmd] then
            self._cache[protoname][cmd] = protoname .. "." .. cmd
        end
        return self._cache[protoname][cmd]
    elseif typ == "internal" then
        -- 同节点其他服务与主服务通信消息
        local cmd = ...
        return cmd
    elseif typ == "gm" then
        -- debug_console发过来的gm消息
        local cmdline = ...
        -- pid cmd arg1 arg2 ...
        local cmds = string.split(cmdline,"%s")
        return cmds[2]
    end
end

-- 收集字段
cactor.collect_attrs  = skynet.getenv("collect_attrs") or
    {"linkid","linktype","fd","pid","id","name","sid","warid",
    "pos","flag","state","uid","account","proto","cmd","addr"}

function cactor.__tostring(obj)
    local list = {}
    for i,attr in ipairs(cactor.collect_attrs) do
        if obj[attr] then
            table.insert(list,string.format("%s=%s",attr,obj[attr]))
        end
    end
    return tostring(obj) .. "@{" .. table.concat(list,",") .. "}"
end

function cactor:traceback()
    -- 配置traceback收集规则
    for name,class_type in pairs(gg.class) do
        if type(name) == "string" then
            class_type.__tostring = self.__tostring
        end
    end
end

return cactor