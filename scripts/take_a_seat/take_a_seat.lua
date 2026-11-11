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
local ui     = require('openmw.ui')
-- Named omwdebug, not debug: Lua's own debug library is a standard global
-- and shadowing it inside a 1300-line file is a trap for the next reader.
local omwdebug = require('openmw.debug')
local seats  = require('scripts.take_a_seat.sitAnim_shared')
local safety = require('scripts.take_a_seat.seat_safety')

-- seat_safety requires no openmw module of its own, so it takes what it needs
-- from here. One table, built once; agentBounds is a function because the
-- player's size can change (a scale-altering effect) between sits.
local SAFETY = {
    nearby = nearby,
    util   = util,
    agentBounds = function()
        return types.Actor.getPathfindingAgentBounds(self)
    end,
}

-- ---------------------------------------------------------------------------
-- SEAT PROFILES
-- ---------------------------------------------------------------------------

local getSeatType    = seats.getSeatType
local isSittable     = seats.isSittable
local resolveSitAnim = seats.animForSeat

local DEBUG = false

local SIT_LOOPS    = 999
local ONE_SHOT_TIMEOUT = 1.5

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

---@param group string|nil
---@return string|nil
local animHintGiven = false

local function playableGroup(group)
    if not group then return nil end
    if anim.hasGroup(self, group) then return group end
    for _, alt in ipairs(seats.groupFallbacks(group)) do
        if anim.hasGroup(self, alt) then
            if DEBUG then
                print(string.format("[sit] %s not on this skeleton; using %s",
                    group, alt))
            end
            return alt
        end
    end
    if DEBUG then
        print(string.format("[sit] no playable group for %s on this skeleton", group))
    end
    -- Almost always one cause: OpenMW loads this mod's animations/<skeleton>/
    -- folders only with "Use additional animation sources" on, and it is off
    -- by default. Measured in OpenMW 0.52: the player sat in the standing
    -- idle and nothing said why. Said once, not under DEBUG.
    if not animHintGiven then
        animHintGiven = true
        print("[sit] the sitting animations are missing on this skeleton. Turn on "
            .. "'Use additional animation sources' in the OpenMW launcher "
            .. "(settings.cfg: [Game] use additional anim sources = true).")
    end
    return nil
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

local SEAT_KEEP_RATE      = 0.25   -- seconds between checks while seated
local SEAT_KEEP_TOLERANCE = 6      -- units of drift tolerated before a re-assert

local EXIT_GLIDE_TIME  = 0.35      -- seconds
local EXIT_GLIDE_PROBE_Z = 40      -- torso height for the path check

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

local SEAT_OCCUPIED_RADIUS = 30
local SEAT_OCCUPIED_Z      = 90

---True for anything that can be talked to, pickpocketed or attacked.
---@param obj any
local function isActorObject(obj)
    if not obj or not obj.recordId then return false end
    local t = types
    return (t.NPC and t.NPC.objectIsInstance and t.NPC.objectIsInstance(obj))
        or (t.Creature and t.Creature.objectIsInstance and t.Creature.objectIsInstance(obj))
        or false
end

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
            local verdict = onHit(res)
            if verdict == 'stop' then return done(nil) end
            if verdict then return done(res) end
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
local standingPos    = nil
local standingFloorZ = nil
local standingCell   = nil
local plannedExit    = nil
local seatedFacing   = nil

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

---@return any furniture, boolean blocked
local function tryFurnitureFastPath()
    if not (I.SharedRay and I.SharedRay.get) then return nil, false end
    local result = I.SharedRay.get()
    if not result or not result.hit then return nil, false end
    local obj = result.hitObject
    if not obj or not obj:isValid() then return nil, false end
    if isActorObject(obj) then return nil, true end
    if not isSittable(obj.recordId) then return nil, false end
    return obj, false
end

local function seatOccupied(furniture)
    local fp = furniture.position
    for _, actor in ipairs(nearby.actors) do
        if actor.id ~= self.id and actor:isValid() then
            local ap = actor.position
            local dx, dy = ap.x - fp.x, ap.y - fp.y
            if (dx * dx + dy * dy) <= SEAT_OCCUPIED_RADIUS * SEAT_OCCUPIED_RADIUS
               and math.abs(ap.z - fp.z) <= SEAT_OCCUPIED_Z then
                return true
            end
        end
    end
    return false
end

local function findFurnitureAsync(done)
    local fast, blocked = tryFurnitureFastPath()
    if blocked then return done(nil) end
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
            if isActorObject(res.hitObject) then return 'stop' end
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
-- AUTHORED PLACEMENT (primary)
-- ---------------------------------------------------------------------------

local SCALE_MIN, SCALE_MAX = 0.25, 4.0

local MODEL_TYPES = { 'Static', 'Activator', 'Container', 'Door', 'Light',
                      'Miscellaneous' }

local function recordModelOf(obj)
    if not obj then return nil end
    for _, name in ipairs(MODEL_TYPES) do
        local t = types[name]
        if t and t.objectIsInstance and t.objectIsInstance(obj) and t.record then
            local rec = t.record(obj)
            if rec and rec.model and rec.model ~= '' then return rec.model end
        end
    end
    return nil
end

local function clampScale(scale)
    if type(scale) ~= 'number' then return 1 end
    if scale < SCALE_MIN then return SCALE_MIN end
    if scale > SCALE_MAX then return SCALE_MAX end
    return scale
end

local function rotateYaw(v, yawRadians)
    return util.transform.rotateZ(yawRadians):apply(v)
end

local function vec3(t)
    return util.vector3(t[1], t[2], t[3])
end

---@param slot table
---@param chosenYawDeg number|nil nil means use the slot's own yaw
local function localRootFor(slot, chosenYawDeg)
    if not slot.anchor or not slot.poseDelta then return vec3(slot.root) end
    local yawDeg = chosenYawDeg or slot.yaw
    return vec3(slot.anchor) + rotateYaw(vec3(slot.poseDelta), math.rad(yawDeg))
end

local function resolveSeatPose(furniture)
    local kind, subType = seats.classify(furniture.recordId)
    if not kind then
        kind, subType = seats.TARGET_KIND.SEAT, getSeatType(furniture.recordId)
    end
    local group = seats.idleAnimFor(kind, subType)
                  or resolveSitAnim(getSeatType(furniture.recordId))
    return kind, subType, group
end

---World placement for an authored slot.
---@return table position, number yaw  -- yaw is ABSOLUTE world facing
local function authoredPlacement(furniture, slot, chosenYawDeg)
    local scale = clampScale(furniture.scale)
    local localRoot = localRootFor(slot, chosenYawDeg)
    local scaled = util.vector3(localRoot.x * scale, localRoot.y * scale,
                                localRoot.z * scale)
    local position = furniture.position + furniture.rotation:apply(scaled)
    local yawDeg = chosenYawDeg or slot.yaw
    local worldYaw = getObjectYaw(furniture) + math.rad(yawDeg)

    -- Reference-pose correction, in actor space: x right, y forward, z up.
    local _, _, group = resolveSeatPose(furniture)
    local delta = seats.poseDelta(group)
    if delta then
        position = position + rotateYaw(
            util.vector3(delta.x or 0, delta.y or 0, delta.z or 0), worldYaw)
    end
    return position, worldYaw
end

---@return table|nil slot
local function nearestSlot(furniture, profile)
    if not profile or not profile.slots or #profile.slots == 0 then return nil end
    if #profile.slots == 1 then return profile.slots[1] end

    local scale = clampScale(furniture.scale)
    local best, bestDist
    for _, slot in ipairs(profile.slots) do
        local localRoot = localRootFor(slot, nil)
        local world = furniture.position + furniture.rotation:apply(
            util.vector3(localRoot.x * scale, localRoot.y * scale,
                         localRoot.z * scale))
        local d = (world - self.position):length()
        if not bestDist or d < bestDist then best, bestDist = slot, d end
    end
    return best
end

local FACING_SCAN_RANGE = 400
local FACING_PROBE_Z    = 70

local function chooseFacing(furniture, profile, slot, done)
    if profile.facing == 'fixed' or not slot.anchor then
        return done(nil)                      -- authored yaw, no rays at all
    end

    local baseYaw = getObjectYaw(furniture)
    local candidates = {}
    if profile.facing == 'two_sided' then
        candidates = { slot.yaw, slot.yaw + 180 }
    else
        for i = 0, 7 do candidates[#candidates + 1] = slot.yaw + i * 45 end
    end

    -- Probe from the seat anchor, which is where the actor's torso will be.
    local anchorLocal = vec3(slot.anchor)
    local scale = clampScale(furniture.scale)
    local from = furniture.position + furniture.rotation:apply(
        util.vector3(anchorLocal.x * scale, anchorLocal.y * scale,
                     anchorLocal.z * scale)) + util.vector3(0, 0, FACING_PROBE_Z)

    local rays = {}
    for i, yawDeg in ipairs(candidates) do
        local a = baseYaw + math.rad(yawDeg)
        rays[i] = { from, from + util.vector3(math.sin(a), math.cos(a), 0)
                                   * FACING_SCAN_RANGE }
    end

    castBatch(rays, function(results)
        local bestYaw, bestClear = candidates[1], -1
        for i, yawDeg in ipairs(candidates) do
            local res = results[i]
            local clear = FACING_SCAN_RANGE
            if res and res.hit and res.hitObject ~= furniture then
                clear = (res.hitPos - from):length()
            end
            if clear > bestClear then bestClear, bestYaw = clear, yawDeg end
        end
        done(bestYaw)
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

local function setControlLock(on)
    if I.Controls and I.Controls.overrideMovementControls then
        I.Controls.overrideMovementControls(on)
        if I.Controls.overrideCombatControls then
            I.Controls.overrideCombatControls(on)
        end
    else
        types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, not on)
        types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping, not on)
    end
end

-- Parkourwind FLOW reads any not-grounded player as mid-jump, and a seated
-- player is placed on the seat with collision off, so it is never grounded:
-- measured in OpenMW 0.52, FLOW sat in Airborne for the whole sit. Jump stands
-- the player up, and with FLOW Airborne and that jump held, the stand-up glide
-- beside a table is exactly where FLOW looks for a vault or a mantle. So the
-- sit yields FLOW, from before the control lock until it is released after
-- the exit clip. Optional: absent FLOW, nothing happens.
--
-- YIELD BEFORE THE LOCK. overrideMovementControls is one flag shared by every
-- mod; FLOW releases its own hold on it as it stands down, and that write must
-- land before ours, not over it.
local FLOW_OWNER = 'TakeASeat'
local function flowYield(on)
    local F = I.Flow
    if not (F and F.yield and F.resume) then return end
    if on then F.yield(FLOW_OWNER) else F.resume(FLOW_OWNER) end
end

local function lockControls()
    if controlsLocked then return end
    flowYield(true)
    setControlLock(true)
    controlsLocked = true
end

local function releaseControls()
    if not controlsLocked then return end
    setControlLock(false)
    controlsLocked = false
    flowYield(false)
end

-- ---------------------------------------------------------------------------
-- CAMERA OFFSET
-- ---------------------------------------------------------------------------

local SETTINGS_PAGE  = "TakeASeat"
local SETTINGS_GROUP = "SettingsTakeASeatCamera"
local SEATING_GROUP  = "SettingsTakeASeatSeating"
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

I.Settings.registerGroup {
    key              = SEATING_GROUP,
    page             = SETTINGS_PAGE,
    l10n             = "none",
    name             = "Sitting",
    description      = "How the mod holds you in a seat, and how it puts you"
                    .. " down when you get up.",
    permanentStorage = true,
    order            = 1,
    settings = {
        {
            key         = "COLLISION_OFF",
            name        = "Hold the seat with collision off",
            description = "Your collision is standing height even when you are"
                        .. " sitting, so at a table the engine pushes you up"
                        .. " onto it. Turning collision off while seated"
                        .. " removes that push. It is restored when you stand,"
                        .. " and on loading a save made while seated. Turn this"
                        .. " off to keep collision on; the mod will then nudge"
                        .. " you back into the seat instead, which can be"
                        .. " visible.",
            renderer    = "checkbox",
            default     = true,
        },
        {
            key         = "EXIT_GLIDE",
            name        = "Glide out of the seat",
            description = "The stand-up animation does not move you, so without"
                        .. " this you snap to your feet position at the end of"
                        .. " it. Turn off for the snap.",
            renderer    = "checkbox",
            default     = true,
        },
    },
}

local cameraSettings   = storage.playerSection(SETTINGS_GROUP)
local seatingSettings  = storage.playerSection(SEATING_GROUP)
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

local animRefreshWarned = false

local function subscribeRefresh()
    if I.AnimRefresh and I.AnimRefresh.subscribe then
        I.AnimRefresh.subscribe("SitOnFurniture", onPerspectiveChanged)
    elseif not animRefreshWarned then
        animRefreshWarned = true
        print('[take a seat] AnimRefresh interface not found; the sit pose will '
            .. 'not be restored after a perspective change, Rest, Travel or a '
            .. 'game load. Check that scripts/AnimRefresh/ is registered in an '
            .. 'enabled .omwscripts.')
    end
end

local function unsubscribeRefresh()
    if I.AnimRefresh and I.AnimRefresh.unsubscribe then
        I.AnimRefresh.unsubscribe("SitOnFurniture")
    end
end

-- ---------------------------------------------------------------------------
-- HOLDING THE SEAT
-- ---------------------------------------------------------------------------

local collisionDisabled = false    -- disabled BY US, not by the player's own TCL
local seatHoldPos       = nil
local seatHolds         = 0        -- re-asserts this sit, for the log
local stopSeatKeeper    = nil

local function setSeatCollision(enabled)
    if enabled then
        if not collisionDisabled then return end
        if not omwdebug.isCollisionEnabled() then omwdebug.toggleCollision() end
        collisionDisabled = false
        return
    end
    if collisionDisabled then return end
    if not seatingSettings:get("COLLISION_OFF") then return end
    if omwdebug.isCollisionEnabled() then
        omwdebug.toggleCollision()
        collisionDisabled = true
    end
end

local function stopHoldingSeat()
    if stopSeatKeeper then stopSeatKeeper() end
    stopSeatKeeper = nil
    seatHoldPos    = nil
    if DEBUG and seatHolds > 0 then
        print(string.format("[sit] held the seat %d time(s) this sit", seatHolds))
    end
    seatHolds = 0
end

local function startHoldingSeat(pos)
    seatHoldPos = pos
    seatHolds   = 0
    if stopSeatKeeper then return end
    stopSeatKeeper = time.runRepeatedly(function()
        if not (isSitting and seatHoldPos) then return end
        local drift = (self.position - seatHoldPos):length()
        if drift <= SEAT_KEEP_TOLERANCE then return end
        seatHolds = seatHolds + 1
        if DEBUG then
            print(string.format("[sit] drifted %.1f units; re-seating", drift))
        end
        core.sendGlobalEvent('SitPlacePlayer', { position = seatHoldPos })
    end, SEAT_KEEP_RATE)
end

---@param chairPos table|nil nil means do not move the furniture
---@param yawAbsolute boolean|nil true when `yaw` is already the world facing
local function commitSit(furniture, chairPos, sitPos, yaw, yawAbsolute)
    currentFurniture = furniture
    originalChairPos = chairPos and furniture.position or nil
    originalChairRot = chairPos and furniture.rotation or nil
    currentKind, currentSubType, currentSitAnim = resolveSeatPose(furniture)

    core.sendGlobalEvent('SitTeleport', {
        position     = sitPos,
        yaw          = yaw,
        yawAbsolute  = yawAbsolute and true or nil,
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
    setSeatCollision(false)
    startHoldingSeat(sitPos)
    lockControls()
    subscribeRefresh()
    applyCameraOffset()
    self.object:sendEvent('FPV_SetEyeDropOverride', { offset = -60 })
end

---@param yawAbsolute boolean|nil as passed to commitSit
---@return boolean committed
local function gateAndCommit(furniture, chairPos, sitPos, yaw, yawAbsolute)
    local facing = yawAbsolute and yaw or (yaw + math.pi)

    local reason, exit, what = safety.sitRejectReason(
        SAFETY, furniture, sitPos, facing, standingPos, standingFloorZ)
    if reason then
        abortResolve()
        if DEBUG then
            print(string.format("[sit] refusing %s: %s",
                tostring(furniture.recordId), reason))
        end
        ui.showMessage("There is no room to get up from there.")
        return false
    end

    plannedExit, seatedFacing = exit, facing
    if DEBUG then
        print(string.format("[sit] exit validated: %s", tostring(what)))
    end
    commitSit(furniture, chairPos, sitPos, yaw, yawAbsolute)
    return true
end

local function beginSit(furniture)
    if not furniture or not furniture:isValid() then return end
    if seatOccupied(furniture) then
        if DEBUG then print("[sit] that seat is taken") end
        return
    end

    standingPos    = self.position
    standingCell   = self.cell
    standingFloorZ = nil
    local ground = safety.groundBelow(SAFETY, standingPos, furniture)
    if ground then standingFloorZ = ground.z end

    abortResolve()                    -- invalidate anything still in flight
    local token = resolveToken
    resolveActive = true

    async:newUnsavableSimulationTimer(RESOLVE_TIMEOUT, function()
        if token == resolveToken and resolveActive then
            if DEBUG then print("[sit] resolve timed out") end
            abortResolve()
        end
    end)

    local model   = recordModelOf(furniture)
    local profile = seats.solverProfile(model)
    local slot    = nearestSlot(furniture, profile)

    if profile and slot then
        chooseFacing(furniture, profile, slot, function(chosenYawDeg)
            if token ~= resolveToken then return end
            if not furniture:isValid() then return abortResolve() end

            local sitPos, worldYaw = authoredPlacement(furniture, slot, chosenYawDeg)
            if DEBUG then
                print(string.format(
                    "[sit] authored %s (%s/%s) model=%s scale=%.2f slot=%s yaw=%s",
                    tostring(furniture.recordId), tostring(profile.seatType),
                    tostring(profile.facing), tostring(model),
                    furniture.scale or 1, tostring(slot.id),
                    tostring(chosenYawDeg or slot.yaw)))
            end
            -- chairPos nil: the furniture stays where the author placed it.
            gateAndCommit(furniture, nil, sitPos, worldYaw, true)
        end)
        return
    end

    if DEBUG then
        print(string.format("[sit] no authored profile for %s (model=%s); raycasting",
            tostring(furniture.recordId), tostring(model)))
    end

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

                gateAndCommit(furniture, chairPos, basePos + offset,
                              getObjectYaw(furniture), false)
            end)
        end)
    end)
end

local function usableOrigin()
    if not standingPos then return nil end
    if standingCell and self.cell ~= standingCell then return nil end
    return standingPos
end

---@return number seconds the move will take
local function commitStandPoint(furniture)
    local from = self.position
    local origin = usableOrigin()
    local target, what = safety.chooseStandPoint(
        SAFETY, from, seatedFacing, origin, furniture,
        origin and standingFloorZ or nil)
    if not target then
        target, what = plannedExit, 'gate-validated exit (re-check failed)'
    end
    plannedExit, seatedFacing = nil, nil
    standingPos, standingFloorZ, standingCell = nil, nil, nil

    if not target then
        if DEBUG then print("[sit] stand-up: no validated point (" ..
                            tostring(what) .. "); not moving the player") end
        return 0
    end

    local glide = seatingSettings:get("EXIT_GLIDE") and true or false
    if glide and not collisionDisabled then
        glide = safety.pathClear(SAFETY, from, target, EXIT_GLIDE_PROBE_Z,
                                 furniture)
        if not glide and DEBUG then
            print("[sit] stand-up path is blocked; snapping instead")
        end
    end

    if DEBUG then
        print(string.format("[sit] stand-up to %s, %.1f units, %s",
            tostring(what), (target - from):length(),
            glide and 'gliding' or 'snapping'))
    end
    core.sendGlobalEvent('SitPlacePlayer', {
        position = target,
        from     = glide and from or nil,
        duration = glide and EXIT_GLIDE_TIME or nil,
    })
    return glide and EXIT_GLIDE_TIME or 0
end

local function stopSitting()
    if not isSitting then return end
    anim.cancel(self, currentSitAnim)

    local exitGroup = playableGroup(seats.exitAnimFor(currentKind, currentSubType))
    local furnitureRef = currentFurniture

    isSitting      = false
    sitAnimStarted = false
    abortResolve()
    self.object:sendEvent('TakeASeat_Stood', {})

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

    stopHoldingSeat()
    local moveTime = commitStandPoint(furnitureRef)

    async:newUnsavableSimulationTimer(moveTime + 0.05, function()
        if isSitting then return end
        setSeatCollision(true)
    end)

    playOneShot(exitGroup, 'exit', releaseControls)
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

-- ---------------------------------------------------------------------------
-- STAND UP ON MOVEMENT INPUT
-- ---------------------------------------------------------------------------
local STANDUP_ACTIONS = { 'MoveForward', 'MoveBackward', 'MoveLeft',
                          'MoveRight', 'Jump' }

local function actionPressed(value)
    if value == true then return true end
    return type(value) == 'number' and value > 0.5
end

local function bindStandUpActions()
    if not (input.registerActionHandler and input.actions) then
        print("[sit] this build has no named input actions; " ..
              "Activate still stands you up")
        return
    end
    local bound, absent = {}, {}
    for _, key in ipairs(STANDUP_ACTIONS) do
        if input.actions[key] then
            input.registerActionHandler(key, async:callback(function(value)
                if isSitting and sitAnimStarted and actionPressed(value) then
                    stopSitting()
                end
            end))
            bound[#bound + 1] = key
        elseif input.triggers and input.triggers[key] then
            -- OpenMW 0.52 has Jump as a TRIGGER, not a named action: this
            -- loop used to report "this build has no Jump", and Jump did
            -- nothing while seated. Measured in-engine with vanilla bindings.
            input.registerTriggerHandler(key, async:callback(function()
                if I.UI and I.UI.getMode() ~= nil then return end
                if isSitting and sitAnimStarted then stopSitting() end
            end))
            bound[#bound + 1] = key .. ' (trigger)'
        else
            absent[#absent + 1] = key
        end
    end
    print(string.format("[sit] stand up on movement: %s%s",
        #bound > 0 and table.concat(bound, ', ') or 'nothing bound',
        #absent > 0 and ('; this build has no ' .. table.concat(absent, ', ')) or ''))
end

bindStandUpActions()

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
        playOneShot(playableGroup(seats.enterAnimFor(currentKind, currentSubType)), 'enter', function()
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
    local exit = nil
    if isSitting then exit = plannedExit or standingPos end
    return { controlsLocked = controlsLocked, chair = chair,
             collisionDisabled = collisionDisabled or nil, exit = exit }
end

local function onLoad(data)
    isSitting, sitAnimStarted, resolveActive = false, false, false
    currentFurniture, originalChairPos, originalChairRot = nil, nil, nil
    standingPos, standingFloorZ, standingCell = nil, nil, nil
    plannedExit, seatedFacing = nil, nil
    resolveToken = resolveToken + 1
    stopHoldingSeat()
    unsubscribeRefresh()
    clearCameraOffset()

    if data and data.collisionDisabled then
        collisionDisabled = true
        if data.exit then
            core.sendGlobalEvent('SitPlacePlayer', { position = data.exit })
            async:newUnsavableSimulationTimer(0.15, function()
                if not isSitting then setSeatCollision(true) end
            end)
        else
            setSeatCollision(true)
        end
    else
        collisionDisabled = false
        if data and data.exit then core.sendGlobalEvent('SitPlacePlayer', { position = data.exit }) end
    end
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
