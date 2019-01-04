require "app.game"

skynet.init(game.init)

skynet.start(game.start)

skynet.info_func(function ()
	return table.dump(profile.cost)
end)
