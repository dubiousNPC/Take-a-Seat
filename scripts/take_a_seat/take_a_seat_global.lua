---@omw-context global

local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')
local I     = require('openmw.interfaces')
local seats = require('scripts.take_a_seat.sitAnim_shared')

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
    local from = eventData.glideFrom
    if from and eventData.glideTime and eventData.glideTime > 0 then
        -- Turned to the lying facing where the player stands, then carried to
        -- the slot over the transition clip (beds).
        player:teleport(player.cell, from,
            { rotation = util.transform.rotateZ(rotation) })
        move = { from = from, to = pos, elapsed = 0,
                 duration = eventData.glideTime, ease = 'inout' }
    else
        player:teleport(player.cell, pos,
            { rotation = util.transform.rotateZ(rotation) })
    end

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
             duration = eventData.duration, ease = eventData.ease }
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
    -- 'inout' (beds, 1 s): smoothstep, no jolt at either end of a long move;
    -- default: ease-out, quick to leave a seat and settling at the point.
    local eased = move.ease == 'inout' and t * t * (3 - 2 * t) or 1 - (1 - t) * (1 - t)
    player:teleport(player.cell, move.from + (move.to - move.from) * eased)
end

-- The bed's own activation (vanilla Bed_Standard opens the Rest menu) is held
-- back for the press that lies down, so the two do not open together
-- (docs/tickets/0006). The player script reports which press that is: plain
-- Activate by default, Sneak + Activate with the setting off. Until the first
-- report arrives (the first frame after a load) plain Activate lies down.
local bedPressLies = true

local function onBedActivateMode(data)
    if data and data.lie ~= nil then bedPressLies = data.lie and true or false end
end

local function modelOf(obj)
    local rec = types.Activator.record(obj)
    return rec and rec.model or nil
end

if I.Activation and I.Activation.addHandlerForType then
    I.Activation.addHandlerForType(types.Activator, function(obj, actor)
        if not bedPressLies then return end
        if not (actor and actor.type == types.Player) then return end
        local ok, bed = pcall(seats.isBed, obj.recordId, modelOf(obj))
        if ok and bed then return false end
    end)
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
        TakeASeat_BedActivateMode = onBedActivateMode,
    }
}
