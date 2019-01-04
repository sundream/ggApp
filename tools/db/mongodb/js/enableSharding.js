sh.enableSharding("game")
sh.shardCollection("game.player",{pid:"hashed"})
printjson(sh.status())
