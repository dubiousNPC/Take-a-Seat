---@omw-context player
--[[
    take_a_seat.lua -- event-driven sitting controller

    No onFrame handler. Every code path is entered from a discrete event:

      Activate keypress  -> input.registerTriggerHandler("Activate", ...)
      camera settle      -> async:newUnsavableSimulationTimer
      raycast results    -> nearby.asyncCastRenderingRay callbacks
      animation cancelled-> I.AnimationController.addAnimationEndedHandler
      fatigue regen      -> time.runRepeatedly at 1s
      movement lock      -> types.Player.setControlSwitch (one-shot, not per-frame)

    Consequence worth understanding before tuning: because the trigger handler
    is not one of the three contexts where synchronous nearby.castRenderingRay
    is legal (onFrame, user-input engine handlers, registerActionHandler
    callbacks), EVERY ray in this file is asynchronous. The resolve is
    therefore a callback chain spread over several frames instead of one
    blocking burst. See RESOLVE LATENCY below.
]]

local self   = require('openmw.self')
local anim   = require('openmw.animation')
local nearby = require('openmw.nearby')
local input  = require('openmw.input')
local camera = require('openmw.camera')
local util   = require('openmw.util')
local core   = require('openmw.core')
local types  = require('openmw.types')
local async  = require('openmw.async')
local storage = require('openmw.storage')
local I      = require('openmw.interfaces')
local time   = require('openmw_aux.time')
local seats  = require('scripts.take_a_seat.sitAnim_shared')

-- ---------------------------------------------------------------------------
-- DATA
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- SEAT PROFILES
-- ---------------------------------------------------------------------------
-- Seat classification, animation groups and height calibration all live in
-- scripts/take_a_seat/sitAnim_shared.lua so they can be extended without
-- touching this controller, and so other mods can read the same lists.
-- Local aliases below keep the call sites short.

local SEAT_TYPE = seats.SEAT_TYPE
local getSeatType    = seats.getSeatType
local isSittable     = seats.isSittable
local resolveSitAnim = seats.animForSeat

local DEBUG = false

local SIT_LOOPS    = 999
local SIT_PRIORITY = anim.PRIORITY.Scripted

-- ---------------------------------------------------------------------------
-- RESOLVE LATENCY
-- ---------------------------------------------------------------------------
-- Each async raycast costs at least one callback round-trip. The stages chain,
-- so worst-case latency between keypress and being seated is roughly:
--     CHAIR_PUSH_MAX_ITER + SEAT_MAX_PIERCES + SEAT_MAX_PIERCES + 1
-- round-trips. These caps are set low deliberately. If sitting feels laggy,
-- lower CHAIR_PUSH_MAX_ITER first -- the solver converges in 2-3 iterations in
-- open rooms and only burns the full budget when wedged into a corner. Adding a
-- SIT_PIVOT_OFFSET entry for a chair skips the seat-surface stage entirely,
-- which is the single biggest latency win available per-record.
local RESOLVE_TIMEOUT   = 3.0   -- seconds; abort a chain that never completes

local MAX_PIERCES       = 4
local SEAT_PROBE_START  = 150
local SEAT_PROBE_END    = 10
local SEAT_PROBE_RADIUS = 16
local SEAT_MAX_PIERCES  = 6     -- was 10; each pierce is a round-trip now
local SEAT_CLUSTER_DIST = 6

local FATIGUE_TICK_RATE   = 1     -- throttled to 1/sec
local FATIGUE_TICK_AMOUNT = 20    -- was 10 per 0.5s; same restore rate per second

local FLAT_RAYS    = { { z = 10 }, { z = 30 }, { z = 55 } }
local PITCHED_RAYS = {
    { pitch = math.rad(-10) }, { pitch = math.rad(-20) }, { pitch = math.rad(-30) },
}
local EYE_HEIGHT   = 60
local RAY_DISTANCE = 200

local PUSH_PROBE_COUNT = 12
local PUSH_PROBE_DIST  = 80
local PUSH_STRENGTH    = 15

local CHAIR_PUSH_PROBE_COUNT = 8
local CHAIR_PUSH_PROBE_DIST  = 90
local CHAIR_PUSH_MIN_DIST    = 45
local CHAIR_PUSH_MAX_MOVE    = 22
local CHAIR_PUSH_STEP        = 2
local CHAIR_PUSH_MAX_ITER    = 5     -- lowered again: each iteration is a round-trip
local CHAIR_PUSH_ORIGIN_DIST = 100
local CHAIR_PUSH_PROBE_ZS    = { -10, 35, 80 }

local SIT_ANIM_WINDOW    = 0.05

-- ---------------------------------------------------------------------------
-- CLASSIFICATION (memoized -- recordId is static per record)
-- ---------------------------------------------------------------------------




local function getObjectYaw(obj)
    local forward = obj.rotation:apply(util.vector3(0, 1, 0))
    return math.atan2(forward.x, forward.y)
end

-- ---------------------------------------------------------------------------
-- ASYNC RAY PRIMITIVES
-- ---------------------------------------------------------------------------

-- Fire N independent rays at once; call done(results) when the last returns.
-- Parallel rather than sequential: N rays cost one round-trip, not N.
local function castBatch(rays, done)
    local n = #rays
    if n == 0 then return done({}) end
    local results, remaining = {}, n
    for i = 1, n do
        local from, to = rays[i][1], rays[i][2]
        nearby.asyncCastRenderingRay(async:callback(function(res)
            results[i] = res
            remaining = remaining - 1
            if remaining == 0 then done(results) end
        end), from, to)
    end
end

-- Walk a ray through hits, stepping past each one, up to maxPierces.
-- onHit(res) returns true to stop (res is handed to done), false to continue.
-- done(res or nil). Inherently sequential: costs up to maxPierces round-trips.
local function castPiercing(from, to, maxPierces, onHit, done)
    local current, left = from, maxPierces
    local step
    step = function()
        if left <= 0 then return done(nil) end
        left = left - 1
        nearby.asyncCastRenderingRay(async:callback(function(res)
            if not res or not res.hit then return done(nil) end
            if onHit(res) then return done(res) end
            local dir = to - current
            local len = dir:length()
            if len < 1 then return done(nil) end
            local advance = (res.hitPos - current):length() + 2
            if advance >= len then return done(nil) end
            current = current + (dir / len) * advance
            step()
        end), current, to)
    end
    step()
end

-- Run worker over every item concurrently; call done() once all report back.
local function forEachAsync(items, worker, done)
    local n = #items
    if n == 0 then return done() end
    local remaining = n
    for i = 1, n do
        worker(items[i], i, function()
            remaining = remaining - 1
            if remaining == 0 then done() end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------------

local isSitting        = false
local sitAnimStarted   = false
local currentFurniture = nil
local originalChairPos = nil
local originalChairRot = nil
local currentSitAnim   = nil
local controlsLocked   = false

-- Animation-restart burst guard. Declared here rather than beside the
-- ended-handler because the perspective-change handler also resets it, and
-- that runs earlier in the file.
local replayCount, replayWindowStart = 0, 0

-- Every async callback in a resolve chain carries the token it started with.
-- Bumping the token invalidates all in-flight callbacks at once, which is how
-- an abort (stood up, walked away, pressed again) is expressed without needing
-- to track individual callbacks.
local resolveToken   = 0
local resolveActive  = false

local function abortResolve()
    resolveToken  = resolveToken + 1
    resolveActive = false
end

-- ---------------------------------------------------------------------------
-- TARGETING
-- ---------------------------------------------------------------------------

-- SharedRay is a single camera-forward ray, cast once per frame and shared by
-- every mod that consumes it. Reading it costs nothing -- no cast is issued
-- here. It only covers "looking straight at it", so the fan below remains for
-- chairs that sit below or off the crosshair.
local function tryFurnitureFastPath()
    if not (I.SharedRay and I.SharedRay.get) then return nil end
    local result = I.SharedRay.get()
    if not result or not result.hit then return nil end
    local obj = result.hitObject
    -- SharedRay validated this at delivery, but delivery was last frame and any
    -- access to an invalidated object raises, so re-check before reading fields.
    if not obj or not obj:isValid() then return nil end
    if not isSittable(obj.recordId) then return nil end
    return obj
end

-- The six fan rays are independent, so they run concurrently and the winner is
-- picked afterwards by the original priority order (flat first, then pitched).
-- Sequential would cost 6 * MAX_PIERCES round-trips; this costs MAX_PIERCES.
local function findFurnitureAsync(done)
    local fast = tryFurnitureFastPath()
    if fast then return done(fast) end

    local yaw     = camera.getYaw()
    local camPos  = camera.getPosition()
    local eyePos  = self.position + util.vector3(0, 0, EYE_HEIGHT)
    local camOffset = util.vector3(camPos.x - eyePos.x, camPos.y - eyePos.y, 0)
    local offsetLen = camOffset:length()
    local origin = eyePos
    if offsetLen > 5 then
        origin = eyePos + (camOffset / offsetLen) * math.min(offsetLen, 30)
    end

    local probes = {}
    local flatDir = util.vector3(math.sin(yaw), math.cos(yaw), 0)
    for _, ray in ipairs(FLAT_RAYS) do
        local from = origin + util.vector3(0, 0, ray.z - EYE_HEIGHT)
        probes[#probes + 1] = { from, from + flatDir * RAY_DISTANCE }
    end
    for _, ray in ipairs(PITCHED_RAYS) do
        local cp = math.cos(ray.pitch)
        local dir = util.vector3(math.sin(yaw) * cp, math.cos(yaw) * cp, math.sin(ray.pitch))
        probes[#probes + 1] = { origin, origin + dir * RAY_DISTANCE }
    end

    local found = {}
    forEachAsync(probes, function(probe, index, finished)
        castPiercing(probe[1], probe[2], MAX_PIERCES, function(res)
            return res.hitObject ~= nil and isSittable(res.hitObject.recordId)
        end, function(res)
            if res and res.hitObject then found[index] = res.hitObject end
            finished()
        end)
    end, function()
        for i = 1, #probes do
            if found[i] then return done(found[i]) end
        end
        done(nil)
    end)
end

-- ---------------------------------------------------------------------------
-- RESOLVE STAGE 1 -- push the chair clear of surrounding geometry
-- ---------------------------------------------------------------------------

local function pushIteration(chairPos, furniture, done)
    local rays, meta = {}, {}
    for i = 0, CHAIR_PUSH_PROBE_COUNT - 1 do
        local angle = (i / CHAIR_PUSH_PROBE_COUNT) * (2 * math.pi)
        local dx, dy = math.sin(angle), math.cos(angle)
        for _, dz in ipairs(CHAIR_PUSH_PROBE_ZS) do
            rays[#rays + 1] = {
                util.vector3(chairPos.x, chairPos.y, chairPos.z + dz),
                util.vector3(chairPos.x + dx * CHAIR_PUSH_ORIGIN_DIST,
                             chairPos.y + dy * CHAIR_PUSH_ORIGIN_DIST,
                             chairPos.z + dz),
            }
            meta[#rays] = { angleIndex = i, dx = dx, dy = dy }
        end
    end

    castBatch(rays, function(results)
        local closest, didHit = {}, {}
        for idx, res in pairs(results) do
            local m = meta[idx]
            if res and res.hit and res.hitObject and res.hitObject ~= furniture
               and res.hitObject:isValid()
               and not isSittable(res.hitObject.recordId) then
                local dist = math.max(math.sqrt(
                    (res.hitPos.x - chairPos.x)^2 +
                    (res.hitPos.y - chairPos.y)^2), 2)
                local a = m.angleIndex
                if not closest[a] or dist < closest[a] then
                    closest[a] = dist; didHit[a] = m
                end
            end
        end

        local repX, repY, totalW = 0, 0, 0
        for a, m in pairs(didHit) do
            if closest[a] < CHAIR_PUSH_MIN_DIST then
                local w = 1 - closest[a] / CHAIR_PUSH_MIN_DIST
                repX = repX - m.dx * w; repY = repY - m.dy * w; totalW = totalW + w
            end
        end

        if totalW < 0.001 then return done(util.vector3(0, 0, 0)) end
        local len = math.sqrt(repX^2 + repY^2)
        if len < 0.001 then return done(util.vector3(0, 0, 0)) end
        local scale = CHAIR_PUSH_MAX_MOVE *
                      math.min(1, totalW / (CHAIR_PUSH_PROBE_COUNT * 0.25))
        done(util.vector3(repX / len * scale, repY / len * scale, 0))
    end)
end

local function resolveChairPosition(furniture, token, done)
    local original, pos, iter = furniture.position, furniture.position, 0
    local stepIteration
    stepIteration = function()
        if token ~= resolveToken then return end
        iter = iter + 1
        if iter > CHAIR_PUSH_MAX_ITER then return done(pos) end
        pushIteration(pos, furniture, function(push)
            if token ~= resolveToken then return end
            if push:length() < 0.5 then return done(pos) end
            local stepLen = math.min(push:length(), CHAIR_PUSH_STEP)
            pos = pos + (push / push:length()) * stepLen
            local delta = pos - original
            if math.sqrt(delta.x^2 + delta.y^2) >= CHAIR_PUSH_MAX_MOVE then
                return done(pos)
            end
            stepIteration()
        end)
    end
    stepIteration()
end

-- ---------------------------------------------------------------------------
-- RESOLVE STAGE 2 -- find the seat plane
-- ---------------------------------------------------------------------------

local function findSeatSurface(chairPos, furniture, token, done)
    local r = SEAT_PROBE_RADIUS
    local offsets = {
        util.vector3( 0,  0, 0), util.vector3( r,  0, 0), util.vector3(-r,  0, 0),
        util.vector3( 0,  r, 0), util.vector3( 0, -r, 0), util.vector3( r,  r, 0),
        util.vector3(-r,  r, 0), util.vector3( r, -r, 0), util.vector3(-r, -r, 0),
    }
    local allZHits = {}
    local stopZ = chairPos.z - SEAT_PROBE_END

    -- The nine columns are independent, so they pierce concurrently; only the
    -- pierces *within* one column are sequential.
    forEachAsync(offsets, function(off, _, finished)
        local bx, by = chairPos.x + off.x, chairPos.y + off.y
        local from = util.vector3(bx, by, chairPos.z + SEAT_PROBE_START)
        local to   = util.vector3(bx, by, stopZ)
        castPiercing(from, to, SEAT_MAX_PIERCES, function(res)
            local obj = res.hitObject
            if obj == furniture or
               (obj and obj:isValid() and isSittable(obj.recordId)) then
                allZHits[#allZHits + 1] = res.hitPos.z
            end
            return res.hitPos.z <= stopZ + 2   -- reached the floor, stop this column
        end, function() finished() end)
    end, function()
        if token ~= resolveToken then return end
        if #allZHits == 0 then return done(nil) end
        table.sort(allZHits)

        local clusters = {}
        local cur = { zMin = allZHits[1], zMax = allZHits[1], count = 1 }
        for i = 2, #allZHits do
            if allZHits[i] - cur.zMax <= SEAT_CLUSTER_DIST then
                cur.zMax = allZHits[i]; cur.count = cur.count + 1
            else
                clusters[#clusters + 1] = cur
                cur = { zMin = allZHits[i], zMax = allZHits[i], count = 1 }
            end
        end
        clusters[#clusters + 1] = cur

        local best = clusters[1]
        for i = 2, #clusters do
            local c = clusters[i]
            if c.count > best.count or (c.count == best.count and c.zMax < best.zMax) then
                best = c
            end
        end

        if DEBUG then
            local diff = best.zMax - chairPos.z
            print(string.format("[sit] seat Z=%.1f pivot Z=%.1f diff=%.1f hits=%d clusters=%d",
                best.zMax, chairPos.z, diff, #allZHits, #clusters))
            print(string.format("[sit] TIP: if correct, add SIT_PIVOT_OFFSET["%s"] = %.1f to sitAnim_shared.lua",
                furniture.recordId or "?", diff))
        end

        done(best.zMax)
    end)
end

local function findObstructionAbove(chairPos, furniture, done)
    local from = util.vector3(chairPos.x, chairPos.y, chairPos.z + SEAT_PROBE_START)
    local to   = util.vector3(chairPos.x, chairPos.y, chairPos.z + 5)
    local blockZ, bailed = nil, false
    castPiercing(from, to, SEAT_MAX_PIERCES, function(res)
        local obj = res.hitObject
        local rid = (obj and obj:isValid()) and obj.recordId or nil
        if obj ~= furniture and not isSittable(rid) then
            blockZ = res.hitPos.z
            return true
        end
        if res.hitPos.z <= chairPos.z + 7 then bailed = true; return true end
        return false
    end, function()
        done((not bailed) and blockZ or nil)
    end)
end

local function computeSeatZ(chairPos, furniture, token, done)
    local rid = furniture.recordId
    local calibrated = seats.pivotOffset(rid)
    if calibrated then
        -- Fast path: no rays at all. Worth adding entries for chairs you use often.
        return done(chairPos.z + calibrated)
    end

    findSeatSurface(chairPos, furniture, token, function(seatZ)
        if token ~= resolveToken then return end
        if seatZ then return done(seatZ) end
        local fallbackZ = chairPos.z + seats.fallbackOffset(rid)
        findObstructionAbove(chairPos, furniture, function(blockZ)
            if token ~= resolveToken then return end
            if blockZ and fallbackZ >= blockZ - 2 then fallbackZ = blockZ - 28 end
            done(fallbackZ)
        end)
    end)
end

-- ---------------------------------------------------------------------------
-- RESOLVE STAGE 3 -- nudge the player clear of walls
-- ---------------------------------------------------------------------------

local function computeSitPushOffset(basePos, furniture, done)
    local rays, dirs = {}, {}
    for i = 0, PUSH_PROBE_COUNT - 1 do
        local angle = (i / PUSH_PROBE_COUNT) * (2 * math.pi)
        local dx, dy = math.sin(angle), math.cos(angle)
        rays[#rays + 1] = { basePos,
            util.vector3(basePos.x + dx * PUSH_PROBE_DIST,
                         basePos.y + dy * PUSH_PROBE_DIST, basePos.z) }
        dirs[#rays] = { dx = dx, dy = dy }
    end

    castBatch(rays, function(results)
        local pushX, pushY, totalW = 0, 0, 0
        for idx, res in pairs(results) do
            if res and res.hit and res.hitObject ~= furniture then
                local d = dirs[idx]
                local hdist = math.sqrt((res.hitPos.x - basePos.x)^2 +
                                        (res.hitPos.y - basePos.y)^2)
                if hdist < PUSH_PROBE_DIST then
                    local w = 1 - hdist / PUSH_PROBE_DIST
                    pushX = pushX - d.dx * w; pushY = pushY - d.dy * w
                    totalW = totalW + w
                end
            end
        end
        if totalW < 0.001 then return done(util.vector3(0, 0, 0)) end
        local len = math.sqrt(pushX^2 + pushY^2)
        if len < 0.001 then return done(util.vector3(0, 0, 0)) end
        local scale = PUSH_STRENGTH * math.min(1, totalW / (PUSH_PROBE_COUNT * 0.3))
        done(util.vector3(pushX / len * scale, pushY / len * scale, 0))
    end)
end

-- ---------------------------------------------------------------------------
-- CONTROL LOCK
-- ---------------------------------------------------------------------------
-- One-shot switches instead of zeroing self.controls every frame. These persist
-- until cleared, so onLoad below force-releases them: unlike the old per-frame
-- writes, a lock left set would survive a reload and soft-lock the player.

local function lockControls()
    if controlsLocked then return end
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, false)
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping, false)
    controlsLocked = true
end

local function releaseControls()
    if not controlsLocked then return end
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, true)
    types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping, true)
    controlsLocked = false
end

-- ---------------------------------------------------------------------------
-- SIT / STAND
-- ---------------------------------------------------------------------------


-- ---------------------------------------------------------------------------
-- CAMERA OFFSET
-- ---------------------------------------------------------------------------
-- The player's chosen perspective is honoured -- this never switches the view.
-- Instead each view gets its own offset, because they need different framing
-- and use different APIs:
--
--   first person : camera.setFirstPersonOffset, a 3d vector measured from the
--                  character's head (x right, y forward, z up)
--   third person : camera.setFocalPreferredOffset, a 2d vector from the tracked
--                  position (x right, y up)
--
-- Vertical defaults are 0 in first person and -75 in third: the first person
-- camera already sits at head height so it usually needs nothing, while the
-- third person focal point frames seated from too high without help.
--
-- The built-in camera script manages the third person offset too, so it is
-- told to stand down for the duration via disableThirdPersonOffsetControl. The
-- tag is this mod's name, so it cannot clash with another mod holding its own.

local SETTINGS_PAGE  = "TakeASeat"
local SETTINGS_GROUP = "SettingsTakeASeatCamera"
local CAMERA_TAG     = "TakeASeat"

-- ---------------------------------------------------------------------------
-- SETTINGS RENDERERS
-- ---------------------------------------------------------------------------
-- SuperSettingsRenderers ships a real slider ("SuperSlider6") with step
-- arrows, min/max labels, a default marker and a reset button. It is an
-- OPTIONAL dependency: it advertises itself in a session-lifetime storage
-- section, so its presence can be checked without requiring anything from it.
--
-- The section carries both an exact id ("SuperSlider6" = true) and a family
-- version ("SuperSlider" = 6), so checking the family means a future
-- SuperSlider7 is picked up without a code change here.
--
-- Absent, everything falls back to the built-in "number" renderer and the
-- settings behave exactly as before, just without the slider.

local installedRenderers = storage.playerSection("InstalledSettingsRenderers")

local function sliderAvailable()
    local ok, version = pcall(function() return installedRenderers:get("SuperSlider") end)
    return ok and type(version) == "number" and version >= 6
end

local HAS_SLIDER = sliderAvailable()

-- Builds a slider setting when the renderer is present, and an equivalent
-- number setting when it is not. `default` is repeated inside argument on
-- purpose: the slider needs it there for the default marker and reset button.
local function numberSetting(key, name, description, default, min, max, step, unit)
    if HAS_SLIDER then
        return {
            key = key, name = name, description = description,
            renderer = "SuperSlider6", default = default,
            argument = {
                min = min, max = max, step = step or 1,
                default = default,
                showDefaultMark = true,
                showResetButton = true,
                tinyReset       = true,
                minLabel = tostring(min),
                maxLabel = tostring(max),
                unit = unit,
                width = 220,
            },
        }
    end
    return {
        key = key, name = name, description = description,
        renderer = "number", integer = true, default = default,
        argument = { min = min, max = max },
    }
end

I.Settings.registerPage {
    key         = SETTINGS_PAGE,
    l10n        = "none",
    name        = "Take a Seat",
    description = "Camera framing while seated.",
}

I.Settings.registerGroup {
    key              = SETTINGS_GROUP,
    page             = SETTINGS_PAGE,
    l10n             = "none",
    name             = "Camera offset",
    description      = "Adjusts the camera while seated. Each perspective is"
                    .. " offset separately; neither changes which view you are in.",
    permanentStorage = true,
    order            = 0,
    settings = {
        {
            key         = "CAMERA_OFFSET_ENABLED",
            name        = "Adjust camera",
            description = "Turn off to leave the camera exactly as it is normally.",
            renderer    = "checkbox",
            default     = true,
        },
        numberSetting("FP_OFFSET_V", "First person: vertical offset",
            "Negative lowers the view.",
            0, -400, 400, 1, "u"),
        numberSetting("FP_OFFSET_H", "First person: horizontal offset",
            "Positive shifts right, negative left.",
            0, -400, 400, 1, "u"),
        numberSetting("TP_OFFSET_V", "Third person: vertical offset",
            "Negative lowers the view.",
            -75, -400, 400, 1, "u"),
        numberSetting("TP_OFFSET_H", "Third person: horizontal offset",
            "Positive shifts right, negative left.",
            0, -400, 400, 1, "u"),
    },
}

local cameraSettings   = storage.playerSection(SETTINGS_GROUP)
local cameraOffsetHeld = false

local function clearCameraOffset()
    if not cameraOffsetHeld then return end
    camera.setFirstPersonOffset(util.vector3(0, 0, 0))
    camera.setFocalPreferredOffset(util.vector2(0, 0))
    if I.Camera and I.Camera.enableThirdPersonOffsetControl then
        I.Camera.enableThirdPersonOffsetControl(CAMERA_TAG)
    end
    cameraOffsetHeld = false
end

local function applyCameraOffset()
    if not isSitting or not cameraSettings:get("CAMERA_OFFSET_ENABLED") then
        clearCameraOffset()
        return
    end

    if not cameraOffsetHeld then
        if I.Camera and I.Camera.disableThirdPersonOffsetControl then
            I.Camera.disableThirdPersonOffsetControl(CAMERA_TAG)
        end
        cameraOffsetHeld = true
    end

    -- Only the active view is offset and the other is zeroed, so a stale value
    -- cannot survive a perspective change. Vanity and preview modes are
    -- third-person-shaped, so anything that is not FirstPerson takes the third
    -- person offset.
    if camera.getMode() == camera.MODE.FirstPerson then
        camera.setFirstPersonOffset(util.vector3(
            cameraSettings:get("FP_OFFSET_H") or 0,
            0,
            cameraSettings:get("FP_OFFSET_V") or 0))
        camera.setFocalPreferredOffset(util.vector2(0, 0))
    else
        camera.setFocalPreferredOffset(util.vector2(
            cameraSettings:get("TP_OFFSET_H") or 0,
            cameraSettings:get("TP_OFFSET_V") or -75))
        camera.setFirstPersonOffset(util.vector3(0, 0, 0))
    end
end

-- Live update: changing a value in the settings menu applies immediately
-- instead of waiting for the next seated session.
cameraSettings:subscribe(async:callback(function()
    applyCameraOffset()
end))

-- ---------------------------------------------------------------------------
-- PERSPECTIVE CHANGE
-- ---------------------------------------------------------------------------
-- Switching perspective rebuilds the player's animation object and drops
-- scripted animations with it, so the sitting pose vanishes on a POV press.
-- The camera is deliberately NOT locked to work around that -- being able to
-- look at the pose is the point -- so instead the pose is re-issued after the
-- switch settles.
--
-- I.AnimRefresh defers past the skeleton rebuild before calling back; firing
-- immediately would re-issue onto a skeleton about to be replaced.
local function onPerspectiveChanged()
    -- Runs even when not seated so a lingering offset is released if the sit
    -- ended while the notification was still settling.
    applyCameraOffset()
    if not (isSitting and sitAnimStarted and currentSitAnim) then return end
    replayCount, replayWindowStart = 0, core.getSimulationTime()
    anim.playBlended(self, currentSitAnim,
        { loops = SIT_LOOPS, priority = SIT_PRIORITY })
end

local function subscribeRefresh()
    if I.AnimRefresh and I.AnimRefresh.subscribe then
        I.AnimRefresh.subscribe("SitOnFurniture", onPerspectiveChanged)
    end
end

local function unsubscribeRefresh()
    if I.AnimRefresh and I.AnimRefresh.unsubscribe then
        I.AnimRefresh.unsubscribe("SitOnFurniture")
    end
end

local function commitSit(furniture, chairPos, sitPos, yaw)
    currentFurniture = furniture
    originalChairPos = furniture.position
    originalChairRot = furniture.rotation
    currentSitAnim   = resolveSitAnim(getSeatType(furniture.recordId))

    core.sendGlobalEvent('SitTeleport', {
        position     = sitPos,
        yaw          = yaw,
        furniture    = furniture,
        furniturePos = chairPos,
    })

    -- Public hook. Add-ons (see the FPV_experimental package) listen for these
    -- rather than patching this script; nothing here depends on anyone doing so.
    self.object:sendEvent('TakeASeat_Seated', {
        furniture = furniture,
        seatType  = getSeatType(furniture.recordId),
        animGroup = currentSitAnim,
    })

    isSitting      = true
    sitAnimStarted = false
    resolveActive  = false
    lockControls()
    subscribeRefresh()
    applyCameraOffset()
    -- Immersive FPV (a separate, third-party mod) listens for this to drop its
    -- simulated eye height while seated. Unrelated to the FPV_experimental
    -- add-on; harmless when neither is installed.
    self.object:sendEvent('FPV_SetEyeDropOverride', { offset = -60 })
end

local function beginSit(furniture)
    if not furniture or not furniture:isValid() then return end

    abortResolve()                    -- invalidate anything still in flight
    local token = resolveToken
    resolveActive = true

    -- The player's chosen perspective is honoured: sitting never switches the
    -- camera. Use the per-view offsets in the settings menu to frame the pose
    -- instead. (An earlier version forced third person here and restored first
    -- person on standing, which overrode a deliberate choice and needed a
    -- settle delay before the teleport could land.)

    -- Safety net: if any callback in the chain never returns (object unloaded
    -- mid-flight, cell change), the resolve would otherwise hang forever and
    -- block all future sit attempts.
    async:newUnsavableSimulationTimer(RESOLVE_TIMEOUT, function()
        if token == resolveToken and resolveActive then
            if DEBUG then print("[sit] resolve timed out") end
            abortResolve()
        end
    end)

    resolveChairPosition(furniture, token, function(chairPos)
        if token ~= resolveToken then return end
        if not furniture:isValid() then return abortResolve() end

        computeSeatZ(chairPos, furniture, token, function(seatZ)
            if token ~= resolveToken then return end
            if not furniture:isValid() then return abortResolve() end

            local basePos = util.vector3(chairPos.x, chairPos.y, seatZ)
            computeSitPushOffset(basePos, furniture, function(offset)
                if token ~= resolveToken then return end
                if not furniture:isValid() then return abortResolve() end

                local sitPos = basePos + offset
                local yaw    = getObjectYaw(furniture)

                commitSit(furniture, chairPos, sitPos, yaw)
            end)
        end)
    end)
end

local function stopSitting()
    if not isSitting then return end
    anim.cancel(self, currentSitAnim)
    isSitting      = false
    sitAnimStarted = false
    abortResolve()
    self.object:sendEvent('TakeASeat_Stood', {})

    releaseControls()
    unsubscribeRefresh()
    clearCameraOffset()
    self.object:sendEvent('FPV_SetEyeDropOverride', { offset = 0 })

    if currentFurniture and originalChairPos then
        core.sendGlobalEvent('SitRestoreChair', {
            furniture = currentFurniture,
            position  = originalChairPos,
            rotation  = originalChairRot,
        })
    end
    currentFurniture, originalChairPos, originalChairRot = nil, nil, nil
end

-- ---------------------------------------------------------------------------
-- EVENT WIRING
-- ---------------------------------------------------------------------------

-- Replaces per-frame input.isActionPressed polling. Trigger handlers are
-- edge-driven by the engine and respect the player's keybinding, so the manual
-- was-down/is-down edge detection disappears too.
--
-- Guarded on HUD visibility, the same way SunsDusk gates its interaction
-- actions: a hidden HUD means a menu, dialogue or cutscene has the player's
-- attention, and Activate should not sit or stand through it. The guard covers
-- the whole handler rather than just the sit branch, so standing up is blocked
-- in those states too.
input.registerTriggerHandler("Activate", async:callback(function()
    if I.UI and I.UI.isHudVisible and not I.UI.isHudVisible() then return end
    if isSitting then
        stopSitting()
    elseif not resolveActive then
        findFurnitureAsync(function(furniture)
            if furniture then beginSit(furniture) end
        end)
    end
end))

-- Replaces the per-frame `not anim.isPlaying(...)` re-trigger poll. The hardcoded
-- character controller can cancel scripted animations at any time; this fires
-- when that happens instead of us checking every frame in case it did.
--
-- The poll was implicitly rate-limited by the frame rate. This is not, so a
-- group that ends immediately (typo'd name, missing text keys) would replay in
-- a tight loop. Bail out after a burst of rapid restarts rather than spin.
local REPLAY_BURST_LIMIT  = 5
local REPLAY_BURST_WINDOW = 1.0

if I.AnimationController and I.AnimationController.addAnimationEndedHandler then
    I.AnimationController.addAnimationEndedHandler(function(groupname)
        if not (isSitting and sitAnimStarted and groupname == currentSitAnim) then
            return
        end
        local now = core.getSimulationTime()
        if now - replayWindowStart > REPLAY_BURST_WINDOW then
            replayWindowStart, replayCount = now, 0
        end
        replayCount = replayCount + 1
        if replayCount > REPLAY_BURST_LIMIT then
            if DEBUG then
                print("[sit] '" .. tostring(currentSitAnim) ..
                      "' keeps ending immediately; check the group name and text keys")
            end
            sitAnimStarted = false   -- stop trying until the next sit
            return
        end
        anim.playBlended(self, currentSitAnim,
            { loops = SIT_LOOPS, priority = SIT_PRIORITY })
    end)
end

-- Replaces the accumulate-dt fatigue tick. Registered at file scope because
-- runRepeatedly stops evaluating across a save load unless started at init.
time.runRepeatedly(function()
    if not isSitting then return end
    local fatigue = types.Actor.stats.dynamic.fatigue(self)   -- documented as nil-able
    if fatigue then
        fatigue.current = math.min(fatigue.current + FATIGUE_TICK_AMOUNT, fatigue.base)
    end
end, FATIGUE_TICK_RATE)

local function onSitAnimStart()
    if not isSitting then return end
    -- Teleports land next frame, so give the position a beat to settle before
    -- the pose starts. The old code played immediately and relied on a per-frame
    -- isPlaying poll to recover if the controller rejected it; the ended-handler
    -- above now covers that case, so a short settle is enough.
    async:newUnsavableSimulationTimer(SIT_ANIM_WINDOW, function()
        if not isSitting then return end
        replayCount, replayWindowStart = 0, core.getSimulationTime()
        anim.playBlended(self, currentSitAnim,
            { loops = SIT_LOOPS, priority = SIT_PRIORITY })
        sitAnimStarted = true
    end)
end

-- Control switches are engine state and ARE written into the save, unlike the
-- old per-frame `self.controls.movement = 0` writes which simply stopped
-- happening. Saving mid-sit would therefore restore a player who cannot move.
-- Record the lock in the save and undo it on load, rather than blanket-clearing
-- the switches (which would stomp a lock some other mod legitimately holds).
local function onSave()
    return { controlsLocked = controlsLocked }
end

local function onLoad(data)
    isSitting, sitAnimStarted, resolveActive = false, false, false
    currentFurniture, originalChairPos, originalChairRot = nil, nil, nil
    resolveToken = resolveToken + 1
    unsubscribeRefresh()
    clearCameraOffset()
    -- Sit state does not survive a load: the chair's world transform is not
    -- restored either, which is a known limitation of this mod rather than
    -- something the rewrite introduces.
    if data and data.controlsLocked then
        controlsLocked = true
        releaseControls()
    else
        controlsLocked = false
    end
end

return {
    engineHandlers = { onSave = onSave, onLoad = onLoad },
    eventHandlers  = { SitAnimStart = onSitAnimStart },
}
