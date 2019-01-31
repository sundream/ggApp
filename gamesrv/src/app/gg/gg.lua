gg = gg or {}

function gg.init()
	httpc.webclient_address = skynet.newservice("webclient")
	skynet.name(".webclient",httpc.webclient_address)
	gg.server = cserver.new()
end

return gg
