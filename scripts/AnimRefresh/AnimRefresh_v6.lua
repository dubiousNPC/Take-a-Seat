---@omw-context player
-- AnimRefresh v6: tells subscribers when the player model is rebuilt
-- (first-person boundary, Rest/Travel/Training/Jail/ChargenRace, load).
-- See docs/animrefresh.md.
--   I.AnimRefresh.subscribe(key, fn(mode, previousMode, meta) [-> false to retry],
--                           { verify = true })
--   I.AnimRefresh.unsubscribe(key)
--   I.AnimRefresh.refreshNow([detail])
--

local camera = require('openmw.camera')
local async  = require('openmw.async')
local I      = require('openmw.interfaces')

local MY_VERSION = 6

do
    local existing = I.AnimRefresh
    if existing ~= nil then
        local theirVersion = existing.version
        if type(theirVersion) == 'number' then
            if theirVersion >= MY_VERSION then
                return -- a compatible equal or newer provider is already published
            end
        else
            print("[AnimRefresh] an existing AnimRefresh provider reports version " ..
                  tostring(theirVersion) .. " (" .. type(theirVersion) ..
                  "), which is not a number; publishing v" .. MY_VERSION ..
                  " over it. The other provider's handlers and timers are NOT retired " ..
                  "(v6 fix list item 13).")
        end
    end
end

local POLL_INTERVAL = 0.1

local DISPATCH_DELAY = 0

local JOIN_DELAY = 0.10
local LOAD_DELAY = 0.10

local VERIFY_DELAY = 1.8

local RETRY_DELAYS = {
    boundary = { 0.10, 0.10 },
    menu     = { 0.10, 0.10 },
    manual   = { 0.10, 0.10 },
    verify   = { 0.10, 0.10 },
    reconcile = { 0.10, 0.20, 0.40 },
}

local LATCH_UI_MODES = {
    Rest        = true,
    Travel      = true,
    Training    = true,
    Jail        = true,
    ChargenRace = true,
}

local registrations   = {}   -- key -> token (an opaque table)
local callbacks       = {}   -- token -> function
local verifiers       = {}   -- token -> true
local verifyDelays    = {}   -- token -> that subscriber's own verification delay (item 10)
local inFlight        = {}   -- token -> episode id, while its callback is running
local subscriberCount = 0
local pollTimer       = 0

local episodeCounter = 0
local latestCause    = 0

local dispatching = false

local pendingReconcile = nil   -- set of keys awaiting one primary reconciliation

local menuLatch      = nil
local menuLatchOrder = nil

local pendingReconcileOrigin = nil

local function isFirstPersonMode(mode)
    return mode == camera.MODE.FirstPerson
end

local baselineFirstPerson = isFirstPersonMode(camera.getMode())
local lastMode            = camera.getMode()

-- ---------------------------------------------------------------------------
-- EPISODES
-- ---------------------------------------------------------------------------

local function newEpisode(reason, mode, previous, recipients, origin, detail)
    episodeCounter = episodeCounter + 1
    local episode = {
        id         = episodeCounter,
        reason     = reason,
        mode       = mode,
        previous   = previous,
        recipients = recipients,
        retries    = RETRY_DELAYS[reason] or RETRY_DELAYS.boundary,
        origin     = origin,
        detail     = detail,
    }
    if reason == 'reconcile' then
        episode.cause    = latestCause
        episode.liveMode = true
    else
        latestCause   = episode.id
        episode.cause = episode.id
    end
    return episode
end

-- Deferred work is only still wanted if no newer cause has happened since.
local function episodeIsCurrent(episode)
    return latestCause == episode.cause
end

local function captureAll()
    local recipients = {}
    for key, token in pairs(registrations) do recipients[key] = token end
    return recipients
end

local function forget(key)
    local token = registrations[key]
    if token == nil then return false end
    registrations[key] = nil
    callbacks[token]   = nil
    verifiers[token]   = nil
    verifyDelays[token] = nil
    inFlight[token]    = nil
    subscriberCount    = subscriberCount - 1
    return true
end

-- ---------------------------------------------------------------------------
-- DELIVERY
-- ---------------------------------------------------------------------------

local dispatchOne

local function enterFromEngine()
    dispatching = false
end

local function quarantine(key, token, episodeId)
    print("[AnimRefresh] '" .. tostring(key) .. "' raised an error during episode " ..
          tostring(episodeId) .. " (the engine logged it as 'callTimer failed'); " ..
          "removing that registration. Re-subscribe after fixing it.")
    if registrations[key] == token then forget(key) end
    inFlight[token] = nil
end

dispatchOne = function(episode, key, attempt)
    enterFromEngine()
    if not episodeIsCurrent(episode) then return end

    local token = episode.recipients[key]
    if token == nil or registrations[key] ~= token then return end

    local previousFlight = inFlight[token]
    if previousFlight ~= nil then
        quarantine(key, token, previousFlight)
        return
    end

    local callback = callbacks[token]
    if callback == nil then return end

    local mode, previous = episode.mode, episode.previous
    if episode.liveMode then
        mode = camera.getMode()
        previous = mode
    end

    local meta = {
        reason           = episode.reason,
        episode          = episode.id,
        cause            = episode.cause,
        attempt          = attempt,
        origin           = episode.origin,
        detail           = episode.detail,
        observedMode     = episode.mode,
        observedPrevious = episode.previous,
        version          = MY_VERSION,
    }

    local wasDispatching = dispatching
    dispatching = true
    inFlight[token] = episode.id

    local result = callback(mode, previous, meta)

    inFlight[token] = nil
    dispatching = wasDispatching

    if result ~= false then return end

    local delay = episode.retries[attempt + 1]
    if delay == nil then
        print("[AnimRefresh] '" .. tostring(key) .. "' still not ready after " ..
              tostring(#episode.retries + 1) ..
              " attempts; giving up on this change")
        return
    end
    async:newUnsavableSimulationTimer(delay, function()
        dispatchOne(episode, key, attempt + 1)
    end)
end

local function dispatch(episode, delay)
    for key in pairs(episode.recipients) do
        async:newUnsavableSimulationTimer(delay, function()
            dispatchOne(episode, key, 0)
        end)
    end
end

-- ---------------------------------------------------------------------------
-- CAUSES
-- ---------------------------------------------------------------------------

local function raise(reason, previous, recipients, delay, origin, detail)
    if subscriberCount == 0 then return nil end
    if dispatching then return nil end
    local episode = newEpisode(reason, camera.getMode(), previous, recipients,
                               origin, detail)
    dispatch(episode, delay)
    return episode
end

local function fireBoundary(previous)
    local episode = raise('boundary', previous, captureAll(), DISPATCH_DELAY, 'poll')
    if episode == nil then return end
    if next(verifiers) == nil then return end

    for key, token in pairs(episode.recipients) do
        if verifiers[token] then
            async:newUnsavableSimulationTimer(verifyDelays[token] or VERIFY_DELAY, function()
                if not episodeIsCurrent(episode) then return end
                if registrations[key] ~= token then return end
                local followUp = newEpisode('verify', camera.getMode(), episode.previous,
                                            { [key] = token }, 'verify', episode.detail)
                followUp.cause = episode.cause
                latestCause = episode.cause
                dispatch(followUp, DISPATCH_DELAY)
            end)
        end
    end
end

local function requestReconcile(keys, delay, origin)
    local scheduling = pendingReconcile == nil
    pendingReconcile = pendingReconcile or {}
    for key, token in pairs(keys) do pendingReconcile[key] = token end
    if origin == 'load' or origin == 'init' or pendingReconcileOrigin == nil then
        pendingReconcileOrigin = origin
    end
    if not scheduling then return end

    async:newUnsavableSimulationTimer(delay, function()
        local batch       = pendingReconcile
        local batchOrigin = pendingReconcileOrigin
        pendingReconcile       = nil
        pendingReconcileOrigin = nil
        if batch == nil or subscriberCount == 0 then return end
        local recipients = nil
        for key, token in pairs(batch) do
            if registrations[key] == token then
                recipients = recipients or {}
                recipients[key] = token
            end
        end
        if recipients == nil then return end
        local episode = newEpisode('reconcile', camera.getMode(), lastMode, recipients,
                                   batchOrigin)
        dispatch(episode, DISPATCH_DELAY)
    end)
end

-- ---------------------------------------------------------------------------
-- DETECTION
-- ---------------------------------------------------------------------------

local checkMenuLatch

local function checkBoundary()
    local mode = camera.getMode()
    local nowFirst = isFirstPersonMode(mode)
    local previous = lastMode
    lastMode = mode

    if nowFirst == baselineFirstPerson then return end
    baselineFirstPerson = nowFirst
    fireBoundary(previous)
end

local function onUpdate(dt)
    enterFromEngine()
    if subscriberCount == 0 then return end
    pollTimer = pollTimer + dt
    if pollTimer < POLL_INTERVAL then return end
    pollTimer = 0
    checkBoundary()
    checkMenuLatch()
end

-- ---------------------------------------------------------------------------
-- ITEM 5: THE MENU LATCH
-- ---------------------------------------------------------------------------

local function latch(mode)
    menuLatch = menuLatch or {}
    if menuLatch[mode] then return end
    menuLatch[mode] = true
    menuLatchOrder = menuLatchOrder or {}
    menuLatchOrder[#menuLatchOrder + 1] = mode
end

local function clearLatch()
    menuLatch      = nil
    menuLatchOrder = nil
end

local uiModesView = nil
local function uiModes()
    if uiModesView == nil then
        local uiInterface = I.UI
        if uiInterface ~= nil then uiModesView = uiInterface.modes end
    end
    return uiModesView
end

local function scanUiStack()
    local modes = uiModes()
    if modes == nil then return false end
    local i = 1
    while true do
        local mode = modes[i]
        if mode == nil then break end
        if LATCH_UI_MODES[mode] then latch(mode) end
        i = i + 1
    end
    return i == 1
end

local function consumeLatch(origin)
    if menuLatch == nil then return end
    local detail = table.concat(menuLatchOrder, '+')
    clearLatch()
    raise('menu', lastMode, captureAll(), DISPATCH_DELAY, origin, detail)
end

checkMenuLatch = function()
    if not scanUiStack() then return end
    consumeLatch('poll')
end

local function uiModeChanged(data)
    enterFromEngine()
    if data == nil then return end

    local newMode, oldMode = data.newMode, data.oldMode

    if newMode ~= nil and LATCH_UI_MODES[newMode] then latch(newMode) end
    if oldMode ~= nil and LATCH_UI_MODES[oldMode] then latch(oldMode) end

    if newMode ~= nil then return end
    consumeLatch('uiMode')

end

local function onLoad()
    enterFromEngine()
    clearLatch()
    requestReconcile(captureAll(), LOAD_DELAY, 'load')
end

local function onInit()
    enterFromEngine()
    clearLatch()
    requestReconcile(captureAll(), LOAD_DELAY, 'init')
end

-- ---------------------------------------------------------------------------
-- INTERFACE
-- ---------------------------------------------------------------------------

local function validate(key, callback, opts)
    if type(key) ~= 'string' or key == '' then
        return ("[AnimRefresh] subscribe() needs a non-empty string key, got %s")
               :format(type(key) == 'string' and '""' or type(key))
    end
    if callback ~= nil and type(callback) ~= 'function' then
        return ("[AnimRefresh] subscribe('%s', ...) needs a function, got %s")
               :format(key, type(callback))
    end
    if opts ~= nil and opts ~= false then
        if type(opts) ~= 'table' then
            return ("[AnimRefresh] subscribe('%s', ...) options must be a table, got %s")
                   :format(key, type(opts))
        end
        if opts.verify ~= nil and type(opts.verify) ~= 'boolean' then
            return ("[AnimRefresh] subscribe('%s', ...) options.verify must be a boolean, got %s")
                   :format(key, type(opts.verify))
        end
        if opts.verifyDelay ~= nil then
            if type(opts.verifyDelay) ~= 'number' then
                return ("[AnimRefresh] subscribe('%s', ...) options.verifyDelay must be a number, got %s")
                       :format(key, type(opts.verifyDelay))
            end
            if opts.verifyDelay <= 0 or opts.verifyDelay ~= opts.verifyDelay then
                return ("[AnimRefresh] subscribe('%s', ...) options.verifyDelay must be above zero, got %s")
                       :format(key, tostring(opts.verifyDelay))
            end
        end
    end
    return nil
end

local function unsubscribe(key)
    if type(key) ~= 'string' or key == '' then return end
    forget(key)
end

local function subscribe(key, callback, opts)
    local problem = validate(key, callback, opts)
    if problem then error(problem) end

    if callback == nil then
        forget(key)
        return
    end

    local firstSubscriber = subscriberCount == 0
    forget(key)   -- replacing an existing registration retires its token first

    local token = {}
    registrations[key] = token
    callbacks[token]   = callback
    verifiers[token]   = (opts and opts.verify) or nil
    verifyDelays[token] = (opts and opts.verifyDelay) or nil
    subscriberCount    = subscriberCount + 1

    if firstSubscriber then
        lastMode            = camera.getMode()
        baselineFirstPerson = isFirstPersonMode(lastMode)
        pollTimer           = 0
    end

    scanUiStack()

    requestReconcile({ [key] = token }, JOIN_DELAY, 'subscribe')
end

local function refreshNow(detail)
    if detail ~= nil and type(detail) ~= 'string' then
        print("[AnimRefresh] refreshNow() takes an optional string detail, got " ..
              type(detail) .. "; ignoring it and refreshing anyway")
        detail = nil
    end
    raise('manual', lastMode, captureAll(), DISPATCH_DELAY, 'api', detail)
end

local function getMode()
    return camera.getMode()
end

local function isFirstPersonNow()
    return isFirstPersonMode(camera.getMode())
end

-- ---------------------------------------------------------------------------
-- ITEM 13: HANDOVER
-- ---------------------------------------------------------------------------
local previousProvider = nil
local retiredTo        = nil
local handedOver       = false

local PUBLISHED

local function versionOf(provider)
    if provider == nil then return nil end
    local reported = provider.version
    if type(reported) ~= 'number' then return nil end
    return reported
end

local function onInterfaceOverride(previous)
    enterFromEngine()
    if previous == nil then return end
    local theirVersion = versionOf(previous)

    if theirVersion ~= nil and theirVersion < MY_VERSION
       and type(previous.retire) == 'function' then
        if handedOver then return end
        handedOver = true
        previousProvider = nil
        previous.retire(PUBLISHED)
        print("[AnimRefresh] took over from v" .. tostring(theirVersion) ..
              " through its retire(); its registrations transferred and its scheduling " ..
              "stopped.")
        return
    end

    previousProvider = previous
    print("[AnimRefresh] publishing over an AnimRefresh v" .. tostring(theirVersion) ..
          " that offers no retire(). Its registrations cannot be enumerated, so each key " ..
          "is unsubscribed from it as that key subscribes here. Its onUpdate and timers " ..
          "keep running (v6 fix list item 13 / G12): load only one provider.")
end

local function retire(successor)
    if retiredTo ~= nil then return end
    if successor == nil or type(successor.subscribe) ~= 'function' then
        print("[AnimRefresh] retire() needs a successor with a subscribe(); ignoring, " ..
              "and staying live rather than leaving consumers with no provider.")
        return
    end
    retiredTo = successor

    local moved = 0
    for key, token in pairs(registrations) do
        local callback = callbacks[token]
        if callback ~= nil then
            successor.subscribe(key, callback,
                { verify = verifiers[token] and true or nil,
                  verifyDelay = verifyDelays[token] })
            moved = moved + 1
        end
    end

    registrations, callbacks, verifiers, verifyDelays = {}, {}, {}, {}
    inFlight, pendingReconcile, pendingReconcileOrigin = {}, nil, nil
    subscriberCount = 0
    clearLatch()
    print("[AnimRefresh] retired to a newer provider; transferred " .. moved ..
          " registration(s).")
end

local function subscribeOrForward(key, callback, opts)
    if retiredTo ~= nil then return retiredTo.subscribe(key, callback, opts) end
    return subscribe(key, callback, opts)
end

local function unsubscribeOrForward(key)
    if retiredTo ~= nil then return retiredTo.unsubscribe(key) end
    return unsubscribe(key)
end

local function refreshNowOrForward(detail)
    if retiredTo ~= nil then return retiredTo.refreshNow(detail) end
    return refreshNow(detail)
end

local function subscribeAndDeduplicate(key, callback, opts)
    local result = subscribeOrForward(key, callback, opts)
    if previousProvider ~= nil and callback ~= nil
       and type(previousProvider.unsubscribe) == 'function' then
        previousProvider.unsubscribe(key)
    end
    return result
end

PUBLISHED = {
    version       = MY_VERSION,
    subscribe     = subscribeAndDeduplicate,
    unsubscribe   = unsubscribeOrForward,
    refreshNow    = refreshNowOrForward,
    getMode       = getMode,
    isFirstPerson = isFirstPersonNow,
    retire        = retire,
}

return {
    interfaceName = "AnimRefresh",
    interface = PUBLISHED,
    -- An event, not an engine handler. See docs/animrefresh.md.
    eventHandlers = {
        UiModeChanged  = uiModeChanged,
    },
    engineHandlers = {
        onUpdate            = onUpdate,
        onInit              = onInit,
        onLoad              = onLoad,
        onInterfaceOverride = onInterfaceOverride,
    },
}
