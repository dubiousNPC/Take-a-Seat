-- test_beds_sweep.lua -- every bed profile in the pack through the real placement
-- maths, at every 90-degree object yaw.
--   python3 tools/luarun.py tools/test_beds_sweep.lua
--
-- test_solver_profiles.lua checks the contract on a handful of representative
-- beds. This sweeps all 289 of them so a single bad row cannot hide behind a
-- passing sample, and it reuses the SAME lifted placement helpers rather than
-- a copy of the arithmetic.
--
-- Invariants asserted per slot, per yaw:
--   1. rotating the object preserves the sleeper's distance from the object
--      origin, and its height -- a yaw-dependent radius means the offset is
--      being applied in the wrong frame.
--   2. scale multiplies the authored root linearly.
--   3. a multi-slot bed keeps its slots apart at every yaw (the bounding-box
--      centre fault this path replaced put them on one point).
--   4. the world yaw is the object yaw plus the slot yaw, nothing negated and
--      nothing flipped by 180 a second time.
local fails, checks = 0, 0
local function bad(fmt, ...)
    fails = fails + 1
    if fails <= 12 then print('  FAIL ' .. string.format(fmt, ...)) end
end

package.preload['openmw.core'] = function() return {
    getGameTime = function() return 0 end, getSimulationTime = function() return 0 end,
    contentFiles = { list = {} } } end
package.preload['openmw.types'] = function() return {} end
package.preload['openmw.util'] = function() return {} end
package.preload['openmw.vfs'] = function() return { fileExists = function() return true end } end
package.path = './?.lua;' .. package.path

local solver = require('scripts.take_a_seat.solver_profiles')
local seats  = dofile('scripts/take_a_seat/sitAnim_shared.lua')

local src = io.open('scripts/take_a_seat/take_a_seat.lua'):read('a')
local body = src:match('(local function clampScale.-\nend\n)\n+local FACING_SCAN_RANGE')
assert(body, 'could not extract the placement helpers')

local V = {}
V.__index = V
local function vec(x, y, z) return setmetatable({ x = x, y = y, z = z }, V) end
V.__add = function(a, b) return vec(a.x + b.x, a.y + b.y, a.z + b.z) end
V.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end
function V:length() return math.sqrt(self.x^2 + self.y^2 + self.z^2) end

local function rotZ(yaw)
    return { apply = function(_, v)
        local c, s = math.cos(yaw), math.sin(yaw)
        return vec(v.x * c + v.y * s, -v.x * s + v.y * c, v.z)
    end }
end

local mathx = {}
for k, v in pairs(math) do mathx[k] = v end
mathx.atan2 = mathx.atan2 or math.atan

local SCALE_MIN = tonumber(src:match('local SCALE_MIN, SCALE_MAX = ([%d%.]+)'))
local SCALE_MAX = tonumber(src:match('local SCALE_MIN, SCALE_MAX = [%d%.]+, ([%d%.]+)'))

local env = {
    SCALE_MIN = SCALE_MIN, SCALE_MAX = SCALE_MAX,
    util = { vector3 = vec, transform = { rotateZ = rotZ } },
    math = mathx, type = type, ipairs = ipairs, pairs = pairs,
    setmetatable = setmetatable, tostring = tostring,
    seats = seats,
    self = { position = vec(0, 0, 0) },
    getSeatType = seats.getSeatType,
    resolveSitAnim = seats.animForSeat,
    recordModelOf = function(obj) return obj and obj.model or nil end,
}
local chunk = load(body .. [[
return { authoredPlacement = authoredPlacement, localRootFor = localRootFor,
         nearestSlot = nearestSlot }
]], 'place', 't', setmetatable(env, { __index = _G }))
local P = chunk()
env.getObjectYaw = function(obj)
    local f = obj.rotation:apply(vec(0, 1, 0))
    return mathx.atan2(f.x, f.y)
end

local YAWS = { 0, math.pi / 2, math.pi, 3 * math.pi / 2 }
local EPS  = 1e-3

local beds, slots, multi = 0, 0, 0
local minSep, minSepKey = math.huge, nil

for key, profile in pairs(solver.PROFILES) do
    if profile.kind == 'sleep' then
        beds = beds + 1
        local origin = vec(250, -175, 40)
        for _, slot in ipairs(profile.slots) do
            slots = slots + 1
            local localLen = math.sqrt(slot.root[1]^2 + slot.root[2]^2)
            local refZ
            for _, yaw in ipairs(YAWS) do
                local furn = { position = origin, rotation = rotZ(yaw), scale = 1,
                               recordId = 'sweep', model = key }
                local pos, worldYaw = P.authoredPlacement(furn, slot, nil)
                local rel = pos - origin
                checks = checks + 1

                -- 1. frame invariance
                local radius = math.sqrt(rel.x^2 + rel.y^2)
                if math.abs(radius - localLen) > EPS then
                    bad('%s/%s yaw=%.0f radius %.4f, authored %.4f',
                        key, slot.id, math.deg(yaw), radius, localLen)
                end
                refZ = refZ or rel.z
                if math.abs(rel.z - refZ) > EPS then
                    bad('%s/%s yaw=%.0f height drifted %.4f -> %.4f',
                        key, slot.id, math.deg(yaw), refZ, rel.z)
                end

                -- 4. yaw composition: object yaw + slot yaw + the bed type's
                -- pose correction (BED_POSE_YAW; the pack's yaw faces slee8)
                local want = yaw + math.rad(slot.yaw)
                             + math.rad(seats.bedPoseYaw(seats.bedTypeForModel(key)))
                local got, diff = worldYaw, nil
                diff = math.abs((got - want) % (2 * math.pi))
                if diff > math.pi then diff = 2 * math.pi - diff end
                if diff > 1e-6 then
                    bad('%s/%s yaw=%.0f world yaw %.4f, expected %.4f',
                        key, slot.id, math.deg(yaw), got, want)
                end

                -- 2. scale linearity
                local big = { position = origin, rotation = rotZ(yaw), scale = 2,
                              recordId = 'sweep', model = key }
                local bpos = select(1, P.authoredPlacement(big, slot, nil))
                local brel = bpos - origin
                if (brel - vec(rel.x * 2, rel.y * 2, rel.z * 2)):length() > EPS then
                    bad('%s/%s yaw=%.0f scale 2 is not linear', key, slot.id, math.deg(yaw))
                end
            end
        end

        -- 3. multi-slot separation at every yaw
        if #profile.slots > 1 then
            multi = multi + 1
            for _, yaw in ipairs(YAWS) do
                local furn = { position = origin, rotation = rotZ(yaw), scale = 1,
                               recordId = 'sweep', model = key }
                local a = select(1, P.authoredPlacement(furn, profile.slots[1], nil))
                local b = select(1, P.authoredPlacement(furn, profile.slots[2], nil))
                local sep = (a - b):length()
                checks = checks + 1
                if sep < minSep then minSep, minSepKey = sep, key .. ' @' .. math.deg(yaw) end
                if sep < 10 then
                    bad('%s slots only %.2f apart at yaw %.0f', key, sep, math.deg(yaw))
                end
            end
        end
    end
end

print(string.format('swept %d bed profiles, %d slots (%d multi-slot), %d assertions',
                    beds, slots, multi, checks))
print(string.format('closest two slots on any bed at any yaw: %.2f units (%s)',
                    minSep, tostring(minSepKey)))
print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
