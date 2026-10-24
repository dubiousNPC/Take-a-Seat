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
-- the v0.37 overhead-escape stage is gone
-- ---------------------------------------------------------------------------
-- That stage moved the player off the authored seat point by up to 42 units in
-- whichever direction had headroom, which is what put the player high on the
-- table and away from the chair. With authored roots it has no job, and its
-- ring probes cost ~24 async casts per sit. Nothing of it may survive: a
-- leftover constant means someone wired it back in.
for _, name in ipairs({ 'OVERHEAD_CLEARANCE', 'OVERHEAD_RING_RADII',
                        'OVERHEAD_RING_COUNT', 'clearOverhead',
                        'overheadCandidates' }) do
    check('no trace of ' .. name, src:find(name, 1, true) == nil)
end

-- ---------------------------------------------------------------------------
-- authored placement is tried before any ray
-- ---------------------------------------------------------------------------
-- The pack is the primary positioner and the raycast the fallback, so beginSit
-- must consult the profile first and return without casting when it has one.
local begin = extract('(local function beginSit%(furniture.-\nend\n)', 'beginSit')
local profileAt = begin:find('seats%.solverProfile')
local rayAt     = begin:find('resolveChairPosition')
check('beginSit looks up an authored profile', profileAt ~= nil)
check('the authored lookup precedes the raycast chain',
      profileAt and rayAt and profileAt < rayAt,
      tostring(profileAt) .. ' vs ' .. tostring(rayAt))
check('the authored branch commits without falling through',
      begin:match('authoredPlacement.-\n%s*return\n') ~= nil)

-- ---------------------------------------------------------------------------
-- the authored yaw must bypass the global script's +pi flip
-- ---------------------------------------------------------------------------
-- The global seats the player at yaw + pi, because the raycast path passes the
-- furniture's own forward. authoredPlacement returns an ABSOLUTE world yaw
-- that already faces outward, so flipping it again would seat the player
-- backwards -- facing into the chair, under the table.
local globalSrc = io.open('scripts/take_a_seat/take_a_seat_global.lua'):read('a')
check('the global honours a yawAbsolute flag',
      globalSrc:find('eventData%.yawAbsolute and yaw or %(yaw %+ math%.pi%)') ~= nil)
check('the flag still flips when it is absent',
      globalSrc:find('yaw %+ math%.pi') ~= nil)
check('commitSit forwards the flag',
      src:find('yawAbsolute%s*= yawAbsolute and true or nil') ~= nil)
check('the authored path sets it',
      src:find('gateAndCommit%(furniture, nil, sitPos, worldYaw, true%)') ~= nil)
check('the raycast path does not',
      src:find('getObjectYaw%(furniture%), false%)') ~= nil)

-- Both placement paths go through the gate, and the gate is the only caller of
-- commitSit. A path that reached commitSit directly would skip the exit
-- validation and could seat the player somewhere they cannot get up from.
local commitCalls = 0
for line in src:gmatch('[^\n]+') do
    if line:find('commitSit%(') and not line:find('local function commitSit')
       and not line:match('^%s*%-%-') then
        commitCalls = commitCalls + 1
    end
end
check('commitSit has exactly one caller', commitCalls == 1, commitCalls)
check('that caller is the gate',
      src:find('local function gateAndCommit') ~= nil and
      src:match('local function gateAndCommit.-commitSit%(furniture, chairPos, sitPos, yaw, yawAbsolute%)') ~= nil)
check('the gate refuses before committing',
      src:match('safety%.sitRejectReason.-if reason then.-return false') ~= nil)

-- The authored path leaves the furniture alone, so there is nothing to put
-- back on stand-up. Restoring a chair that never moved teleports it onto
-- itself, which is a world write and a physics nudge for nothing.
check('the chair placement is only recorded when the chair may move',
      src:find('originalChairPos = chairPos and furniture%.position or nil') ~= nil)
check('the restore is sent only when a placement was recorded',
      src:find('if currentFurniture and originalChairPos then') ~= nil)

-- ---------------------------------------------------------------------------
-- stand-up: the gate's companion
-- ---------------------------------------------------------------------------
-- The exit teleport happens in the one-shot's completion callback, not during
-- the clip: a root that moves while the stand-up plays is what the animation
-- would be fighting. And it is ONE teleport, not a lerp -- lerping a player
-- through interior geometry is the stuck case the gate exists to prevent.
check('the stand-up point is committed from the exit clip callback',
      src:match("playOneShot%(exitGroup, 'exit', function%(%).-commitStandPoint") ~= nil)
check('controls are released after the teleport, not before',
      src:match('commitStandPoint%(furnitureRef%)%s*\n%s*releaseControls%(%)') ~= nil)
check('the stand-up sends exactly one teleport event',
      select(2, src:gsub('SitStandTeleport', '')) == 1)
check('the global handles it', globalSrc:find('SitStandTeleport%s*=') ~= nil)
check('the global teleports position only, leaving the facing alone',
      globalSrc:match('onSitStandTeleport.-player:teleport%(player%.cell, eventData%.position%)') ~= nil)

-- A cell change while seated invalidates the recorded origin: those
-- coordinates in a different cell are somewhere the player has never been.
check('the recorded origin is dropped on a cell change',
      src:find('if standingCell and self%.cell ~= standingCell then return nil end') ~= nil)
check('the floor height goes with it',
      src:find('origin and standingFloorZ or nil') ~= nil)

-- Standing up on a movement press is bound by NAME, and the names are taken
-- from the engine's own registry rather than typed in hopefully: a handler on
-- a key this build does not have would never fire and never complain.
check('stand-up actions are checked against input.actions',
      src:find('if input%.actions%[key%] then') ~= nil)
check('and what was bound is reported',
      src:find('%[sit%] stand up on movement') ~= nil)
check('a build without named actions still says so',
      src:find('no named input actions') ~= nil)
check('the sit-down transition is not interruptible by it',
      src:find('if isSitting and sitAnimStarted and actionPressed%(value%) then') ~= nil)

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
