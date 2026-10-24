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

    -- Two kinds of yaw arrive here.
    --
    -- The raycast fallback sends the FURNITURE's yaw, and a chair model's
    -- forward points at its own backrest, so it needs the half turn.
    --
    -- The authored solver path sends the world facing it already solved. Its
    -- contract says in terms not to negate it or add 180 again, so adding the
    -- flip there would seat the player backwards on every covered seat.
    local rotation = eventData.yawAbsolute and yaw or (yaw + math.pi)
    player:teleport(player.cell, pos,
        { rotation = util.transform.rotateZ(rotation) })

    player:sendEvent('SitAnimStart', {})
end

---Put the player down after the stand-up clip.
---
---Position only: the facing is left alone on purpose. Snapping the camera
---round at the end of a stand-up is disorienting, and the facing is not a
---safety matter -- the position is.
local function onSitStandTeleport(eventData)
    if not player then
        player = findPlayer()
        if not player then
            print("[sit-global] ERROR: player not found")
            return
        end
    end
    if not eventData.position then return end
    player:teleport(player.cell, eventData.position)
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
        SitTeleport       = onSitTeleport,
        SitStandTeleport  = onSitStandTeleport,
        SitRestoreChair   = onSitRestoreChair,
    }
}
