local netmap = {
    C2GS = {},
    GS2C = {},
}


local C2GS = netmap.C2GS
local GS2C = netmap.GS2C

local function packScenePlayer(player)
    return {
        pid = player.pid,
        linkid = player.linkid,
        linktype = player.linktype,
        pos = player.pos,
        speed = 1,
        radiusAOI = 3,
        sign = Map.TERRIAN_WATER | Map.TERRIAN_HIGHLOAD | Map.TERRIAN_LOWLOAD,
        gridSign = 0,
        type = 10,
    }
end

function C2GS.Map_EnterScene(player,message)
    local args = message.args
    local sceneId = assert(args.sceneId)
    local pos = assert(args.pos)
    local session = args.session
    local queryMap = args.queryMap
    local scene = gg.sceneMgr:getScene(sceneId)
    if not scene then
        return
    end
    player.pos = pos
    player.sceneId = sceneId
    local scenePlayer = packScenePlayer(player)
    player.id = scene:addPlayer(scenePlayer)
end

function C2GS.Map_LeaveScene(player,message)
    local sceneId = player.sceneId
    local scene = gg.sceneMgr:getScene(sceneId)
    if not scene then
        return
    end
    scene:delPlayer(player.id)
end

function C2GS.Map_SetPath(player,message)
    local args = message.args
    local path = assert(message.path)
    local id = player.id
    local sceneId = player.sceneId
    local scene = gg.sceneMgr:getScene(sceneId)
    if not scene then
        return
    end
    scene:setPath(id,path)
end

function C2GS.Map_SetTargetPos(player,message)
    local args = message.args
    local targetPos = assert(message.pos)
    local id = player.id
    local sceneId = player.sceneId
    local scene = gg.sceneMgr:getScene(sceneId)
    if not scene then
        return
    end
    scene:setTargetPos(id,targetPos)
end

function C2GS.Map_StopMove(player,message)
    local id = player.id
    local sceneId = player.sceneId
    local scene = gg.sceneMgr:getScene(sceneId)
    if not scene then
        return
    end
    scene:stopMove(id)
end

function C2GS.Map_Follow(player,message)
end

function C2GS.Map_StopFollow(player,message)
end

function C2GS.Map_SetTarget(player,message)
end

function C2GS.Map_ResetTarget(player,message)
end

function __hotfix(module)
    gg.hotfix("app.game.client.client")
end

return netmap
