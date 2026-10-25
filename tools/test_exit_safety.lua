-- The gate and the stand-up point: seat_safety.lua against a scripted world.
--   python3 tools/luarun.py tools/test_exit_safety.lua
--
-- These are the two things stages 4 and 5 are for:
--   * a sit is refused while the player is still standing somewhere safe,
--     rather than committed and coped with;
--   * standing up puts the player on a point that was checked first.
-- Both are decided by arithmetic over ray and navmesh answers, so both can be
-- driven here with a world that says exactly what a cramped interior,
-- a stairwell and a knocked-over chair would say.
local fails = 0
local function check(n, c, e)
    if c then print('  ok   ' .. n)
    else fails = fails + 1; print('  FAIL ' .. n .. '  ' .. tostring(e or '')) end
end

package.path = './?.lua;' .. package.path
local safety = dofile('scripts/take_a_seat/seat_safety.lua')

-- ---------------------------------------------------------------------------
-- a world that answers rays and navmesh queries
-- ---------------------------------------------------------------------------
-- Real vector arithmetic: the module adds, subtracts, scales and measures
-- these, so stand-ins would prove nothing.
local V = {}
V.__index = V
local function vec(x, y, z) return setmetatable({ x = x, y = y, z = z }, V) end
V.__add = function(a, b) return vec(a.x + b.x, a.y + b.y, a.z + b.z) end
V.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end
V.__mul = function(a, k)
    if type(a) == 'number' then a, k = k, a end
    return vec(a.x * k, a.y * k, a.z * k)
end
function V:length() return math.sqrt(self.x^2 + self.y^2 + self.z^2) end

local world = {
    floorZ = 0,            -- height of the floor, or nil for a hole
    navOffset = nil,       -- what findNearestNavMeshPosition shifts a point by
    navNowhere = false,    -- navmesh returns nothing
    rays = 0, navQueries = 0,
    holes = {},            -- {x=,y=} points with no floor
}

local function isHole(p)
    for _, h in ipairs(world.holes) do
        if math.abs(p.x - h.x) < 1 and math.abs(p.y - h.y) < 1 then return true end
    end
    return false
end

local env = {
    util = {
        vector3 = vec,
        bitOr = function(a, b) return a + b end,   -- the stub values are disjoint
    },
    nearby = {
        COLLISION_TYPE = { World = 1, Door = 2, HeightMap = 4, Actor = 8 },
        castRay = function(from, to, _options)
            world.rays = world.rays + 1
            -- A downward ray is a ground probe and finds the floor; a
            -- level one is a path probe and finds only a wall, if there
            -- is one. Modelling both matters: pathClear and groundBelow
            -- ask the same function different questions.
            if math.abs(to.z - from.z) < math.abs(to.y - from.y)
               + math.abs(to.x - from.x) then
                if world.wall then
                    return { hit = true, hitPos = vec(from.x, from.y, from.z) }
                end
                return { hit = false }
            end
            if world.floorZ == nil or isHole(from) then return { hit = false } end
            return { hit = true, hitPos = vec(from.x, from.y, world.floorZ),
                     hitNormal = vec(0, 0, 1) }
        end,
        findNearestNavMeshPosition = function(pos, options)
            world.navQueries = world.navQueries + 1
            world.lastNavOptions = options
            if world.navNowhere then return nil end
            if world.navOffset then return pos + world.navOffset end
            return pos
        end,
    },
}

local function furniture(upZ)
    -- rotation:apply is only ever asked for world up here.
    return { recordId = 'chair', rotation = { apply = function(_, _v)
        return vec(0, math.sqrt(math.max(0, 1 - upZ * upZ)), upZ)
    end } }
end

local function reset()
    world.floorZ, world.navOffset, world.navNowhere = 0, nil, false
    world.wall = false
    world.holes, world.rays, world.navQueries = {}, 0, 0
end

-- ---------------------------------------------------------------------------
-- tipped furniture
-- ---------------------------------------------------------------------------
-- A knocked-over chair is still a chair record, still sittable, and the player
-- path had no test for it at all -- it would happily seat you on a chair lying
-- on its side.
reset()
check('an upright chair is upright', (safety.isUpright(env, furniture(1.0))) == true)
check('a chair tipped 30 degrees still counts',
      (safety.isUpright(env, furniture(0.87))) == true)
check('a chair on its side does not',
      (safety.isUpright(env, furniture(0.2))) == false)
check('the threshold is the documented 0.7', safety.UP_Z_MIN == 0.7)

local seat = vec(100, 100, 40)
local origin = vec(100, 60, 0)

reset()
local reason = safety.sitRejectReason(env, furniture(0.3), seat, 0, origin, 0)
check('a tipped chair is refused', reason ~= nil and reason:find('tipped') ~= nil,
      tostring(reason))
check('a tipped chair is refused without casting a single ray', world.rays == 0,
      world.rays)

-- ---------------------------------------------------------------------------
-- the ordinary case
-- ---------------------------------------------------------------------------
reset()
local ok, exit, what = safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
check('an ordinary sit is allowed', ok == nil, tostring(ok))
check('it picks the recorded origin', what == 'recorded origin', tostring(what))
check('the exit is the origin, lifted clear of the floor',
      exit and math.abs(exit.x - origin.x) < 0.01
          and math.abs(exit.z - (0 + safety.EXIT_LIFT)) < 0.01,
      exit and string.format('%.2f,%.2f,%.2f', exit.x, exit.y, exit.z))
check('the whole gate costs a handful of synchronous probes',
      world.rays <= 2 and world.navQueries <= 2,
      string.format('%d ray(s), %d navmesh query(s)', world.rays, world.navQueries))

-- The navmesh asked about has to be the player's own: a point something
-- smaller can stand on says nothing about the player. The API documents no
-- default for agentBounds, so it is passed explicitly.
reset()
env.agentBounds = function() return { shapeType = 0, halfExtents = vec(23, 23, 64) } end
safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
check('the navmesh query names the player agent bounds',
      world.lastNavOptions ~= nil and world.lastNavOptions.agentBounds ~= nil
      and world.lastNavOptions.agentBounds.halfExtents.z == 64,
      world.lastNavOptions and tostring(world.lastNavOptions.agentBounds))
check('and a search box, not the whole active grid',
      world.lastNavOptions.searchAreaHalfExtents ~= nil
      and world.lastNavOptions.searchAreaHalfExtents.x == safety.NAV_SEARCH_EXTENT)
env.agentBounds = nil
reset()
safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
check('no agent bounds provided is not a crash',
      world.lastNavOptions ~= nil and world.lastNavOptions.agentBounds == nil)

-- ---------------------------------------------------------------------------
-- the stairwell case
-- ---------------------------------------------------------------------------
-- The floor the ray finds is 120 units below the one the player walked in on:
-- that is the storey below, not the room they are in. The old code had no
-- notion of this; the tolerance is the 35 the Procedural Chatter seating uses.
reset()
world.floorZ = -120
local r2 = safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
check('a candidate on the storey below is refused',
      r2 ~= nil and r2:find('different storey') ~= nil, tostring(r2))

-- Same drop, but that IS the floor the player came from: allowed.
reset()
world.floorZ = -120
local r3, exit3 = safety.sitRejectReason(env, furniture(1), seat, 0, origin, -120)
check('the same drop is fine when it is the floor they came from',
      r3 == nil and exit3 ~= nil, tostring(r3))

-- ---------------------------------------------------------------------------
-- the cramped interior
-- ---------------------------------------------------------------------------
-- Nothing is on the navmesh anywhere near: no route out, so no sit. This is
-- the case the whole stage exists for -- refused while the player is still
-- standing, instead of teleported in and stuck.
-- A navmesh with nothing in it anywhere is a build or cell problem, not a
-- reason to stop the player sitting down: the recorded origin is where they
-- were standing a moment ago, so it stands on its own evidence.
reset()
world.navNowhere = true
local r4, exit4, what4 = safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
check('no navmesh anywhere still allows the recorded origin',
      r4 == nil and what4 == 'recorded origin', tostring(r4) .. '/' .. tostring(what4))
check('and the origin is used as the ground ray found it',
      exit4 ~= nil and math.abs(exit4.z - safety.EXIT_LIFT) < 0.01)

-- With no origin to fall back on, every remaining candidate is one this module
-- invented, and for those the navmesh is the whole proof. This is the cramped
-- interior the stage exists for: refused while the player is still standing.
reset()
world.navNowhere = true
local r4b = safety.sitRejectReason(env, furniture(1), seat, 0, nil, 0)
check('a seat with no route out and no origin is refused',
      r4b ~= nil and r4b:find('no validated way back out') ~= nil, tostring(r4b))
check('the refusal names what it tried',
      r4b ~= nil and r4b:find('forward of the seat') ~= nil
                 and r4b:find('the seat itself') ~= nil, tostring(r4b))

-- A navmesh point too far from the asked-for position is not an answer about
-- that position: findNearestNavMeshPosition searches a whole box and will
-- gladly return somewhere across the room.
reset()
world.navOffset = vec(300, 0, 0)
local r5 = safety.sitRejectReason(env, furniture(1), seat, 0, nil, 0)
check('a navmesh point across the room does not count',
      r5 ~= nil and r5:find('not on the navmesh') ~= nil, tostring(r5))

-- No floor at all under anything: refused.
reset()
world.floorZ = nil
local r6 = safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
check('a seat over a hole is refused',
      r6 ~= nil and r6:find('no floor under it') ~= nil, tostring(r6))

-- ---------------------------------------------------------------------------
-- candidate order and fallback
-- ---------------------------------------------------------------------------
-- The origin is unusable (someone closed a trapdoor under it), so the next
-- candidate is forward of the seated facing -- out of the chair, not into its
-- back.
reset()
world.holes = { { x = origin.x, y = origin.y } }
local r7, exit7, what7 = safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
check('an unusable origin falls through to the next candidate',
      r7 == nil and what7 == 'forward of the seat', tostring(r7) .. '/' .. tostring(what7))
check('forward of the seat is in front of it, by the documented distance',
      exit7 and math.abs(exit7.y - (seat.y + safety.EXIT_FORWARD)) < 0.01
            and math.abs(exit7.x - seat.x) < 0.01,
      exit7 and string.format('%.2f,%.2f', exit7.x, exit7.y))

-- Facing matters: at a quarter turn, "forward" is +x. The seated facing is the
-- yaw the mod hands the engine, so sin/cos here must match the convention
-- used for placement (rotateZ(yaw) applied to +y).
reset()
world.holes = { { x = origin.x, y = origin.y } }
local _, exit8 = safety.sitRejectReason(env, furniture(1), seat, math.pi / 2, origin, 0)
check('the exit direction follows the seated facing',
      exit8 and math.abs(exit8.x - (seat.x + safety.EXIT_FORWARD)) < 0.01
            and math.abs(exit8.y - seat.y) < 0.01,
      exit8 and string.format('%.2f,%.2f', exit8.x, exit8.y))

-- With no origin recorded at all (a load while seated, say), stand-up still
-- has candidates.
reset()
local p9, w9 = safety.chooseStandPoint(env, seat, 0, nil, nil, nil)
check('stand-up works with no recorded origin', p9 ~= nil, tostring(w9))

-- The last resort is the seat itself, which is where the player already is --
-- so a validated "do nothing much" rather than a teleport to an unchecked
-- point.
reset()
world.holes = { { x = origin.x, y = origin.y },
                { x = seat.x, y = seat.y + safety.EXIT_FORWARD } }
local p10, w10 = safety.chooseStandPoint(env, seat, 0, origin, nil, 0)
check('the seat itself is the last resort',
      p10 ~= nil and w10 == 'the seat itself', tostring(w10))

-- ---------------------------------------------------------------------------
-- an older build with no navmesh query
-- ---------------------------------------------------------------------------
-- Sitting must not become impossible on a build whose nearby has no
-- findNearestNavMeshPosition: the gate degrades to the ground ray.
reset()
local saved = env.nearby.findNearestNavMeshPosition
env.nearby.findNearestNavMeshPosition = nil
local r11, exit11 = safety.sitRejectReason(env, furniture(1), seat, 0, origin, 0)
env.nearby.findNearestNavMeshPosition = saved
check('no navmesh query means the ground ray decides, not a refusal',
      r11 == nil and exit11 ~= nil, tostring(r11))

-- ---------------------------------------------------------------------------
-- the glide path
-- ---------------------------------------------------------------------------
-- Only asked when collision is ON during the stand-up move: with collision off
-- nothing can obstruct the player, and with it on a glide through a closed
-- door is worse than the snap it replaces.
reset()
world.floorZ = 0
check('a clear line is clear',
      safety.pathClear(env, vec(0, 0, 40), vec(0, 48, 8), 40, nil) == true)

-- A wall between the two: the ray at torso height hits, so the glide is
-- refused and the caller snaps instead.
reset()
world.wall = true
check('a blocked line is not',
      safety.pathClear(env, vec(0, 0, 40), vec(0, 48, 8), 40, nil) == false)
check('the probe is one ray', world.rays == 1, world.rays)

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
