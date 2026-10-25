-- The global script, driven directly: the sit teleport and the stand-up move.
--   python3 tools/luarun.py tools/test_standup.lua
--
-- The global script returns its handler table, so this loads the real file and
-- calls the real handlers rather than lifting fragments out of it. What is
-- being pinned:
--   * the sit teleport's two yaw conventions (authored vs raycast fallback);
--   * the stand-up move, which exists because the stand-up clip carries no
--     root motion -- without it the player stands in place and then snaps,
--     which is how it read in game;
--   * that the move lands exactly on the validated point, never past it;
--   * that onUpdate does nothing at all when no move is running, because it is
--     the only per-frame code in this mod.
local fails = 0
local function check(n, c, e)
    if c then print('  ok   ' .. n)
    else fails = fails + 1; print('  FAIL ' .. n .. '  ' .. tostring(e or '')) end
end

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

local teleports = {}        -- every player teleport, in order
local events = {}           -- events sent back to the player script
-- Declared before the constructor: inside it, `player` would be the global,
-- which is exactly the scoping mistake globalcheck now reports in shipped
-- code.
local player
player = {
    type = 'player', cell = 'cell-a',
    position = vec(0, 0, 0),
    isValid = function() return true end,
    sendEvent = function(_, name, data)
        events[#events + 1] = { name = name, data = data }
    end,
    teleport = function(self_, cell, pos, options)
        teleports[#teleports + 1] = { cell = cell, pos = pos, options = options }
        player.position = pos
    end,
}
local chairTeleports = {}
local chair = {
    recordId = 'chair', cell = 'cell-a', position = vec(50, 50, 0),
    rotation = 'chair-rot', isValid = function() return true end,
    teleport = function(_, cell, pos, opts)
        chairTeleports[#chairTeleports + 1] = { cell = cell, pos = pos, opts = opts }
    end,
}

package.preload['openmw.world'] = function() return {
    activeActors = { player } } end
package.preload['openmw.types'] = function() return { Player = 'player' } end
package.preload['openmw.util'] = function() return {
    vector3 = vec,
    transform = { rotateZ = function(a) return { yaw = a } end },
} end
package.path = './?.lua;' .. package.path

local M = dofile('scripts/take_a_seat/take_a_seat_global.lua')
check('the global script returns engine handlers',
      type(M.engineHandlers) == 'table')
check('and event handlers', type(M.eventHandlers) == 'table')
check('onUpdate is registered', type(M.engineHandlers.onUpdate) == 'function')

local H = M.eventHandlers
M.engineHandlers.onPlayerAdded(player)

-- ---------------------------------------------------------------------------
-- the sit teleport: two yaw conventions
-- ---------------------------------------------------------------------------
teleports = {}
H.SitTeleport({ position = vec(10, 20, 40), yaw = 1.0, yawAbsolute = true,
                furniture = chair })
check('an authored yaw is applied verbatim',
      #teleports == 1 and math.abs(teleports[1].options.rotation.yaw - 1.0) < 1e-9,
      #teleports > 0 and tostring(teleports[1].options.rotation.yaw))

teleports = {}
H.SitTeleport({ position = vec(10, 20, 40), yaw = 1.0, furniture = chair })
check('a fallback yaw gets the half turn',
      #teleports == 1
      and math.abs(teleports[1].options.rotation.yaw - (1.0 + math.pi)) < 1e-9,
      #teleports > 0 and tostring(teleports[1].options.rotation.yaw))

-- The furniture is only moved when the player script sends a position for it,
-- and only when that is an actual move: the authored path sends none.
chairTeleports, teleports = {}, {}
H.SitTeleport({ position = vec(10, 20, 40), yaw = 0, furniture = chair })
check('no furniture position means the furniture is not moved',
      #chairTeleports == 0)
H.SitTeleport({ position = vec(10, 20, 40), yaw = 0, furniture = chair,
                furniturePos = chair.position })
check('a furniture position equal to where it already is moves nothing',
      #chairTeleports == 0)
H.SitTeleport({ position = vec(10, 20, 40), yaw = 0, furniture = chair,
                furniturePos = chair.position + vec(30, 0, 0) })
check('a real furniture move is applied', #chairTeleports == 1)

-- ---------------------------------------------------------------------------
-- the stand-up move
-- ---------------------------------------------------------------------------
-- No `from`/`duration`: one teleport, which is what the seat keeper and a
-- blocked exit path both use.
teleports = {}
H.SitPlacePlayer({ position = vec(100, 0, 8) })
check('a bare place is a single teleport', #teleports == 1)
check('and it goes exactly there',
      teleports[1].pos.x == 100 and teleports[1].pos.z == 8)
check('the facing is left alone', teleports[1].options == nil)

teleports = {}
M.engineHandlers.onUpdate(0.1)
check('a bare place leaves no move running', #teleports == 0)

-- A glide: from, to and a duration.
local from, to = vec(0, 0, 40), vec(0, 48, 8)
teleports = {}
H.SitPlacePlayer({ position = to, from = from, duration = 0.4 })
check('arming a glide teleports nothing by itself', #teleports == 0)

M.engineHandlers.onUpdate(0.1)
check('the first tick moves the player', #teleports == 1)
local p1 = teleports[1].pos
check('it starts out of the seat, not at the destination',
      p1.y > from.y + 1 and p1.y < to.y - 1,
      string.format('%.2f', p1.y))
-- Ease-out: a quarter of the way through the clock covers more than a quarter
-- of the distance, which is what makes a short move read as a step rather
-- than a slide.
check('the easing front-loads the movement',
      (p1 - from):length() > (to - from):length() * 0.25,
      string.format('%.3f of %.3f', (p1 - from):length(), (to - from):length()))

for _ = 1, 2 do M.engineHandlers.onUpdate(0.1) end
local mid = teleports[#teleports].pos
check('it keeps moving while the clock runs', (mid - p1):length() > 1)
check('and never overshoots', (mid - from):length() <= (to - from):length() + 1e-6,
      string.format('%.3f', (mid - from):length()))

M.engineHandlers.onUpdate(0.2)      -- past the duration
local last = teleports[#teleports].pos
check('the last tick lands exactly on the validated point',
      (last - to):length() < 1e-9,
      string.format('%.2f,%.2f,%.2f', last.x, last.y, last.z))

local n = #teleports
M.engineHandlers.onUpdate(0.1)
check('the move stops itself', #teleports == n)
check('a whole glide costs a handful of teleports, not a stream',
      n <= 6, n)

-- A move interrupted by a new sit must not keep dragging the player out of the
-- seat they just took.
teleports = {}
H.SitPlacePlayer({ position = vec(0, 90, 8), from = vec(0, 0, 40), duration = 0.4 })
M.engineHandlers.onUpdate(0.1)
local during = #teleports
H.SitTeleport({ position = vec(10, 20, 40), yaw = 0, furniture = chair })
teleports = {}
M.engineHandlers.onUpdate(0.1)
check('a new sit cancels a glide in flight', during > 0 and #teleports == 0, #teleports)

-- A zero or negative duration is a snap, not a division by zero.
teleports = {}
H.SitPlacePlayer({ position = vec(5, 5, 5), from = vec(0, 0, 0), duration = 0 })
check('a zero duration snaps', #teleports == 1 and teleports[1].pos.x == 5)

-- ---------------------------------------------------------------------------
-- chair restore
-- ---------------------------------------------------------------------------
chairTeleports = {}
H.SitRestoreChair({ furniture = chair, position = chair.position,
                    rotation = chair.rotation })
check('the chair restore is applied', #chairTeleports == 1)
H.SitRestoreChair({ furniture = { isValid = function() return false end },
                    position = chair.position })
check('an invalid furniture ref is survived', #chairTeleports == 1)

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
