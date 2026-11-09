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

-- Parkourwind FLOW: the sit yields it, BEFORE the shared override is taken and
-- resumed AFTER it is released (FLOW's stand-down writes the same flag).
local env3, log3, lock3, release3 = newEnv(true)
local seq = {}
env3.I.Controls.overrideMovementControls = function(v) seq[#seq + 1] = 'override ' .. tostring(v) end
local owners = {}
env3.I.Flow = {
    yield = function(o) owners[o] = true; seq[#seq + 1] = 'yield' end,
    resume = function(o) owners[o] = nil; seq[#seq + 1] = 'resume' end,
}
lock3()
check('sitting yields FLOW before taking the override',
      seq[1] == 'yield' and seq[2] == 'override true', table.concat(seq, ', '))
check('FLOW is yielded while seated', owners.TakeASeat == true)
release3()
check('standing resumes FLOW after releasing the override',
      seq[#seq] == 'resume' and seq[#seq - 1] == 'override false', table.concat(seq, ', '))
check('FLOW is free after standing', owners.TakeASeat == nil)

-- Jump stands the player up. In OpenMW 0.52 Jump is a TRIGGER, not a named
-- action, and the binder only knew actions: "this build has no Jump".
local bindSrc = src:match('(local STANDUP_ACTIONS = .-\nlocal function bindStandUpActions%(%).-\nend\n)')
assert(bindSrc, 'could not extract bindStandUpActions')
local stood, handlers, triggers = 0, {}, {}
local benv = setmetatable({
    isSitting = true, sitAnimStarted = true,
    stopSitting = function() stood = stood + 1 end,
    print = function() end,
    async = { callback = function(_, f) return f end },
    I = { UI = { getMode = function() return nil end } },
    input = {
        actions = { MoveForward = {}, MoveBackward = {}, MoveLeft = {}, MoveRight = {} },
        triggers = { Jump = {}, Activate = {} },
        registerActionHandler = function(k, f) handlers[k] = f end,
        registerTriggerHandler = function(k, f) triggers[k] = f end,
    },
}, { __index = _G })
local bind = load(bindSrc .. '\nreturn bindStandUpActions', 'bind', 't', benv)()
bind()
check('Jump is bound through the trigger when it is not an action', triggers.Jump ~= nil)
if triggers.Jump then triggers.Jump() end
check('the Jump trigger stands a seated player up', stood == 1, stood)
benv.isSitting = false
if triggers.Jump then triggers.Jump() end
check('and does nothing when not seated', stood == 1, stood)

-- Activation must stay with the engine: the Activate trigger is what stands
-- the player up, so an override of it would strand the player in the chair.
check('activation is never overridden', not src:find('overrideActivation'))

print(fails == 0 and 'ALL PASS' or (fails .. ' FAILURES'))
if fails > 0 then os.exit(1) end
