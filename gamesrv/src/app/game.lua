require "app.init"
local traceback = require "gg.base.traceback"

local function _print(...)
	print(...)
	skynet.error(...)
end

game = game or {}

function game.init()
	cjson.encode_sparse_array(true)
	game.init_traceback()
	logger.init()
	local db_type = skynet.getenv("db_type") or "redis"
	dbmgr.init(db_type)
end

function game.start()
	logger.logf("info","game","op=start")
	local debug_port = skynet.getenv("debug_port")
	if debug_port then
		-- record address + port for shell/gm.sh
		local file = io.open("./debug_console.txt","wb")
		file:write(string.format("address=%s\nport=%s",skynet.self(),debug_port))
		file:close()
		local address = skynet.newservice("debug_console",debug_port)
	end
	if not skynet.getenv "daemon" then
		local file = io.open("./skynet.pid","wb")
		file:write(game.getpid())
		file:close()
		console.init()
	end
	local address = skynet.self()
	skynet.name(".main",address)
	timectrl.init()
	_print("timectrl.init")
	rpc.init()
	_print("rpc.init")
	playermgr.init()
	_print("playermgr.init")
	gg.init()
	_print("gg.init")
	skynet.dispatch("lua",game.dispatch)
	-- 多久不活跃会主动关闭套接字(1/100秒为单位)
	local timeout = 18000
	local msg_max_len = 65535
	local maxclient = playermgr.onlinelimit or 10240
	local proto
	local proto_type = skynet.getenv("proto_type")
	-- nil/false--不握手,"nil"--握手告知客户端不加密,其他--握手时和客户端协商密钥
	local encrypt_key = skynet.getenv("encrypt_key")
	if proto_type == "sproto" then
		proto = {
			type = "sproto",
			c2s = "../src/proto/sproto/all.spb",
			s2c = "../src/proto/sproto/all.spb",
			binary = true,
		}
	elseif proto_type == "protobuf" then
		proto = {
			type = "protobuf",
			pbfile = "../src/proto/protobuf/all.pb",
			idfile = "../src/proto/protobuf/message_define.lua",
		}
	else
		assert(proto_type == "json")
		proto = {
			type = "json"
		}
	end
	local gate_conf = {
		watchdog = address,
		proto = proto,
		encrypt_key = encrypt_key,
		timeout = timeout,
		msg_max_len = msg_max_len,
		maxclient = maxclient,
	}
	local tcp_gate
	local kcp_gate
	local websocket_gate
	local tcp_port = skynet.getenv("tcp_port")
	if tcp_port then
		gate_conf.port = tcp_port
		tcp_gate = skynet.uniqueservice("gg/service/gate/tcp")
		skynet.call(tcp_gate,"lua","open",gate_conf)
	end
	local kcp_port = skynet.getenv("kcp_port")
	if kcp_port then
		gate_conf.port = kcp_port
		kcp_gate = skynet.uniqueservice("gg/service/gate/kcp")
		skynet.call(kcp_gate,"lua","open",gate_conf)
	end
	local websocket_port = skynet.getenv("websocket_port")
	if websocket_port then
		gate_conf.port = websocket_port
		websocket_gate = skynet.uniqueservice("gg/service/gate/websocket")
		skynet.call(websocket_gate,"lua","open",gate_conf)
	end
	local http_port = skynet.getenv("http_port")
	if http_port then
		gate_conf.port = http_port
		httpd.start(gate_conf)
	end

	net.init()
	_print("net.init")
	client.init({
		tcp_gate = tcp_gate,
		kcp_gate = kcp_gate,
		websocket_gate = websocket_gate,
	})
	_print("client.init")
	_print("start")
end

function game.stop(reason)
	logger.logf("info","game","op=stoping")
	playermgr.kickall()
	game.saveall()
	skynet.timeout(300,function ()
		logger.logf("info","game","op=stoped")
		_print("stoped")
		dbmgr.disconnect()
		logger.shutdown()
		os.execute("rm ../skynet/skynet.pid")
		os.exit()
	end)
end

function game.saveall()
	logger.logf("info","game","op=saveall")
	savemgr.saveall()
end

function game._dispatch(session,source,typ,...)
	--skynet.trace()
	if typ == "client" then
		-- 客户端消息
		client.dispatch(session,source,...)
	elseif typ == "cluster" then
		-- 集群(服务器间）消息
		rpc.dispatch(session,source,...)
	elseif typ == "service" then
		-- 同节点其他服务与主服务通信消息
		game.service_dispatch(session,source,...)
	elseif typ == "gm" then
		-- debug_console发过来的gm消息
		-- 客户端自己执行的gm可以通过特定协议(如频道消息）+ gm权限控制执行
		game.dogm(session,source,...)
	end
end

function game.dispatch(session,source,typ,...)
	local ok,err
	local cmd = game.extract_cmd(typ,...)
	if cmd then
		profile.cost[typ] = profile.cost[typ] or {__tostring=tostring,}
		ok,err = profile.stat(profile.cost[typ],cmd,onerror,game._dispatch,session,source,typ,...)
	else
		ok,err = xpcall(game._dispatch,onerror,session,source,typ,...)
	end
	-- 将错误传给引擎,这样被对方skynet.call报错后也会回复对方一个错误包
	assert(ok,err)
end

function game.dogm(session,source,...)
	local cmdline = ...
	if session ~= 0 then
		local ok,msg,sz = pcall(skynet.pack,gm.docmd(cmdline))
		if ok then
			skynet.ret(msg,sz)
		else
			local err = msg
			skynet.retpack(err)
		end
	else
		gm.docmd(cmdline)
	end
end

function game.service_dispatch(session,source,cmd,...)
	if cmd == "http" then
		client.http_onmessage(...)
	end
end

function game.getpid()
	if not game.pid then
		local serverid = skynet.getenv("id")
		local cmd = string.format("ps -ef | grep skynet | grep %s | grep -v grep",serverid)
		local file = io.popen(cmd,"r")
		local line = file:read("*a")
		file:close()
		local list = string.split(line)
		game.pid = assert(tonumber(list[2]))
	end
	return game.pid
end

function game.extract_cmd(typ,...)
	if typ == "client" then
		local cmd = ...
		if cmd == "onmessage" then
			local message = select(3,...)
			return message.proto
		else
			return cmd
		end
		-- 客户端消息
	elseif typ == "cluster" then
		-- 集群(服务器间）消息
		local protoname,cmd,cmd2 = select(2,...)
		if protoname == "playerexec" then
			cmd = cmd2
		end
		if not game._cache then
			game._cache = {}
		end
		if not game._cache[protoname] then
			game._cache[protoname] = {}
		end
		if not game._cache[protoname][cmd] then
			game._cache[protoname][cmd] = protoname .. "." .. cmd
		end
		return game._cache[protoname][cmd]
	elseif typ == "service" then
		-- 同节点其他服务与主服务通信消息
		return nil
	elseif typ == "gm" then
		-- debug_console发过来的gm消息
		local cmdline = ...
		-- pid cmd arg1 arg2 ...
		local cmds = string.split(cmdline,"%s")
		return cmds[2]
	end
end

function game.init_traceback()
	-- 配置traceback收集规则,对于特定类型只收集指定字段
	local collect_attrs  = {"linkid","linktype","fd","pid","id","name","sid","warid",
		"flag","state","uid","account","proto","addr"}
	local tbls = {cplayer,clinkobj,profile,traceback}
	for i,tbl in ipairs(tbls) do
		if not tbl.__tostring then
			tbl.__tostring = function (obj)
				local kvlines = {}
				for k,v in pairs(obj) do
					if table.find(collect_attrs,k) then
						table.insert(kvlines,string.format("%s=%s",k,v))
					end
				end
				return "{" .. table.concat(kvlines,",") .. "}"
			end
		end
	end
end

return game
