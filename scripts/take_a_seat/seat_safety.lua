---@omw-context none
--[[
    seat_safety.lua -- evaluate, then commit.

    The mod used to commit a sit and then cope: teleport the player onto the
    seat, and deal with whatever happened. In a cramped interior that is how a
    player ends up standing inside geometry when they get up again.

    This module answers one question before the sit happens -- "is there a
    validated way back out of this seat?" -- and answers it again at stand-up
    time, because the world may have moved in between. If there is no answer,
    the sit is refused while the player is still standing somewhere they
    demonstrably got to on foot.

    The approach is taken from the Procedural Chatter NPC-seating pair
    (`SittingLogic`'s floorPosNear / groundPosBelow / ground-tolerance
    candidates, and `SittingGlobal`'s tipped-furniture test). The ordering is
    the load-bearing part: navmesh first (on the navmesh means walkable means
    not stuck), ground ray second (gives the actual floor height and rejects a
    point that is really the storey below).

    Two things from that pair are deliberately NOT copied: its per-frame
    re-teleport while seated, and its pcall density.

    NO openmw requires here. Everything comes in through `env`
    ({ nearby = ..., util = ..., agentBounds = function() ... end }), which is
    what lets tools/test_exit_safety.lua drive it against a scripted world.
]]

local M = {}

M.GROUND_PROBE_UP   = 24
M.GROUND_PROBE_DOWN = 200

M.GROUND_Z_TOLERANCE = 35

M.NAV_SEARCH_EXTENT = 96
M.NAV_MATCH_RADIUS  = 48

M.UP_Z_MIN = 0.7

M.EXIT_FORWARD = 48
M.EXIT_LIFT    = 8

---Is this furniture the right way up?
---@return boolean upright, number upZ
function M.isUpright(env, furniture)
    local up = furniture.rotation:apply(env.util.vector3(0, 0, 1))
    return up.z >= M.UP_Z_MIN, up.z
end

local function floorTypes(env)
    local C = env.nearby.COLLISION_TYPE
    return env.util.bitOr(env.util.bitOr(C.World, C.Door), C.HeightMap)
end

---@return any|nil position
function M.groundBelow(env, pos, ignore)
    local from = pos + env.util.vector3(0, 0, M.GROUND_PROBE_UP)
    local to   = pos - env.util.vector3(0, 0, M.GROUND_PROBE_DOWN)
    local res = env.nearby.castRay(from, to,
        { ignore = ignore, collisionType = floorTypes(env) })
    if not (res and res.hit and res.hitPos) then return nil end
    return res.hitPos
end

---@return any|nil position
function M.navMeshNear(env, pos)
    local find = env.nearby.findNearestNavMeshPosition
    if not find then return pos end     -- older build: do not block sitting
    local e = M.NAV_SEARCH_EXTENT
    local found = find(pos, {
        searchAreaHalfExtents = env.util.vector3(e, e, e),
        agentBounds = env.agentBounds and env.agentBounds() or nil,
    })
    if not found then return nil end
    local d = found - pos
    if math.sqrt(d.x * d.x + d.y * d.y) > M.NAV_MATCH_RADIUS then return nil end
    if math.abs(d.z) > M.GROUND_Z_TOLERANCE then return nil end
    return found
end

---@param floorZ number|nil the floor they were standing on before sitting
---@param navRequired boolean|nil default true
---@return any|nil position, string|nil reason
function M.validateStandPoint(env, candidate, ignore, floorZ, navRequired)
    local ground = M.groundBelow(env, candidate, ignore)
    if not ground then return nil, 'no floor under it' end
    local nav = M.navMeshNear(env, ground)
    if not nav then
        if navRequired == false then
            nav = ground
        else
            return nil, 'not on the navmesh'
        end
    end
    if floorZ and math.abs(nav.z - floorZ) > M.GROUND_Z_TOLERANCE then
        return nil, 'different storey'
    end
    return nav + env.util.vector3(0, 0, M.EXIT_LIFT)
end

---@return boolean
function M.pathClear(env, from, to, height, ignore)
    local lift = env.util.vector3(0, 0, height)
    local res = env.nearby.castRay(from + lift, to + lift,
        { ignore = ignore, collisionType = floorTypes(env) })
    return not (res and res.hit)
end

---@return table[] candidates each { pos = position, what = string }
function M.exitCandidates(env, seatPos, seatYaw, origin)
    local out = {}
    if origin then
        out[#out + 1] = { pos = origin, what = 'recorded origin', navRequired = false }
    end
    if seatYaw then
        local forward = env.util.vector3(math.sin(seatYaw), math.cos(seatYaw), 0)
        out[#out + 1] = { pos = seatPos + forward * M.EXIT_FORWARD,
                          what = 'forward of the seat' }
    end
    out[#out + 1] = { pos = seatPos, what = 'the seat itself' }
    return out
end

---The first candidate that validates.
---@return any|nil position, string what  -- `what` names the candidate or the refusal
function M.chooseStandPoint(env, seatPos, seatYaw, origin, ignore, floorZ)
    local tried = {}
    for _, cand in ipairs(M.exitCandidates(env, seatPos, seatYaw, origin)) do
        local ok, why = M.validateStandPoint(env, cand.pos, ignore, floorZ,
                                             cand.navRequired)
        if ok then return ok, cand.what end
        tried[#tried + 1] = cand.what .. ' (' .. tostring(why) .. ')'
    end
    return nil, table.concat(tried, ', ')
end

---@return string|nil reason, any|nil plannedExit, string|nil exitWhat
function M.sitRejectReason(env, furniture, seatPos, seatYaw, origin, floorZ)
    local upright, upZ = M.isUpright(env, furniture)
    if not upright then
        return string.format('the furniture is tipped over (up.z = %.2f)', upZ)
    end

    local exit, what = M.chooseStandPoint(env, seatPos, seatYaw, origin,
                                          furniture, floorZ)
    if not exit then
        return 'no validated way back out -- tried ' .. what
    end
    return nil, exit, what
end

return M
