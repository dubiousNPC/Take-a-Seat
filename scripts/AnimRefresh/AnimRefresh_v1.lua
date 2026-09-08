---@omw-context player
--[[
    AnimRefresh v1 -- perspective-change notifier

    THE PROBLEM
    -----------
    Switching perspective rebuilds the player's animation object. Scripted
    animations and VFX attached to it are dropped in the process, so a sitting
    pose or a riding pose silently vanishes the moment the player presses the
    POV key. The usual "fix" is to lock the camera, which is what Devilish
    Horse/Guar Riding does (forceFirstPerson re-asserted on a timer). That
    trades the bug for a worse restriction: you can no longer look at the
    animation you are paying for.

    THE APPROACH
    ------------
    Lifted from Sun's Dusk p_backpacks.lua, which has the same problem with a
    backpack VFX and solves it by tracking the last camera mode, and on change
    removing and re-adding the effect. Two details from that implementation are
    worth copying exactly and are easy to miss:

      * the refresh must be DEFERRED, not immediate. Right after the switch the
        new skeleton may not be ready; Sun's Dusk guards with
        animation.hasBone and retries once on a 0.1s timer if the bone is
        missing.
      * it does not run on the per-frame job list. It sits on Sun's Dusk's
        "sluggish" (throttled) list, so even a mod of that size does not check
        camera mode every frame.

    DETECTION -- event first, poll as backstop
    ------------------------------------------
    Deliberate POV presses are caught by a TogglePOV trigger handler, which is
    instant and costs nothing when not pressed. That covers the case the player
    actually notices.

    A mode change can also happen without that key: vanity mode kicking in
    after idle, preview mode while the key is held, another mod calling
    setMode, or this mod's own setMode. Those are caught by a throttled poll
    at POLL_INTERVAL (default 1.0s, honouring the suite's "no more than once
    per second" rule). One second of latency is fine for those cases precisely
    because the player did not ask for them.

    The poll lives in onUpdate, not onFrame. onUpdate is the gameplay handler
    and is skipped while the game is paused, which is correct here -- you
    cannot change perspective from a menu. onFrame would only be needed for
    work that must continue during a pause.

    COST WHEN IDLE
    --------------
    With no subscribers, onUpdate does one table-empty check and returns. The
    trigger handler is not even reached unless the key is pressed. Subscribers
    unsubscribe when they stop animating, so a player who is neither sitting
    nor riding pays essentially nothing.

    USAGE
    -----
        I.AnimRefresh.subscribe("MyMod", function(mode, previousMode)
            -- re-issue whatever scripted animation you own
        end)
        I.AnimRefresh.unsubscribe("MyMod")

    Bundle this file in every mod that needs it, like SharedRay: the version
    guard below means only the newest loaded copy actually runs.
]]

local camera = require('openmw.camera')
local input  = require('openmw.input')
local async  = require('openmw.async')
local I      = require('openmw.interfaces')

local MY_VERSION = 1

if I.AnimRefresh and I.AnimRefresh.version >= MY_VERSION then
    return
end

-- How long to wait after a detected change before telling subscribers. The
-- animation object is being rebuilt during this window; firing immediately
-- means re-issuing an animation onto a skeleton that is about to be replaced.
local SETTLE_DELAY = 0.10

-- Backstop poll rate for mode changes that arrive without a TogglePOV press.
local POLL_INTERVAL = 1.0

local subscribers   = {}
local subscriberCount = 0
local lastMode      = camera.getMode()
local pollTimer     = 0
local pendingSettle = false

-- ---------------------------------------------------------------------------
-- DELIVERY
-- ---------------------------------------------------------------------------

-- A subscriber blowing up must not stop delivery to the others, same rule
-- SharedRay applies to its callbacks.
local function fire(mode, previous)
    for key, callback in pairs(subscribers) do
        local ok, err = pcall(callback, mode, previous)
        if not ok then
            print("[AnimRefresh] callback error in '" .. tostring(key) .. "': " .. tostring(err))
        end
    end
end

local function scheduleRefresh(previous)
    if pendingSettle then return end   -- collapse a burst of changes into one
    pendingSettle = true
    async:newUnsavableSimulationTimer(SETTLE_DELAY, function()
        pendingSettle = false
        local mode = camera.getMode()
        lastMode = mode
        if subscriberCount == 0 then return end
        fire(mode, previous)
    end)
end

local function checkMode()
    local mode = camera.getMode()
    if mode == lastMode then return end
    local previous = lastMode
    lastMode = mode
    scheduleRefresh(previous)
end

-- ---------------------------------------------------------------------------
-- DETECTION
-- ---------------------------------------------------------------------------

-- Registered defensively: TogglePOV is an engine trigger, but trigger keys are
-- registered by built-in scripts and a stripped or modified setup may not have
-- it. If it is absent the poll below still catches everything, just later.
if input.triggers and input.triggers.TogglePOV then
    input.registerTriggerHandler("TogglePOV", async:callback(function()
        if subscriberCount == 0 then return end
        -- The mode has not actually changed yet at trigger time, so schedule
        -- off the press rather than comparing modes here.
        scheduleRefresh(lastMode)
    end))
end

local function onUpdate(dt)
    if subscriberCount == 0 then return end

    pollTimer = pollTimer + dt
    if pollTimer < POLL_INTERVAL then return end
    pollTimer = 0
    checkMode()
end

-- ---------------------------------------------------------------------------
-- INTERFACE
-- ---------------------------------------------------------------------------

local function subscribe(key, callback)
    if not key then return end
    if subscribers[key] == nil and callback ~= nil then
        subscriberCount = subscriberCount + 1
    elseif subscribers[key] ~= nil and callback == nil then
        subscriberCount = subscriberCount - 1
    end
    subscribers[key] = callback
    -- Re-baseline so a subscriber joining just after a switch does not get an
    -- immediate spurious refresh for a change it was never present for.
    lastMode = camera.getMode()
    pollTimer = 0
end

local function unsubscribe(key)
    subscribe(key, nil)
end

-- Force a refresh without waiting for a detected change. Useful right after
-- your own setMode call, or after a UI mode that rebuilds the model (Sun's
-- Dusk refreshes its VFX after Rest and Travel menus for exactly this reason).
local function refreshNow()
    scheduleRefresh(lastMode)
end

local function getMode()
    return lastMode
end

return {
    interfaceName = "AnimRefresh",
    interface = {
        version     = MY_VERSION,
        subscribe   = subscribe,
        unsubscribe = unsubscribe,
        refreshNow  = refreshNow,
        getMode     = getMode,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
