-- Targeting and overhead clearance: the two reported bugs, pinned.
--   python3 tools/luarun.py tools/test_targeting.lua
--
-- 1. Looking at an NPC must not sit the player down. The furniture search
--    PIERCES anything that is not sittable, so a ray went through a seated NPC
--    and returned the chair underneath -- activating the NPC sat you on it, and
--    the NPC could never be talked to.
-- 2. A chair tucked under a table left the player's standing-height collision
--    capsule inside the table top, and the engine resolved that by pushing the
--    player up: knees above the table.
local fails = 0
local function check(n, c, e)
    if c then print('  ok   ' .. n)
    else fails = fails + 1; print('  FAIL ' .. n .. '  ' .. tostring(e or '')) end
end

local src = io.open('scripts/take_a_seat/take_a_seat.lua'):read('a')
local function extract(pattern, label)
    local body = src:match(pattern)
    assert(body, 'could not extract ' .. label)
    return body
end

-- ---------------------------------------------------------------------------
-- castPiercing: an actor ends the column instead of being pierced
-- ---------------------------------------------------------------------------
-- castPiercing does real vector arithmetic (to - current, dir / len,
-- :length()), so the mock needs real vectors, not stand-ins. The scene is one
-- line along +y and a hit list keyed by distance from the origin.
local V = {}
V.__index = V
local function vec(x, y, z) return setmetatable({ x = x, y = y, z = z }, V) end
V.__add = function(a, b) return vec(a.x + b.x, a.y + b.y, a.z + b.z) end
V.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end
V.__div = function(a, k) return vec(a.x / k, a.y / k, a.z / k) end
V.__mul = function(a, k)
    if type(a) == 'number' then a, k = k, a end
    return vec(a.x * k, a.y * k, a.z * k)
end
function V:length() return math.sqrt(self.x^2 + self.y^2 + self.z^2) end

local world = { hits = {} }      -- { d = distance along +y, obj = ... }
local casts = 0

local env = {
    nearby = { asyncCastRenderingRay = function(cb, from, to)
        casts = casts + 1
        local nextHit = nil
        for _, h in ipairs(world.hits) do
            if h.d > from.y + 0.0001 and (not nextHit or h.d < nextHit.d) then
                nextHit = h
            end
        end
        if not nextHit or nextHit.d > to.y then return cb({ hit = false }) end
        cb({ hit = true, hitObject = nextHit.obj, hitPos = vec(0, nextHit.d, 0) })
    end },
    async = { callback = function(_, f) return f end },
    util = { vector3 = vec },
    math = math, ipairs = ipairs, pairs = pairs, print = print, tostring = tostring,
    type = type, table = table, setmetatable = setmetatable,
}
env.types = {
    NPC = { objectIsInstance = function(o) return o and o.kind == 'npc' end },
    Creature = { objectIsInstance = function(o) return o and o.kind == 'creature' end },
}

local piercing = extract('(local function castPiercing%(from, to, maxPierces, onHit, done%).-\nend\n)',
                         'castPiercing')
local actorFn = extract('(local function isActorObject%(obj%).-\nend\n)', 'isActorObject')
local chunk = load(actorFn .. piercing ..
    '\nreturn castPiercing, isActorObject', 'pierce', 't',
    setmetatable(env, { __index = _G }))
local castPiercing, isActorObject = chunk()

check('an NPC object is recognised as an actor',
      isActorObject({ kind = 'npc', recordId = 'guard' }) == true)
check('a creature is recognised as an actor',
      isActorObject({ kind = 'creature', recordId = 'rat' }) == true)
check('a chair is not an actor',
      isActorObject({ kind = 'static', recordId = 'furn_com_r_chair_01' }) == false)
check('nil is not an actor', isActorObject(nil) == false)

-- The filter the mod uses, lifted to the test so its semantics are checked.
local function filter(res)
    if isActorObject(res.hitObject) then return 'stop' end
    local o = res.hitObject
    return o ~= nil and o.sittable == true
end

-- An NPC in front of the chair: the column must stop at the NPC.
world.hits = {
    { d = 10, obj = { kind = 'npc', recordId = 'guard' } },
    { d = 40, obj = { kind = 'static', recordId = 'chair', sittable = true } },
}
local got = 'unset'
castPiercing(vec(0, 0, 0), vec(0, 200, 0), 4, filter, function(res) got = res end)
check('a ray through an NPC finds no furniture behind them', got == nil, tostring(got))

-- Same scene without the NPC: the chair is still found, so the stop is not a
-- blanket refusal to look through anything.
world.hits = { { d = 40, obj = { kind = 'static', recordId = 'chair', sittable = true } } }
got = 'unset'
castPiercing(vec(0, 0, 0), vec(0, 200, 0), 4, filter, function(res) got = res end)
check('the same chair is found with the NPC gone',
      type(got) == 'table' and got.hitObject.recordId == 'chair')

-- A non-sittable, non-actor obstruction is still pierced.
world.hits = {
    { d = 10, obj = { kind = 'static', recordId = 'rug' } },
    { d = 40, obj = { kind = 'static', recordId = 'chair', sittable = true } },
}
got = 'unset'
castPiercing(vec(0, 0, 0), vec(0, 200, 0), 4, filter, function(res) got = res end)
check('clutter is still pierced', type(got) == 'table' and got.hitObject.recordId == 'chair')

-- ---------------------------------------------------------------------------
-- seatOccupied
-- ---------------------------------------------------------------------------
-- The constants come from the module itself, so the test cannot drift from the
-- radius the mod actually uses.
local occEnv = {
    self = { id = 'player' },
    nearby = { actors = {} },
    math = math, ipairs = ipairs,
    SEAT_OCCUPIED_RADIUS = tonumber(src:match('SEAT_OCCUPIED_RADIUS%s*=%s*(%d+)')),
    SEAT_OCCUPIED_Z      = tonumber(src:match('SEAT_OCCUPIED_Z%s*=%s*(%d+)')),
}
assert(occEnv.SEAT_OCCUPIED_RADIUS and occEnv.SEAT_OCCUPIED_Z,
       'could not read the occupancy constants out of the module')
local occBody = extract('(local function seatOccupied%(furniture%).-\nend\n)', 'seatOccupied')
local seatOccupied = load(occBody .. '\nreturn seatOccupied', 'occ', 't',
                          setmetatable(occEnv, { __index = _G }))()
local chair = { position = { x = 100, y = 100, z = 0 } }
local function actorAt(id, x, y, z)
    return { id = id, isValid = function() return true end,
             position = { x = x, y = y, z = z } }
end

occEnv.nearby.actors = {}
check('an empty room leaves the seat free', seatOccupied(chair) == false)

occEnv.nearby.actors = { actorAt('npc', 105, 98, 0) }
check('an NPC on the seat marks it taken', seatOccupied(chair) == true)

occEnv.nearby.actors = { actorAt('npc', 200, 100, 0) }
check('an NPC across the room does not', seatOccupied(chair) == false)

occEnv.nearby.actors = { actorAt('npc', 100, 100, 400) }
check('an NPC on the floor above does not', seatOccupied(chair) == false)

occEnv.nearby.actors = { actorAt('player', 100, 100, 0) }
check('the player does not block their own seat', seatOccupied(chair) == false)

-- ---------------------------------------------------------------------------
-- overheadCandidates ordering
-- ---------------------------------------------------------------------------
local candEnv = { math = math, ipairs = ipairs, table = table,
                  OVERHEAD_RING_RADII = { 18, 30, 42 }, OVERHEAD_RING_COUNT = 8 }
local candBody = extract('(local function overheadCandidates%(backYaw%).-\n    return out\nend\n)',
                         'overheadCandidates')
local overheadCandidates = load(candBody .. '\nreturn overheadCandidates', 'cand', 't',
                                setmetatable(candEnv, { __index = _G }))()

local cands = overheadCandidates(0)       -- prefer +y ("back" is north here)
check('every ring position is offered', #cands == 3 * 8, #cands)

local radii = {}
for _, c in ipairs(cands) do radii[#radii + 1] = c.r end
local ascending = true
for i = 2, #radii do if radii[i] < radii[i - 1] then ascending = false end end
check('nearer rings are tried first', ascending, table.concat(radii, ','))

-- The first candidate must be straight back: moving the player out from under
-- the table, not further under it.
check('the first candidate is straight back',
      math.abs(cands[1].dx) < 0.001 and math.abs(cands[1].dy - 18) < 0.001,
      string.format('%.2f,%.2f', cands[1].dx, cands[1].dy))

-- Nothing in the first ring may point forward (toward the table) before the
-- sideways directions have been tried.
local firstRing = {}
for _, c in ipairs(cands) do if c.r == 18 then firstRing[#firstRing + 1] = c end end
check('the forward direction is tried last in a ring',
      math.abs(firstRing[#firstRing].dy + 18) < 0.001,
      string.format('%.2f', firstRing[#firstRing].dy))

-- A rotated chair keeps the same relationship.
local rotated = overheadCandidates(math.pi / 2)   -- back is +x
check('the preference follows the chair yaw',
      math.abs(rotated[1].dx - 18) < 0.001 and math.abs(rotated[1].dy) < 0.001,
      string.format('%.2f,%.2f', rotated[1].dx, rotated[1].dy))

-- ---------------------------------------------------------------------------
-- the clearance must cover a standing capsule
-- ---------------------------------------------------------------------------
local clearance = tonumber(src:match('OVERHEAD_CLEARANCE%s*=%s*(%d+)'))
check('overhead clearance is at least a standing actor tall',
      clearance and clearance >= 100, tostring(clearance))
-- The seated player's facing is the global script's rotation, not the chair's
-- forward. If these two drift apart the escape pushes the player UNDER the
-- table instead of out from it, which looks exactly like the bug it fixes.
local globalSrc = io.open('scripts/take_a_seat/take_a_seat_global.lua'):read('a')
check('the global script seats the player at yaw + pi',
      globalSrc:find('rotateZ%(yaw %+ math%.pi%)') ~= nil)
check('the escape direction is derived from that same facing',
      src:find('local facingYaw = yaw %+ math%.pi') ~= nil and
      src:find('clearOverhead%(sitPos, furniture, facingYaw') ~= nil)
check('the escape prefers the opposite of the facing',
      src:find('overheadCandidates%(facingYaw %+ math%.pi%)') ~= nil)

check('the escape is applied before the sit is committed',
      src:find('commitSit%(furniture, chairPos, sitPos %+ escape, yaw%)') ~= nil)

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
