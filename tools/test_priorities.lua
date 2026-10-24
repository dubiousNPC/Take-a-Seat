-- Animation priority profiles and exit-clip wiring.
--   python3 tools/luarun.py tools/test_priorities.lua
--
-- The rule being pinned: a transition outranks the seated idle ON THE LEGS,
-- and the seated idle sits LOW on the upper body so hit reactions, weapons and
-- other mods' conversation gestures can take the torso and arms.
local fails = 0
local function check(n, c, e)
    if c then print('  ok   ' .. n)
    else fails = fails + 1; print('  FAIL ' .. n .. '  ' .. tostring(e or '')) end
end

-- openmw.animation's real tiers, in order. The numbers are what the engine
-- compares, so the test can assert "higher" rather than just "different".
local P = { Default = 0, WeaponLowerBody = 1, SneakIdleLowerBody = 2, SwimIdle = 3,
            Jump = 4, Movement = 5, Hit = 6, Weapon = 7, Block = 8, Knockdown = 9,
            Torch = 10, Storm = 11, Death = 12, Scripted = 13 }
local BG = { LowerBody = 1, Torso = 2, LeftArm = 3, RightArm = 4 }
local B  = { LowerBody = 1, Torso = 2, LeftArm = 4, RightArm = 8, UpperBody = 14, All = 15 }

package.preload['openmw.core'] = function() return {
    getGameTime = function() return 0 end, getSimulationTime = function() return 0 end,
    contentFiles = { list = {} } } end
package.preload['openmw.types'] = function() return {} end
package.preload['openmw.util'] = function() return {} end
package.preload['openmw.vfs'] = function() return { fileExists = function() return true end } end
package.path = './?.lua;' .. package.path

local seats = dofile('scripts/take_a_seat/sitAnim_shared.lua')
local profiles = seats.buildAnimProfiles({ PRIORITY = P, BLEND_MASK = B, BONE_GROUP = BG })

local seat = profiles[seats.TARGET_KIND.SEAT]
check('a seat profile exists', type(seat) == 'table')

-- every phase names all four bone groups ------------------------------------
-- A bone group left out of a priority table silently defaults to Default,
-- which for the legs means locomotion wins and the pose is lost.
for _, phase in ipairs({ 'idle', 'enter', 'exit' }) do
    local pr = seat[phase].priority
    check(phase .. ' priority is a per-bone-group table', type(pr) == 'table', type(pr))
    if type(pr) == 'table' then
        local missing = {}
        for name, g in pairs(BG) do
            if pr[g] == nil then missing[#missing + 1] = name end
        end
        check(phase .. ' names all four bone groups', #missing == 0, table.concat(missing, ','))
    end
end

-- Read a bone group's priority whether the profile uses a table or a single
-- value, so a profile that is still one flat number fails the checks below
-- with a real comparison instead of crashing on an index.
local function prio(p, g)
    if type(p) == 'table' then return p[g] end
    return p
end

local idleP, enterP, exitP = seat.idle.priority, seat.enter.priority, seat.exit.priority
local idle  = setmetatable({}, { __index = function(_, g) return prio(idleP, g) end })
local enter = setmetatable({}, { __index = function(_, g) return prio(enterP, g) end })
local exit  = setmetatable({}, { __index = function(_, g) return prio(exitP, g) end })

-- the legs hold the pose ----------------------------------------------------
check('idle legs outrank Movement, Jump and Hit',
      idle[BG.LowerBody] > P.Movement and idle[BG.LowerBody] > P.Jump
      and idle[BG.LowerBody] > P.Hit, idle[BG.LowerBody])

-- the upper body yields -----------------------------------------------------
check('idle upper body is below the legs',
      idle[BG.Torso] < idle[BG.LowerBody], idle[BG.Torso])
check('idle upper body yields to a weapon, a hit and a torch',
      idle[BG.Torso] < P.Hit and idle[BG.Torso] < P.Weapon and idle[BG.Torso] < P.Torch,
      idle[BG.Torso])
check('idle upper body still outranks vanilla idle (Default)',
      idle[BG.Torso] > P.Default, idle[BG.Torso])
check('both arms match the torso',
      idle[BG.LeftArm] == idle[BG.Torso] and idle[BG.RightArm] == idle[BG.Torso])
-- Procedural Chatter poses seated NPCs at Movement and plays gestures above
-- that on bone mask 14. A seated player must leave the same room.
check('idle upper body does not outrank a Procedural Chatter gesture',
      idle[BG.Torso] <= P.Movement, idle[BG.Torso])

-- transitions beat the idle on the legs -------------------------------------
check('enter legs outrank idle legs', enter[BG.LowerBody] > idle[BG.LowerBody],
      enter[BG.LowerBody])
check('exit legs outrank idle legs', exit[BG.LowerBody] > idle[BG.LowerBody],
      exit[BG.LowerBody])
check('transition legs outrank locomotion', exit[BG.LowerBody] > P.Movement)

-- Scripted pauses every other animation on the actor, including the gestures
-- the idle split exists to allow. It must not appear in a seat profile.
for _, phase in ipairs({ 'idle', 'enter', 'exit' }) do
    local pr = seat[phase].priority
    local scripted = false
    for _, g in pairs(BG) do if prio(pr, g) == P.Scripted then scripted = true end end
    check(phase .. ' avoids PRIORITY.Scripted', not scripted)
end

-- misc keeps its lower-body-only mask ---------------------------------------
local misc = profiles[seats.TARGET_KIND.MISC]
check('misc idle still masks the upper body out', misc.idle.blendMask == B.LowerBody)

-- exit clips are wired ------------------------------------------------------
-- These groups ship in xdbsgetup01.kf and xdbsRAsitting1.kf on all four
-- skeletons; before this they were commented out and never played.
-- Groups that exist in the shipped .kf files and are legitimate exits.
-- tassitu1/2 are the purpose-built chair stand-ups; rasitup1 belongs to the RA
-- (floor) set; getup1/2 still ship in xdbsWakeUp*.kf.
local SHIPPED_EXITS = { tassitu1 = true, tassitu2 = true,
                        rasitup1 = true, getup1 = true, getup2 = true }
local missing, wrong = {}, {}
for name, seatType in pairs(seats.SEAT_TYPE) do
    local group = seats.exitAnimFor(seats.TARGET_KIND.SEAT, seatType)
    if not group then missing[#missing + 1] = name
    elseif not SHIPPED_EXITS[group] then wrong[#wrong + 1] = name .. '=' .. group end
end
check('every seat type has an exit clip', #missing == 0, table.concat(missing, ','))
check('every exit clip is one that ships', #wrong == 0, table.concat(wrong, ','))
check('the cushion exits with the RA set clip it was posed from',
      seats.exitAnimFor(seats.TARGET_KIND.SEAT, seats.SEAT_TYPE.CUSHION) == 'rasitup1')

-- Sit-down clips ship for chairs (xdbsTASsitT*.kf: tassitd*) and for floor
-- seating (xdbsRAsit2T.kf: rasitd*). Every seat type is wired now, including
-- CUSHION and BATH, which take the RA-set clips.
local SHIPPED_ENTERS = { tassitd1 = true, tassitd2 = true,
                         rasitd1 = true, rasitd2 = true }
local missingEnter, wrongEnter = {}, {}
for name, seatType in pairs(seats.SEAT_TYPE) do
    local group = seats.enterAnimFor(seats.TARGET_KIND.SEAT, seatType)
    if not group then missingEnter[#missingEnter + 1] = name
    elseif not SHIPPED_ENTERS[group] then
        wrongEnter[#wrongEnter + 1] = name .. '=' .. group
    end
end
check('every seat type has a sit-down clip', #missingEnter == 0,
      table.concat(missingEnter, ','))

-- The RA-set groups are absent from the beast skeleton, which gets its
-- transitions from xdbsTASsitTkna.kf under the tassit* names. Every RA group
-- the tables name must therefore have a fallback, or a beast player gets
-- silence on those seats.
local raGroups = {}
for _, seatType in pairs(seats.SEAT_TYPE) do
    for _, g in ipairs({ seats.enterAnimFor(seats.TARGET_KIND.SEAT, seatType),
                         seats.exitAnimFor(seats.TARGET_KIND.SEAT, seatType) }) do
        if g and g:match('^rasit') then raGroups[g] = true end
    end
end
local noFallback = {}
for g in pairs(raGroups) do
    local alts = seats.groupFallbacks(g)
    if not alts or #alts == 0 then noFallback[#noFallback + 1] = g end
end
check('every RA-set transition has a beast-skeleton fallback',
      #noFallback == 0, table.concat(noFallback, ','))
check('every sit-down clip is one that ships', #wrongEnter == 0,
      table.concat(wrongEnter, ','))

-- The group names in the .kf are tassitd*/tassitu* -- double s. Typing the
-- handover spelling (tasistd/tasitu) would play nothing, silently.
check('the sit-down group is spelled as the .kf spells it',
      seats.enterAnimFor(seats.TARGET_KIND.SEAT, seats.SEAT_TYPE.BACKED_CHAIR) == 'tassitd1')
check('the stand-up group is spelled as the .kf spells it',
      seats.exitAnimFor(seats.TARGET_KIND.SEAT, seats.SEAT_TYPE.BACKED_CHAIR) == 'tassitu1')

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
