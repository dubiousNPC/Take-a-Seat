---@omw-context player
-- Take a Seat: sit on furniture. Activate a seat to sit, Activate again to stand.

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
-- SEAT PROFILES
-- ---------------------------------------------------------------------------

local getSeatType    = seats.getSeatType
local isSittable     = seats.isSittable
local resolveSitAnim = seats.animForSeat

local DEBUG = false

local SIT_LOOPS    = 999

-- Longest an enter/exit one-shot is allowed to hold up the sit.
local ONE_SHOT_TIMEOUT = 1.0

-- Per-target-kind priority and blend masks
local ANIM_PROFILES = seats.buildAnimProfiles(anim)

-- What is currently being sat on: seat | bed | misc, and its sub-type.
local currentKind, currentSubType = nil, nil

---Profile for the current target
local function profileFor(phase)
    local kind = ANIM_PROFILES[currentKind or seats.TARGET_KIND.SEAT]
                 or ANIM_PROFILES[seats.TARGET_KIND.SEAT]
    return kind[phase]
end

local pendingOneShot = {}

---@param group string|nil
---@param phase string 'enter' | 'exit'
---@param done function
local function playOneShot(group, phase, done)
    if not group then return done() end

    local profile = profileFor(phase)
    local finished = false
    local function finish()
        if finished then return end
        finished = true
        if pendingOneShot[group] == finish then pendingOneShot[group] = nil end
        done()
    end

    pendingOneShot[group] = finish

    anim.playBlended(self, group, {
        loops       = profile.loops,
        priority    = profile.priority,
        blendMask   = profile.blendMask,
        autoDisable = true,
    })

    -- Backstop. A missing clip never ends because it never started.
    async:newUnsavableSimulationTimer(ONE_SHOT_TIMEOUT, finish)
end

-- ---------------------------------------------------------------------------
-- RESOLVE LATENCY
-- ---------------------------------------------------------------------------
local RESOLVE_TIMEOUT   = 3.0   -- seconds; abort a chain that never completes

local MAX_PIERCES       = 4
local SEAT_PROBE_START  = 150
local SEAT_PROBE_END    = 10
local SEAT_PROBE_RADIUS = 16
local SEAT_MAX_PIERCES  = 6     -- each pierce is an async round-trip
local SEAT_CLUSTER_DIST = 6

local FATIGUE_TICK_RATE   = 1     -- seconds
local FATIGUE_TICK_AMOUNT = 20

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
local CHAIR_PUSH_MIN_DIST    = 45
local CHAIR_PUSH_MAX_MOVE    = 22
local CHAIR_PUSH_STEP        = 2
local CHAIR_PUSH_MAX_ITER    = 5     -- each iteration is an async round-trip
local CHAIR_PUSH_ORIGIN_DIST = 100
local CHAIR_PUSH_PROBE_ZS    = { -10, 35, 80 }

local SIT_ANIM_WINDOW    = 0.05

local function getObjectYaw(obj)
    local forward = obj.rotation:apply(util.vector3(0, 1, 0))
    return math.atan2(forward.x, forward.y)
end

-- ---------------------------------------------------------------------------
-- ASYNC RAY PRIMITIVES
-- ---------------------------------------------------------------------------

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

local replayCount, replayWindowStart = 0, 0

local resolveToken   = 0
local resolveActive  = false

local function abortResolve()
    resolveToken  = resolveToken + 1
    resolveActive = false
end

-- ---------------------------------------------------------------------------
-- TARGETING
-- ---------------------------------------------------------------------------

local function tryFurnitureFastPath()
    if not (I.SharedRay and I.SharedRay.get) then return nil end
    local result = I.SharedRay.get()
    if not result or not result.hit then return nil end
    local obj = result.hitObject
    if not obj or not obj:isValid() then return nil end
    if not isSittable(obj.recordId) then return nil end
    return obj
end

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
            print(string.format("[sit] TIP: if correct, add SIT_PIVOT_OFFSET[\"%s\"] = %.1f to sitAnim_shared.lua",
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
-- CAMERA OFFSET
-- ---------------------------------------------------------------------------

local SETTINGS_PAGE  = "TakeASeat"
local SETTINGS_GROUP = "SettingsTakeASeatCamera"
local CAMERA_TAG     = "TakeASeat"

-- ---------------------------------------------------------------------------
-- SETTINGS RENDERERS
-- ---------------------------------------------------------------------------

local installedRenderers = storage.playerSection("InstalledSettingsRenderers")

local function sliderAvailable()
    local version = installedRenderers:get("SuperSlider")
    return type(version) == "number" and version >= 6
end

local HAS_SLIDER = sliderAvailable()

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

cameraSettings:subscribe(async:callback(function()
    applyCameraOffset()
end))

-- ---------------------------------------------------------------------------
-- PERSPECTIVE CHANGE
-- ---------------------------------------------------------------------------
local function playSitIdle()
    local idle = profileFor('idle')
    anim.playBlended(self, currentSitAnim,
        { loops = SIT_LOOPS, priority = idle.priority, blendMask = idle.blendMask })
end

-- Re-issue only if the rebuild dropped the pose; a replay restarts it.
local function onPerspectiveChanged()
    applyCameraOffset()
    if not (isSitting and sitAnimStarted and currentSitAnim) then return end
    if anim.isPlaying(self, currentSitAnim) then return end
    replayCount, replayWindowStart = 0, core.getSimulationTime()
    playSitIdle()
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
    currentKind, currentSubType = seats.classify(furniture.recordId)
    if not currentKind then
        currentKind, currentSubType = seats.TARGET_KIND.SEAT,
                                      getSeatType(furniture.recordId)
    end

    currentSitAnim   = seats.idleAnimFor(currentKind, currentSubType)
                       or resolveSitAnim(getSeatType(furniture.recordId))

    core.sendGlobalEvent('SitTeleport', {
        position     = sitPos,
        yaw          = yaw,
        furniture    = furniture,
        furniturePos = chairPos,
    })

    -- Public hook. Add-ons
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
    self.object:sendEvent('FPV_SetEyeDropOverride', { offset = -60 })
end

local function beginSit(furniture)
    if not furniture or not furniture:isValid() then return end

    abortResolve()                    -- invalidate anything still in flight
    local token = resolveToken
    resolveActive = true

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

    local exitGroup = seats.exitAnimFor(currentKind, currentSubType)

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

    -- Played last, and nothing waits on it.
    playOneShot(exitGroup, 'exit', function() end)
    currentKind, currentSubType = nil, nil
end

-- ---------------------------------------------------------------------------
-- EVENT WIRING
-- ---------------------------------------------------------------------------

input.registerTriggerHandler("Activate", async:callback(function()
    if I.UI and I.UI.getMode() ~= nil then return end
    if isSitting then
        stopSitting()
    elseif not resolveActive then
        findFurnitureAsync(function(furniture)
            if furniture then beginSit(furniture) end
        end)
    end
end))

local REPLAY_BURST_LIMIT  = 5
local REPLAY_BURST_WINDOW = 1.0

if I.AnimationController and I.AnimationController.addAnimationEndedHandler then
    I.AnimationController.addAnimationEndedHandler(function(groupname)
        local oneShot = pendingOneShot[groupname]
        if oneShot then oneShot() return end
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
        playSitIdle()
    end)
end

time.runRepeatedly(function()
    if not isSitting then return end
    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    if fatigue then
        local max = fatigue.base + fatigue.modifier
        if fatigue.current < max then
            fatigue.current = math.min(fatigue.current + FATIGUE_TICK_AMOUNT, max)
        end
    end
end, FATIGUE_TICK_RATE)

local function onSitAnimStart()
    if not isSitting then return end
    async:newUnsavableSimulationTimer(SIT_ANIM_WINDOW, function()
        if not isSitting then return end
        playOneShot(seats.enterAnimFor(currentKind, currentSubType), 'enter', function()
            if not isSitting then return end
            replayCount, replayWindowStart = 0, core.getSimulationTime()
            playSitIdle()
            sitAnimStarted = true
        end)
    end)
end

-- A save made while seated keeps the chair's original placement so load can restore it.
local function onSave()
    local chair = nil
    if isSitting and currentFurniture and originalChairPos then
        chair = { furniture = currentFurniture, position = originalChairPos,
                  rotation = originalChairRot }
    end
    return { controlsLocked = controlsLocked, chair = chair }
end

local function onLoad(data)
    isSitting, sitAnimStarted, resolveActive = false, false, false
    currentFurniture, originalChairPos, originalChairRot = nil, nil, nil
    resolveToken = resolveToken + 1
    unsubscribeRefresh()
    clearCameraOffset()
    if data and data.controlsLocked then
        controlsLocked = true
        releaseControls()
    else
        controlsLocked = false
    end
    local chair = data and data.chair
    if chair and chair.furniture and chair.furniture:isValid() then
        core.sendGlobalEvent('SitRestoreChair', chair)
    end
end

return {
    engineHandlers = { onSave = onSave, onLoad = onLoad },
    eventHandlers  = { SitAnimStart = onSitAnimStart },
}
