---@omw-context global

local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')

local player = nil

local move = nil

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
    move = nil
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

    local rotation = eventData.yawAbsolute and yaw or (yaw + math.pi)
    player:teleport(player.cell, pos,
        { rotation = util.transform.rotateZ(rotation) })

    player:sendEvent('SitAnimStart', {})
end

local function onSitPlacePlayer(eventData)
    if not player then
        player = findPlayer()
        if not player then
            print("[sit-global] ERROR: player not found")
            return
        end
    end
    local to = eventData.position
    if not to then return end

    if not (eventData.from and eventData.duration and eventData.duration > 0) then
        move = nil
        player:teleport(player.cell, to)
        return
    end
    move = { from = eventData.from, to = to, elapsed = 0,
             duration = eventData.duration }
end

local function onUpdate(dt)
    if not move then return end
    move.elapsed = move.elapsed + dt
    local t = move.elapsed / move.duration
    if t >= 1 then
        local to = move.to
        move = nil
        player:teleport(player.cell, to)
        return
    end
    local eased = 1 - (1 - t) * (1 - t)
    player:teleport(player.cell, move.from + (move.to - move.from) * eased)
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
        onUpdate      = onUpdate,
    },
    eventHandlers = {
        SitTeleport       = onSitTeleport,
        SitPlacePlayer    = onSitPlacePlayer,
        SitRestoreChair   = onSitRestoreChair,
    }
}
