clinkobj = class("clinkobj")

function clinkobj:init(linktype,linkid,addr)
	-- linktype: tcp/websocket/kcp
	self.linktype = assert(linktype)
	self.linkid = assert(linkid)
	self.addr = assert(addr)
	local ip,port
	if linktype == "kcp" then
		ip,port = socket.udp_address(addr)
	else
		ip,port = table.unpack(string.split(addr,":"))
	end
	self.ip = assert(ip)
	self.port = assert(port)
end

function clinkobj:bind(pid)
	self.pid = pid
end

function clinkobj:unbind()
	self.pid = nil
end

return clinkobj
