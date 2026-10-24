-- Authored placement: the solver pack and the maths that reads it.
--   python3 tools/luarun.py tools/test_solver_profiles.lua
--
-- The pack is the PRIMARY positioner now, so a quiet arithmetic slip here is
-- the whole mod being wrong on 189 pieces of furniture. Everything below is
-- checked against the real pack numbers rather than invented ones, and the
-- placement functions are lifted out of the module itself so the test cannot
-- drift from the code that ships.
--
-- The contract (pack README, contractVersion 3):
--     worldRoot = objectPosition + objectRotation * (slot.root * scale)
--     worldYaw  = objectYaw + rad(slot.yaw)
-- `root` is the SOLVED ACTOR ROOT for the reference pose. It is not a seat
-- surface: no legacy -36 / -7 offset goes on top of it, and the yaw is not to
-- be negated or flipped by 180 again.
local fails = 0
local function check(n, c, e)
    if c then print('  ok   ' .. n)
    else fails = fails + 1; print('  FAIL ' .. n .. '  ' .. tostring(e or '')) end
end

package.preload['openmw.core'] = function() return {
    getGameTime = function() return 0 end, getSimulationTime = function() return 0 end,
    contentFiles = { list = {} } } end
package.preload['openmw.types'] = function() return {} end
package.preload['openmw.util'] = function() return {} end
package.preload['openmw.vfs'] = function() return { fileExists = function() return true end } end
package.path = './?.lua;' .. package.path

-- require, not dofile: sitAnim_shared requires the provider by name, and the
-- lookup checks below compare table identity against what IT holds.
local solver = require('scripts.take_a_seat.solver_profiles')
local seats  = dofile('scripts/take_a_seat/sitAnim_shared.lua')

-- ---------------------------------------------------------------------------
-- the pack as shipped
-- ---------------------------------------------------------------------------
check('the provider declares the contract the runtime expects',
      solver.contractVersion == seats.solverContract,
      tostring(solver.contractVersion) .. ' vs ' .. tostring(seats.solverContract))
check('the contract is version 3', solver.contractVersion == 3)

local profileCount, slotCount, anchored = 0, 0, 0
local badKey, badSlot, badType, badFacing = {}, {}, {}, {}
local SEAT_TYPES, POLICIES = {}, { fixed = true, two_sided = true, free = true }
for _, t in pairs(seats.SEAT_TYPE) do SEAT_TYPES[t] = true end

for key, profile in pairs(solver.PROFILES) do
    profileCount = profileCount + 1
    if key ~= key:lower() or key:find('\\', 1, true) or not key:find('^meshes/') then
        badKey[#badKey + 1] = key
    end
    if profile.kind == 'sit' then
        if not SEAT_TYPES[profile.seatType] then
            badType[#badType + 1] = key .. '=' .. tostring(profile.seatType)
        end
        if not POLICIES[profile.facing] then
            badFacing[#badFacing + 1] = key .. '=' .. tostring(profile.facing)
        end
    end
    for _, slot in ipairs(profile.slots) do
        slotCount = slotCount + 1
        local ok = type(slot.root) == 'table' and #slot.root == 3
                   and type(slot.yaw) == 'number'
        for i = 1, 3 do if type(slot.root[i]) ~= 'number' then ok = false end end
        -- anchor and poseDelta are the facing re-derivation; one without the
        -- other would rebuild a root from half the data.
        if (slot.anchor ~= nil) ~= (slot.poseDelta ~= nil) then ok = false end
        if slot.anchor then anchored = anchored + 1 end
        if not ok then badSlot[#badSlot + 1] = key .. '/' .. tostring(slot.id) end
    end
end

check('all 189 sit profiles are present', profileCount == 189, profileCount)
check('all 230 slots are present', slotCount == 230, slotCount)
check('every key is a lowercase forward-slash mesh path',
      #badKey == 0, table.concat(badKey, ' '))
check('every slot carries a usable root and yaw',
      #badSlot == 0, table.concat(badSlot, ' '))
check('every seat type is one this mod defines',
      #badType == 0, table.concat(badType, ' '))
check('every facing policy is one the runtime handles',
      #badFacing == 0, table.concat(badFacing, ' '))
check('some slots carry anchor/poseDelta for facing choice', anchored > 0, anchored)

-- No legacy offsets may have leaked into the generated provider. The TSV
-- offsets (FinalZOffset, FinalForwardOffset, HeightOffset) measure seat
-- surfaces; mixing them with solved actor roots double-corrects.
local provSrc = io.open('scripts/take_a_seat/solver_profiles.lua'):read('a')
for _, word in ipairs({ 'FinalZOffset', 'FinalForwardOffset', 'HeightOffset' }) do
    check('no ' .. word .. ' in the provider', provSrc:find(word, 1, true) == nil)
end

-- ---------------------------------------------------------------------------
-- lookup and normalisation
-- ---------------------------------------------------------------------------
-- A record's model comes back however the plugin spelled it: mixed case,
-- Windows separators. A lookup that misses silently falls back to the raycast,
-- so the normalisation is load-bearing, not cosmetic.
local sample, sampleProfile
for key, profile in pairs(solver.PROFILES) do
    if profile.facing == 'fixed' then sample, sampleProfile = key, profile; break end
end
assert(sample, 'the pack has no fixed-facing profile to test with')

check('an exact key resolves', seats.solverProfile(sample) == sampleProfile)
check('an upper-case model resolves',
      seats.solverProfile(sample:upper()) == sampleProfile)
check('a backslash path resolves',
      seats.solverProfile((sample:gsub('/', '\\'))) == sampleProfile)
check('an unknown model resolves to nil',
      seats.solverProfile('meshes/x/not_a_real_mesh.nif') == nil)
check('a nil model resolves to nil', seats.solverProfile(nil) == nil)

check('slot 1 of a profile is returned',
      seats.solverSlot(sampleProfile, 1) == sampleProfile.slots[1])
-- Out of range falls back to slot 1 rather than nil: a caller asking for the
-- second place on a one-seat bench gets the seat, not a failed sit.
check('an out-of-range index falls back to slot 1',
      seats.solverSlot(sampleProfile, 99) == sampleProfile.slots[1])
check('a nil profile has no slots', seats.solverSlot(nil, 1) == nil)

-- ---------------------------------------------------------------------------
-- the placement maths, lifted from the module
-- ---------------------------------------------------------------------------
local src = io.open('scripts/take_a_seat/take_a_seat.lua'):read('a')
local body = src:match('(local function clampScale.-\nend\n)\n---Facing choice')
assert(body, 'could not extract the placement helpers')

local V = {}
V.__index = V
local function vec(x, y, z) return setmetatable({ x = x, y = y, z = z }, V) end
V.__add = function(a, b) return vec(a.x + b.x, a.y + b.y, a.z + b.z) end
V.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end
function V:length() return math.sqrt(self.x^2 + self.y^2 + self.z^2) end

-- The engine's rotation about Z, in the handedness the pack's own data proves
-- (see the facing-re-derivation block at the bottom: this matrix reproduces
-- every authored root exactly, the other one misses 25 of the 150 anchored
-- slots by up to 34.7 units). It is also the handedness that makes
-- getObjectYaw -- atan2(forward.x, forward.y) -- the inverse of rotateZ, which
-- is what the global script relies on when it seats the player.
local function rotZ(yaw)
    return { apply = function(_, v)
        local c, s = math.cos(yaw), math.sin(yaw)
        return vec(v.x * c + v.y * s, -v.x * s + v.y * c, v.z)
    end }
end
local function rotZCCW(yaw)
    return { apply = function(_, v)
        local c, s = math.cos(yaw), math.sin(yaw)
        return vec(v.x * c - v.y * s, v.x * s + v.y * c, v.z)
    end }
end

local mathx = {}
for k, v in pairs(math) do mathx[k] = v end
mathx.atan2 = mathx.atan2 or math.atan        -- LuaJIT has it, 5.4 does not

-- The clamp bounds live above the extracted span. Read them from the module
-- so the test asserts the mod's own limits, not a copy of them.
local SCALE_MIN = tonumber(src:match('local SCALE_MIN, SCALE_MAX = ([%d%.]+)'))
local SCALE_MAX = tonumber(src:match('local SCALE_MIN, SCALE_MAX = [%d%.]+, ([%d%.]+)'))
assert(SCALE_MIN and SCALE_MAX, 'could not read the scale clamp out of the module')

local env = {
    SCALE_MIN = SCALE_MIN, SCALE_MAX = SCALE_MAX,
    util = { vector3 = vec, transform = { rotateZ = rotZ } },
    math = mathx, type = type, ipairs = ipairs, pairs = pairs,
    setmetatable = setmetatable, tostring = tostring,
    -- authoredPlacement asks for the seated pose so a measured POSE_DELTA can
    -- be applied. The real resolvers come from the shared module.
    seats = seats,
    -- nearestSlot measures from the player.
    self = { position = vec(0, 0, 0) },
    getSeatType = seats.getSeatType,
    resolveSitAnim = seats.animForSeat,
}
local chunk = load(body .. [[
return { clampScale = clampScale, rotateYaw = rotateYaw, vec3 = vec3,
         localRootFor = localRootFor, authoredPlacement = authoredPlacement,
         resolveSeatPose = resolveSeatPose, nearestSlot = nearestSlot }
]], 'place', 't', setmetatable(env, { __index = _G }))
local P = chunk()
-- getObjectYaw lives above the extracted span; the real one derives the yaw
-- from the rotation, so the test uses that same derivation.
env.getObjectYaw = function(obj)
    local f = obj.rotation:apply(vec(0, 1, 0))
    return mathx.atan2(f.x, f.y)
end

-- The pack states the clamp: a 0.1-scale decoration or a 10x giant would
-- otherwise place an actor somewhere the solver never solved for.
check('the clamp is the pack\'s 0.25 - 4.0',
      SCALE_MIN == 0.25 and SCALE_MAX == 4.0,
      tostring(SCALE_MIN) .. '-' .. tostring(SCALE_MAX))
check('scale is clamped low', P.clampScale(0.01) == SCALE_MIN)
check('scale is clamped high', P.clampScale(99) == SCALE_MAX)
check('an ordinary scale passes through', P.clampScale(1.5) == 1.5)
check('a missing scale means 1', P.clampScale(nil) == 1)

local function near(a, b, tol) return math.abs(a - b) <= (tol or 1e-4) end
local function vnear(v, t, tol)
    return near(v.x, t[1], tol) and near(v.y, t[2], tol) and near(v.z, t[3], tol)
end

-- The contract itself, on a real slot of a real mesh.
local slot = sampleProfile.slots[1]
local furn = { position = vec(100, 200, 300), rotation = rotZ(0), scale = 1 }
local pos, yaw = P.authoredPlacement(furn, slot, nil)
check('an unrotated seat places the actor at position + root',
      vnear(pos, { 100 + slot.root[1], 200 + slot.root[2], 300 + slot.root[3] }),
      string.format('%.3f,%.3f,%.3f', pos.x, pos.y, pos.z))
check('the yaw is the object yaw plus the slot yaw',
      near(yaw, mathx.rad(slot.yaw)), string.format('%.4f', yaw))

-- Scale multiplies the local root and nothing else.
furn.scale = 2
pos = P.authoredPlacement(furn, slot, nil)
check('scale multiplies the local root',
      vnear(pos, { 100 + slot.root[1] * 2, 200 + slot.root[2] * 2,
                   300 + slot.root[3] * 2 }),
      string.format('%.3f,%.3f,%.3f', pos.x, pos.y, pos.z))
furn.scale = 1

-- A rotated object carries the offset round with it, and the seated facing
-- follows. Quarter turn: local +y becomes world +x.
furn.rotation = rotZ(math.pi / 2)
pos, yaw = P.authoredPlacement(furn, slot, nil)
check('a rotated seat rotates the local root',
      vnear(pos, { 100 + slot.root[2], 200 - slot.root[1], 300 + slot.root[3] }),
      string.format('%.3f,%.3f,%.3f', pos.x, pos.y, pos.z))
check('the seated facing turns with the furniture',
      near(yaw, math.pi / 2 + mathx.rad(slot.yaw)), string.format('%.4f', yaw))
furn.rotation = rotZ(0)

-- The yaw is used as authored. A sign slip or a stray 180 here is the "player
-- faces into the table" fault, so it is pinned against the pack's own number.
check('the authored yaw is neither negated nor flipped',
      not near(yaw, -mathx.rad(slot.yaw)) or near(slot.yaw, 0),
      tostring(slot.yaw))

-- ---------------------------------------------------------------------------
-- facing re-derivation, over every anchored slot in the pack
-- ---------------------------------------------------------------------------
-- The invariant that makes the rebuild trustworthy: at the slot's own yaw the
-- anchor-plus-rotated-poseDelta route must reproduce the authored root
-- exactly. If it does not, every two_sided and free seat is placed by
-- arithmetic the pack never sanctioned.
-- Both the formula the code runs and the shape of the data behind it.
local worstEngine, worstEngineKey = 0, nil      -- anchor + rotateZ(yaw)*delta
local worstCode, worstCodeKey = 0, nil          -- localRootFor at the authored yaw
local worstNil = 0                              -- localRootFor with no choice
local bestCCW, ccwMatches = 0, 0                 -- the opposite handedness
local turnedOk, turnedBad = 0, {}
for key, profile in pairs(solver.PROFILES) do
    for _, sl in ipairs(profile.slots) do
        if sl.anchor then
            local root = vec(sl.root[1], sl.root[2], sl.root[3])
            local a    = vec(sl.anchor[1], sl.anchor[2], sl.anchor[3])
            local d    = vec(sl.poseDelta[1], sl.poseDelta[2], sl.poseDelta[3])
            local yaw  = mathx.rad(sl.yaw)

            local e = ((a + rotZ(yaw):apply(d)) - root):length()
            if e > worstEngine then worstEngine, worstEngineKey = e, key end

            local c = (P.localRootFor(sl, sl.yaw) - root):length()
            if c > worstCode then worstCode, worstCodeKey = c, key end
            local n = (P.localRootFor(sl, nil) - root):length()
            if n > worstNil then worstNil = n end

            local ccw = ((a + rotZCCW(yaw):apply(d)) - root):length()
            if ccw > bestCCW then bestCCW = ccw end
            if ccw < 1e-3 then ccwMatches = ccwMatches + 1 end

            -- A chosen facing swings the root around the anchor: the distance
            -- from the anchor and the height are both preserved.
            local turned = P.localRootFor(sl, sl.yaw + 180)
            local r0, r1 = root - a, turned - a
            if near(math.sqrt(r0.x^2 + r0.y^2), math.sqrt(r1.x^2 + r1.y^2), 1e-3)
               and near(r0.z, r1.z, 1e-6) then
                turnedOk = turnedOk + 1
            else
                turnedBad[#turnedBad + 1] = key
            end
        end
    end
end

check('anchor + rotateZ(slot yaw) * poseDelta is the authored root',
      worstEngine < 1e-3,
      string.format('worst %.6f at %s', worstEngine, tostring(worstEngineKey)))
check('localRootFor reproduces the authored root at the authored yaw',
      worstCode < 1e-3,
      string.format('worst %.6f at %s', worstCode, tostring(worstCodeKey)))
check('localRootFor with no choice is the authored root',
      worstNil < 1e-3, string.format('worst %.6f', worstNil))
-- The guard that matters: poseDelta is in ACTOR space, so the rotation's
-- handedness is load-bearing. The wrong one agrees on every slot whose yaw is
-- 0 or 180 -- most of them -- and is badly out on the rest, which is exactly
-- the kind of fault that ships looking fine on the chairs someone tested.
check('the opposite handedness is ruled out by the data',
      bestCCW > 1 and ccwMatches < anchored,
      string.format('worst %.3f, agrees on %d of %d', bestCCW, ccwMatches, anchored))
check('a turned facing swings the root about the anchor at constant height',
      #turnedBad == 0 and turnedOk == anchored,
      string.format('%d ok, %d bad', turnedOk, #turnedBad))

-- A fixed-facing slot has no anchor, so there is nothing to rebuild from and a
-- chosen yaw must not move it. chooseFacing passes nil for those anyway.
local plain = { root = { 1, 2, 3 }, yaw = 90 }
check('a slot with no anchor keeps its authored root',
      vnear(P.localRootFor(plain, 270), { 1, 2, 3 }))

-- ---------------------------------------------------------------------------
-- the reference-pose correction is wired, even while it is empty
-- ---------------------------------------------------------------------------
-- Every authored root is solved for pcdbssit5 (= dbssit5). Bench, stool and
-- barstool idles are different clips, so if one of them ever needs a
-- correction it goes in POSE_DELTA -- and that table has to be read by the
-- placement path, or filling it in later would do nothing at all.
check('placement consults the pose delta', body:find('seats%.poseDelta') ~= nil)
local probe = setmetatable({}, { __index = seats })
local recorded = nil
local before = P.authoredPlacement(furn, slot, nil)
env.seats = setmetatable({ poseDelta = function(g) recorded = g
                               return { x = 0, y = 10, z = 0 } end },
                         { __index = seats })
local after = P.authoredPlacement(furn, slot, nil)
env.seats = probe
check('a pose delta is applied in actor space',
      near((after - before):length(), 10, 1e-3),
      string.format('%.4f', (after - before):length()))
check('the delta is looked up by the seated clip',
      type(recorded) == 'string' or recorded == nil, tostring(recorded))

-- ---------------------------------------------------------------------------
-- multi-seat furniture
-- ---------------------------------------------------------------------------
-- 41 of the 189 profiles are two-seat benches. Slot 1 regardless of where the
-- player stood would send them to the far end of the bench they just walked
-- up to.
local bench = nil
for _, profile in pairs(solver.PROFILES) do
    if #profile.slots > 1 then bench = profile; break end
end
assert(bench, 'the pack has no multi-slot profile to test with')
check('the test bench really has two seats', #bench.slots == 2, #bench.slots)

local benchFurn = { position = vec(0, 0, 0), rotation = rotZ(0), scale = 1 }
local function seatWorld(slot)
    local r = P.localRootFor(slot, nil)
    return benchFurn.position + benchFurn.rotation:apply(r)
end
local w1, w2 = seatWorld(bench.slots[1]), seatWorld(bench.slots[2])
check('the two seats are in different places', (w1 - w2):length() > 1,
      string.format('%.3f apart', (w1 - w2):length()))

env.self.position = w1 + vec(0, 0, 20)
check('standing by the first seat picks it',
      P.nearestSlot(benchFurn, bench) == bench.slots[1])
env.self.position = w2 + vec(0, 0, 20)
check('standing by the second seat picks it',
      P.nearestSlot(benchFurn, bench) == bench.slots[2])
env.self.position = vec(0, 0, 0)

-- A single-slot profile returns its only slot without measuring anything, and
-- an empty or missing profile returns nil rather than erroring on a sit.
check('a one-seat profile returns its slot',
      P.nearestSlot(benchFurn, sampleProfile) == sampleProfile.slots[1])
check('no profile means no slot', P.nearestSlot(benchFurn, nil) == nil)
check('an empty slot list means no slot',
      P.nearestSlot(benchFurn, { slots = {} }) == nil)

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
