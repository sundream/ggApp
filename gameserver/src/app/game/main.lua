require "app.game.game"

skynet.init(function ()
    local ok,err = pcall(game.init)
    if not ok then
        local msg = string.format("game.init,err=%s",err)
        print(msg)
        skynet.error(msg)
        os.exit()
    end
end)

skynet.start(function ()
    local ok,err = pcall(game.start)
    if not ok then
        local msg = string.format("game.start,err=%s",err)
        print(msg)
        skynet.error(msg)
        os.exit()
    end
end)

skynet.info_func(function ()
    return table.dump(gg.profile.cost)
end)