---@omw-context global

local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')

local player = nil

local function findPlayer()
    for _, actor in ipairs(world.activeActors) do
        if actor.type == types.Player then
            return actor
        end
    end
    return nil
end

local function onPlayerAdded(p)
    player = p
end

local function onSitTeleport(eventData)
    if not player then
        player = findPlayer()
        if not player then
            print("[sit-global] ERROR: player not found")
            return
        end
    end

    if eventData.furniture and eventData.furniturePos then
        local furn   = eventData.furniture
        local newPos = eventData.furniturePos
        local delta  = newPos - furn.position
        if math.sqrt(delta.x^2 + delta.y^2) > 0.5 then
            furn:teleport(furn.cell, newPos, { rotation = furn.rotation })
        end
    end

    local pos = eventData.position
    local yaw = eventData.yaw
    player:teleport(player.cell, pos,
        { rotation = util.transform.rotateZ(yaw + math.pi) })

    player:sendEvent('SitAnimStart', {})
end

local function onSitRestoreChair(eventData)
    local furniture = eventData.furniture
    local pos       = eventData.position
    local rot       = eventData.rotation

    if not (furniture and furniture:isValid()) then
        print("[sit-global] SitRestoreChair: furniture ref is invalid")
        return
    end

    furniture:teleport(furniture.cell, pos, { rotation = rot })
end

return {
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
    },
    eventHandlers = {
        SitTeleport     = onSitTeleport,
        SitRestoreChair = onSitRestoreChair,
    }
}
