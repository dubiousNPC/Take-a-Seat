---@omw-context global

local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')

local player = nil

-- The stand-up move, while one is running; nil the rest of the time, which is
-- what keeps onUpdate below free. Declared up here because onSitTeleport
-- clears it -- below its first use it would be an assignment to an undeclared
-- global, which OpenMW's script sandbox rejects outright.
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
    -- A new sit cancels any stand-up move still in flight; otherwise the tween
    -- would keep teleporting the player back out of the seat they just took.
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

---Put the player down on a point the player script has already validated.
---
---With `from` and `duration` this glides; without them it is one teleport. The
---stand-up clip carries no root motion, so the glide is the only thing that
---takes the player out of the chair, and it is short on purpose.
---
---Position only, either way: the facing is left alone. Snapping the camera
---round at the end of a stand-up is disorienting, and the facing is not a
---safety matter -- the position is.
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

---Advance the stand-up move.
---
---The only per-frame code in this mod, and it is one nil check wide unless a
---move is actually running -- a tween is the one thing a timer cannot do
---smoothly. It eases out, so a short move reads as a step away from the chair
---rather than a slide.
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
