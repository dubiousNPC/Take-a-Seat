-- Enter/exit one-shots: extracts the REAL playOneShot + pendingOneShot and the
-- REAL file-scope ended handler from take_a_seat.lua and drives them.
-- Run from the mod root:  python3 tools/luarun.py tools/test_oneshot.lua
local FAILED = false
local function check(n, c, e)
    print((c and '  ok   ' or '  FAIL ') .. n .. (c and '' or ('  ' .. tostring(e or ''))))
    if not c then FAILED = true end
end
local src = io.open('scripts/take_a_seat/take_a_seat.lua'):read('a')
local oneShot = src:match('(local pendingOneShot = {}.-\nlocal function playOneShot%(.-\nend\n)')
assert(oneShot, 'could not extract playOneShot')
local handler = src:match('(if I%.AnimationController and I%.AnimationController%.addAnimationEndedHandler then.-\nend\n)')
assert(handler, 'could not extract ended handler')
local code = src:gsub('%-%-%[%[.-%]%]', ''):gsub('%-%-[^\n]*', '')
check('openmw.animation is not asked for an ended handler',
    not code:find('anim%.addAnimationEndedHandler'))

local ended, timers, played = nil, {}, {}
local env = setmetatable({
    profileFor = function() return { loops = 0, priority = 1, blendMask = 15 } end,
    anim = { playBlended = function(_, g) played[#played + 1] = g end },
    self = {},
    async = { newUnsavableSimulationTimer = function(_, d, f) timers[#timers + 1] = f end },
    ONE_SHOT_TIMEOUT = 1.0,
    I = { AnimationController = { addAnimationEndedHandler = function(h) ended = h end } },
    core = { getSimulationTime = function() return 0 end },
    isSitting = false, sitAnimStarted = false, currentSitAnim = nil,
    replayWindowStart = 0, replayCount = 0, REPLAY_BURST_LIMIT = 5, REPLAY_BURST_WINDOW = 1,
    DEBUG = false, SIT_LOOPS = 1, SIT_PRIORITY = 1,
}, { __index = _G })
-- One chunk, so the handler closes over the same pendingOneShot local.
local play = load(oneShot .. handler .. '\nreturn playOneShot', 'oneshot', 't', env)()
check('one ended handler registered at file scope', type(ended) == 'function')

local done = 0
play(nil, 'enter', function() done = done + 1 end)
check('no clip: done runs immediately, nothing played', done == 1 and #played == 0)

done = 0
local ok, err = pcall(play, 'dbssit5_enter', 'enter', function() done = done + 1 end)
check('a real clip plays without raising', ok and played[#played] == 'dbssit5_enter', err)
check('done waits for the clip', done == 0)
ended('some_other_group')
check('an unrelated group ending does not finish it', done == 0)
ended('dbssit5_enter')
check('the clip ending runs done exactly once', done == 1, done)
for _, t in ipairs(timers) do t() end
check('the timeout backstop does not run done a second time', done == 1, done)

done = 0; timers = {}
play('never_ends', 'exit', function() done = done + 1 end)
for _, t in ipairs(timers) do t() end
check('a clip that never ends is finished by the timeout', done == 1)
ended('never_ends')
check('a late ended event after the timeout does not re-run done', done == 1, done)

print(FAILED and 'FAILURES' or 'ALL PASS')
if FAILED then os.exit(1) end
