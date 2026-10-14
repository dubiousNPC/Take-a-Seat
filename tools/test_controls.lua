-- The seated control lock. Extracts the REAL setControlLock / lockControls /
-- releaseControls out of take_a_seat.lua and drives them.
--   python3 tools/luarun.py tools/test_controls.lua
--
-- What this pins: the lock must NOT turn off CONTROL_SWITCH.Controls when the
-- Controls interface is available. That switch is vanilla's
-- DisablePlayerControls, and OpenMW refuses the inventory, journal and quick
-- keys while it is off -- which is why menus could not be opened while seated.
local fails = 0
local function check(n, c, e)
    if c then print('  ok   ' .. n)
    else fails = fails + 1; print('  FAIL ' .. n .. '  ' .. tostring(e or '')) end
end

local src = io.open('scripts/take_a_seat/take_a_seat.lua'):read('a')
local body = src:match('(local function setControlLock%(on%).-\nlocal function releaseControls%(%).-\nend\n)')
assert(body, 'could not extract the control lock functions')

local function newEnv(withInterface)
    local log = { movement = {}, combat = {}, switches = {} }
    local env = {
        controlsLocked = false,
        self = { id = 'player' },
        types = { Player = {
            CONTROL_SWITCH = { Controls = 'Controls', Jumping = 'Jumping' },
            setControlSwitch = function(_, which, value)
                log.switches[#log.switches + 1] = which .. '=' .. tostring(value)
            end } },
        I = {},
    }
    if withInterface then
        env.I.Controls = {
            overrideMovementControls = function(v) log.movement[#log.movement + 1] = v end,
            overrideCombatControls = function(v) log.combat[#log.combat + 1] = v end,
        }
    end
    local chunk = load(body .. '\nreturn lockControls, releaseControls, function() return controlsLocked end',
                       'controls', 't', setmetatable(env, { __index = _G }))
    local lock, release, locked = chunk()
    return env, log, lock, release, locked
end

-- with the Controls interface ----------------------------------------------
local env, log, lock, release, locked = newEnv(true)
lock()
check('locking overrides movement', #log.movement == 1 and log.movement[1] == true)
check('locking overrides combat', #log.combat == 1 and log.combat[1] == true)
check('locking does NOT touch any control switch', #log.switches == 0,
      table.concat(log.switches, ','))
check('the lock is recorded', locked() == true)

lock(); lock()
check('locking twice does nothing further', #log.movement == 1, #log.movement)

release()
check('releasing clears the movement override',
      #log.movement == 2 and log.movement[2] == false)
check('releasing clears the combat override',
      #log.combat == 2 and log.combat[2] == false)
check('releasing still touches no control switch', #log.switches == 0)
check('the lock is cleared', locked() == false)
release()
check('releasing twice does nothing further', #log.movement == 2, #log.movement)

-- without the interface (stripped built-in scripts, older build) ------------
local env2, log2, lock2, release2 = newEnv(false)
lock2()
check('without the interface it falls back to the switches',
      #log2.switches == 2, table.concat(log2.switches, ','))
check('the fallback disables Controls and Jumping',
      log2.switches[1] == 'Controls=false' and log2.switches[2] == 'Jumping=false',
      table.concat(log2.switches, ','))
release2()
check('the fallback re-enables both',
      log2.switches[3] == 'Controls=true' and log2.switches[4] == 'Jumping=true',
      table.concat(log2.switches, ','))

-- Activation must stay with the engine: the Activate trigger is what stands
-- the player up, so an override of it would strand the player in the chair.
check('activation is never overridden', not src:find('overrideActivation'))

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
