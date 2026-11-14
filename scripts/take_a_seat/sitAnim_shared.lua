---@omw-context runtime
-- Seat, bed and animation profiles. Data only; other mods may require it.
-- See README.md for the lookup API and how to add seats.

local core = require('openmw.core')

-- ---------------------------------------------------------------------------
-- SEAT TYPES
-- ---------------------------------------------------------------------------
-- Pose classification, not mesh category

local SEAT_TYPE = {
    BACKED_CHAIR      = "backed_chair",
    BENCH             = "bench",
    STOOL             = "stool",
    BARSTOOL          = "barstool",
    SINGLE_SEAT_BENCH = "single_seat_bench",
    CUSHION           = "cushion",
    THRONE            = "throne",
    BATH              = "bath",
}
local T = SEAT_TYPE

-- ---------------------------------------------------------------------------
-- ANIMATION GROUPS
-- ---------------------------------------------------------------------------
-- One group per seat type.
local SEAT_ANIM_BY_NAME = {
    BACKED_CHAIR      = "dbssit5",
    BENCH             = "dbssit4",
    STOOL             = "dbssitting24",
    BARSTOOL          = "dbssit6",
    SINGLE_SEAT_BENCH = "dbssit4",
    CUSHION           = "rasit6",
    THRONE            = "dbssitThrone4",
    BATH              = "dbssit2",
}

---Resolve a name-keyed table to a seat-type-keyed one, naming anything unknown.
---@param byName table<string, any>
---@param label string
local function resolveByType(byName, label)
    local out = {}
    for name, value in pairs(byName) do
        local seatType = SEAT_TYPE[name]
        if not seatType then
            error(("[take a seat] %s references unknown seat type '%s' -- " ..
                   "add it to SEAT_TYPE or remove the row"):format(label, name))
        end
        out[seatType] = value
    end
    return out
end

local SEAT_ANIM = resolveByType(SEAT_ANIM_BY_NAME, "SEAT_ANIM")

-- ---------------------------------------------------------------------------
-- ENTER / EXIT ONE-SHOTS
-- ---------------------------------------------------------------------------

local SEAT_ENTER_ANIM = resolveByType({
    BACKED_CHAIR      = "tassitd1",
    BENCH             = "tassitd2",
    STOOL             = "tassitd1",
    BARSTOOL          = "tassitd1",
    SINGLE_SEAT_BENCH = "tassitd2",
    CUSHION           = "rasitd1",
    THRONE            = "tassitd1",
    BATH              = "rasitd1",
}, "SEAT_ENTER_ANIM")

local SEAT_EXIT_ANIM = resolveByType({
    BACKED_CHAIR      = "tassitu1",
    BENCH             = "tassitu1",
    STOOL             = "tassitu1",
    BARSTOOL          = "tassitu1",
    SINGLE_SEAT_BENCH = "tassitu1",
    CUSHION           = "rasitup1",
    THRONE            = "tassitu1",
    BATH              = "tassitu1",
}, "SEAT_EXIT_ANIM")

-- ---------------------------------------------------------------------------
-- ANIMATION GROUP FALLBACKS
-- ---------------------------------------------------------------------------
local GROUP_FALLBACKS = {
    rasitd1  = { "tassitd1" },
    rasitd2  = { "tassitd2", "tassitd1" },
    rasitu1  = { "tassitu1" },
    rasitu2  = { "tassitu2", "tassitu1" },
    rasitup1 = { "tassitu1" },
    tassitd2 = { "tassitd1" },
    tassitu2 = { "tassitu1" },

    -- The bed ENTER transitions ship only in the third-person folders:
    -- animations/xbase_anim{,_female,kna}/xSleepT.kf carries sleept1..6 AND
    -- sleepte1..6, but the three .1st copies carry sleept1..6 only. Without a
    -- fallback, playableGroup returns nil in first person and the lie-down
    -- transition is skipped silently. Falling back to the matching held pose
    -- is the right degradation: the player still ends up lying correctly, just
    -- without the transition, which is how the rasit/tassit chains above
    -- already behave.
    sleepte1 = { "sleept1" },
    sleepte2 = { "sleept2" },
    sleepte3 = { "sleept3" },
    sleepte4 = { "sleept4" },
    sleepte5 = { "sleept5" },
    sleepte6 = { "sleept6" },
}

---Alternatives for a group, best first, excluding the group itself.
---@param group string|nil
---@return table
local function groupFallbacks(group)
    if not group then return {} end
    return GROUP_FALLBACKS[group] or {}
end

-- ---------------------------------------------------------------------------
-- POSE DELTA
-- ---------------------------------------------------------------------------
-- Values are actor-space: x right, y forward, z up, in game units.
local POSE_DELTA = {
    -- dbssit4 = { x = 0, y = 0, z = 0 },
}

local function poseDelta(group)
    return group and POSE_DELTA[group] or nil
end

-- ---------------------------------------------------------------------------
-- AUTHORED SOLVER PROFILES
-- ---------------------------------------------------------------------------
local solver = require('scripts.take_a_seat.solver_profiles')

local SOLVER_CONTRACT = 3

local solverUsable = solver and solver.contractVersion == SOLVER_CONTRACT
if not solverUsable then
    print(("[take a seat] solver_profiles.lua reports contract %s, expected %d; "
        .. "authored placement disabled, falling back to raycast positioning")
        :format(tostring(solver and solver.contractVersion), SOLVER_CONTRACT))
end

---Authored profile for a model path, or nil.
---@param model string|nil a VFS model path, any case, either slash
local function solverProfile(model)
    if not solverUsable or not model then return nil end
    local key = model:lower():gsub('\\', '/')
    return solver.PROFILES[key]
end

---Slot by index, falling back to the first.
local function solverSlot(profile, index)
    if not profile or not profile.slots then return nil end
    return profile.slots[index or 1] or profile.slots[1]
end

-- ---------------------------------------------------------------------------
-- TARGET KINDS AND PRIORITY PROFILES
-- ---------------------------------------------------------------------------

local TARGET_KIND = {
    SEAT = "seat",
    BED  = "bed",
    MISC = "misc",
}

---@param anim any the openmw.animation module, passed in so this file requires nothing
---@return table<string, table> profiles keyed by TARGET_KIND
local function buildAnimProfiles(anim)
    local P, B, BG = anim.PRIORITY, anim.BLEND_MASK, anim.BONE_GROUP

    local function split(legs, upper)
        return {
            [BG.LowerBody] = legs,
            [BG.Torso]     = upper,
            [BG.LeftArm]   = upper,
            [BG.RightArm]  = upper,
        }
    end

    -- Transitions outrank the idle on the legs
    local TRANSITION_LEGS = P.Knockdown
    local TRANSITION_UPPER = P.Weapon
    -- Block, NOT Weapon. The engine refuses to switch the camera to first
    -- person while ANY animation state holds Hit, Weapon, Knockdown or Death
    -- on any bone group (MWRender::Animation::upperBodyReady), and queues the
    -- switch instead. A seated idle at Weapon held for the whole sit, so a
    -- player seated in third person could not get back to first person until
    -- they stood up - measured in OpenMW 0.52 on a chair, a bench and a
    -- cushion. Block still outranks every engine leg state (Movement, Jump,
    -- Hit, Weapon) and stays under the transitions' Knockdown, and the tuple
    -- is not uniform, so a shield's uniform Block cannot erase it. The short
    -- enter and exit clips may still block; a switch queued there resolves as
    -- soon as they end.
    local IDLE_LEGS = P.Block
    local IDLE_UPPER = P.Movement
    local BED_LEGS = P.Scripted
    local BED_UPPER = P.Movement

    return {
        [TARGET_KIND.SEAT] = {
            idle  = { priority = split(IDLE_LEGS, IDLE_UPPER),
                      blendMask = B.All, loops = 0 },
            enter = { priority = split(TRANSITION_LEGS, TRANSITION_UPPER),
                      blendMask = B.All, loops = 0 },
            exit  = { priority = split(TRANSITION_LEGS, TRANSITION_UPPER),
                      blendMask = B.All, loops = 0 },
        },
        [TARGET_KIND.BED] = {
            idle  = { priority = split(BED_LEGS, BED_UPPER),
                      blendMask = B.All, loops = 0 },
            enter = { priority = split(BED_LEGS, BED_UPPER),
                      blendMask = B.All, loops = 0 },
            exit  = { priority = split(BED_LEGS, BED_UPPER),
                      blendMask = B.All, loops = 0 },
        },
        [TARGET_KIND.MISC] = {
            idle  = { priority = split(IDLE_LEGS, IDLE_UPPER),
                      blendMask = B.LowerBody, loops = 0 },
            enter = { priority = split(TRANSITION_LEGS, TRANSITION_UPPER),
                      blendMask = B.All, loops = 0 },
            exit  = { priority = split(TRANSITION_LEGS, TRANSITION_UPPER),
                      blendMask = B.All, loops = 0 },
        },
    }
end

-- ---------------------------------------------------------------------------
-- BEDS
-- ---------------------------------------------------------------------------

local BED_TYPE = {
    SINGLE   = "single",
    DOUBLE   = "double",
    BUNK     = "bunk",
    BEDROLL  = "bedroll",
    HAMMOCK  = "hammock",
}

local function resolveBedByName(byName, label)
    local out = {}
    for name, value in pairs(byName) do
        local bedType = BED_TYPE[name]
        if not bedType then
            error(("[take a seat] %s references unknown bed type '%s'")
                  :format(label, name))
        end
        out[bedType] = value
    end
    return out
end

local BED_ANIM = resolveBedByName({
    SINGLE  = "sleept1",
    DOUBLE  = "sleept2",
    BUNK    = "sleept5",
    BEDROLL = "sleept1",
    HAMMOCK = "sleept6",
}, "BED_ANIM")

local BED_ENTER_ANIM = resolveBedByName({ SINGLE = "sleepte1", DOUBLE = "sleepte2", BUNK = "sleepte5", BEDROLL = "sleepte1", HAMMOCK = "sleepte6" }, "BED_ENTER_ANIM")
local BED_EXIT_ANIM  = resolveBedByName({ SINGLE = "getup1", DOUBLE = "getup1", BUNK = "getup1", BEDROLL = "getup1", HAMMOCK = "getup1" }, "BED_EXIT_ANIM")

local BEDS_ENABLED = true

-- Which way the body lies along a bed, relative to the authored slot yaw, in
-- degrees. The solver pack's bed yaws were solved for its reference pose
-- (slee8). The root (where the hips land) carries over to sleept* unchanged --
-- kf_root_offsets.py measures identical Bip01/Pelvis translations -- but the
-- FACING does not: on every single and double tested in OpenMW 0.52 the
-- sleept1/sleept2 body lay with its feet on the pillow at the pack yaw and with
-- its head on the pillow at +180 (docs/tickets/0001). Bunks (sleept5, upper
-- berth photographed) and bedrolls (sleept1) match. Hammocks play sleept6,
-- which lies across the pack's yaw: photographed at 0/90/180/270 on
-- active_de_bed_29/30, only +90 lies along the hammock with the head at the
-- pillow end. So this is per bed type, not one constant.
local BED_POSE_YAW = resolveBedByName({
    SINGLE  = 180,
    DOUBLE  = 180,
    BUNK    = 180,
    BEDROLL = 180,
    HAMMOCK = 90,
}, "BED_POSE_YAW")

-- Bed type corrections by MODEL, applied before the solver pack's own
-- bedType. The pack labels the three vanilla hammock meshes "single"; their
-- in-game names are Hammock and SDP's own row for active_de_p_bed_28 says
-- hammock (docs/tickets/0003).
local BED_TYPE_BY_MODEL = {
    ['meshes/f/active_de_bed_28.nif'] = BED_TYPE.HAMMOCK,
    ['meshes/f/active_de_bed_29.nif'] = BED_TYPE.HAMMOCK,
    ['meshes/f/active_de_bed_30.nif'] = BED_TYPE.HAMMOCK,
}

-- ---------------------------------------------------------------------------
-- MISCELLANEOUS ITEMS -- STUB
-- ---------------------------------------------------------------------------
-- Reserved for props that are neither seat nor bed: leaning on a railing,
-- kneeling at a shrine, resting against a crate. Deliberately empty.

local MISC_TYPE = {
    -- LEAN_RAIL = "lean_rail",
    -- KNEEL     = "kneel",
}

local MISC_ANIM       = {}   -- [MISC_TYPE.X] = "groupname"
local MISC_ENTER_ANIM = {}
local MISC_EXIT_ANIM  = {}
local MISC_ITEMS      = {}   -- [recordId] = MISC_TYPE.X

-- Per-plugin animation overrides, merged only when the plugin is loaded.
-- Same shape as SEAT_ANIM. Use for animation packs that ship their own groups.
local MOD_ANIM_DATABASE = {
    -- ["YourAnimPack.esp"] = {
    --     [T.CUSHION] = "yourpack_sit_floor_01",
    -- },
}

-- ---------------------------------------------------------------------------
-- SEATS -- VANILLA
-- ---------------------------------------------------------------------------
-- Keys lowercase: Object.recordId is always lowercase.

local BASE_SEATS = {
    -- backed_chair
    ["furn_com_r_chair_01"]  = T.BACKED_CHAIR,
    ["furn_com_rm_chair_03"] = T.BACKED_CHAIR,
    ["furn_de_p_chair_01"]   = T.BACKED_CHAIR,
    ["furn_de_p_chair_02"]   = T.BACKED_CHAIR,
    ["furn_de_r_chair_03"]   = T.BACKED_CHAIR,
    ["bm_ka_chair"]   = T.BACKED_CHAIR,

    -- bench
    ["furn_com_p_bench_01"]  = T.BENCH,
    ["furn_com_rm_bench_02"] = T.BENCH,
    ["furn_com_rm_stool_01"] = T.BENCH,   -- named stool, poses as a bench
    ["furn_de_bench_03"]     = T.BENCH,
    ["furn_de_ex_bench_01"]  = T.BENCH,
    ["furn_de_p_bench_03"]   = T.BENCH,
    ["furn_de_p_bench_04"]   = T.BENCH,
    ["furn_de_r_bench_01"]   = T.BENCH,
    ["furn_de_r_bench_02"]   = T.BENCH,

    -- stool
    ["furn_com_pm_stool_02"] = T.STOOL,
    ["furn_de_ex_stool_02"]  = T.STOOL,
    ["furn_de_p_stool_01"]   = T.STOOL,
    ["furn_de_p_stool_02"]   = T.STOOL,

    -- barstool
    ["furn_com_rm_barstool"] = T.BARSTOOL,

    -- single_seat_bench
    ["furn_com_pm_chair_02"] = T.SINGLE_SEAT_BENCH,  -- named chair, poses as a padded bench

    -- cushion (floor seating)
    ["furn_de_cushion_square_01"] = T.CUSHION,
    ["furn_de_cushion_square_02"] = T.CUSHION,
    ["furn_de_cushion_square_03"] = T.CUSHION,
    ["furn_de_cushion_square_04"] = T.CUSHION,
    ["furn_de_cushion_square_05"] = T.CUSHION,
    ["furn_de_cushion_square_06"] = T.CUSHION,
    ["furn_de_cushion_square_07"] = T.CUSHION,
    ["furn_de_cushion_square_08"] = T.CUSHION,
    ["furn_de_cushion_square_09"] = T.CUSHION,
    ["furn_de_cushion_round_01"]  = T.CUSHION,
    ["furn_de_cushion_round_02"]  = T.CUSHION,
    ["furn_de_cushion_round_03"]  = T.CUSHION,
    ["furn_de_cushion_round_04"]  = T.CUSHION,
    ["furn_de_cushion_round_05"]  = T.CUSHION,
    ["furn_de_cushion_round_06"]  = T.CUSHION,
    ["furn_de_cushion_round_07"]  = T.CUSHION,

    -- throne
    ["bm_ka_throne"]  = T.THRONE,
}

-- ---------------------------------------------------------------------------
-- SEATS -- PER PLUGIN
-- ---------------------------------------------------------------------------

local MOD_SEAT_DATABASE = {
    ["tamriel_data.esm"] = {
        -- throne
        ["t_ayl_dngruin_f_throne_01"] = T.THRONE,
        ["t_ayl_dngruin_f_chair_01"]  = T.THRONE,
        ["t_ayl_dngruin_f_chair_02"]  = T.THRONE,

        -- backed_chair
        ["t_imp_furnm_chair01brown"]  = T.BACKED_CHAIR,
        ["t_imp_furnm_chair01green"]  = T.BACKED_CHAIR,
        ["t_imp_furnr_chair_01"]      = T.BACKED_CHAIR,
        ["t_imp_furnr_chair_02"]      = T.BACKED_CHAIR,
        ["t_imp_furnr_chair_03"]      = T.BACKED_CHAIR,
        ["t_imp_furnr_chair_04"]      = T.BACKED_CHAIR,
        ["t_imp_furnr_chair_05"]      = T.BACKED_CHAIR,
        ["t_nor_furnm_chair_01"]      = T.BACKED_CHAIR,
        ["t_nor_furnm_chair_02"]      = T.BACKED_CHAIR,
        ["t_nor_furnm_chair_03"]      = T.BACKED_CHAIR,
        ["t_nor_furnr_chair_02"]      = T.BACKED_CHAIR,

        -- bench
        ["t_nor_furnm_bench_01"] = T.BENCH,
        ["t_nor_furnm_bench_02"] = T.BENCH,
        ["t_nor_furnr_bench_05"] = T.BENCH,

        -- stool
        ["t_nor_furnm_stool_01"] = T.STOOL,

        -- barstool
        ["t_imp_furnr_barstool_01"] = T.BARSTOOL,

        -- cushion
        ["t_he_furn_cushion_round_01"]  = T.CUSHION,
        ["t_he_furn_cushion_round_02"]  = T.CUSHION,
        ["t_he_furn_cushion_round_03"]  = T.CUSHION,
        ["t_he_furn_cushion_round_04"]  = T.CUSHION,
        ["t_he_furn_cushion_round_05"]  = T.CUSHION,
        ["t_he_furn_cushion_round_06"]  = T.CUSHION,
        ["t_he_furn_cushion_round_07"]  = T.CUSHION,
        ["t_he_furn_cushion_round_08"]  = T.CUSHION,
        ["t_he_furn_cushion_square_01"] = T.CUSHION,
        ["t_he_furn_cushion_square_02"] = T.CUSHION,
        ["t_he_furn_cushion_square_03"] = T.CUSHION,
        ["t_he_furn_cushion_square_04"] = T.CUSHION,
        ["t_he_furn_cushion_square_05"] = T.CUSHION,
        ["t_he_furn_cushion_square_06"] = T.CUSHION,
        ["t_he_furn_cushion_square_07"] = T.CUSHION,
        ["t_he_furn_cushion_square_08"] = T.CUSHION,
        ["t_orc_setnomad_cushion_01"]   = T.CUSHION,
        ["t_orc_setnomad_cushion_02"]   = T.CUSHION,
        ["t_rga_furn_cushion_01"]       = T.CUSHION,
        ["t_rga_furn_cushion_02"]       = T.CUSHION,
        ["t_rga_furn_cushion_03"]       = T.CUSHION,
        ["t_rga_furn_cushion_04"]       = T.CUSHION,
    },

    ["oaab_data.esm"] = {
        ["ab_furn_commidchaircushgreen"] = T.BACKED_CHAIR,
        ["ab_furn_commidchaircushbrown"] = T.BACKED_CHAIR,
        ["ab_furn_commidchaircushgrey"]  = T.BACKED_CHAIR,
        ["ab_furn_daemetalchair01"]      = T.BACKED_CHAIR,
        ["ab_furn_deexchair01"]          = T.BACKED_CHAIR,
        ["ab_furn_demidchair"]           = T.BACKED_CHAIR,
        ["ab_furn_demidbench"]           = T.BENCH,
        ["ab_furn_deplnbench04"]         = T.BENCH,
        ["ab_furn_demidstool"]           = T.BARSTOOL,
    },

    ["bov.esm"] = {
        ["s3_saunabench_01"]             = T.BENCH,
        ["S3_bath_02"]                   = T.BATH,
        ["S3_bath_01gr"]                 = T.BATH,
        ["S3_bath_03"]                   = T.BATH,
    },
}

-- ---------------------------------------------------------------------------
-- PATTERN FALLBACK
-- ---------------------------------------------------------------------------

local SEAT_TYPE_PATTERNS = {
    { seat = T.BARSTOOL, patterns = { "barstool", "bar_stool" } },
    { seat = T.SINGLE_SEAT_BENCH, patterns = { "single_seat", "seat_bench" } },
    { seat = T.BENCH,    patterns = { "bench", "furn_nord_bench", "furn_com_bench" } },
    { seat = T.STOOL,    patterns = { "stool" } },
    { seat = T.BACKED_CHAIR, patterns = { "chair", "seat", "com_m_chr" } },
    { seat = T.THRONE, patterns = { "throne" } },
}

-- Never sittable, whatever else matches.
local BLACKLIST = {
    ["furn_com_rm_bar_counter"] = true,
}

-- ---------------------------------------------------------------------------
-- SEAT HEIGHT CALIBRATION
-- ---------------------------------------------------------------------------
-- Measured offset from a record's origin up to its seat plane

local SIT_PIVOT_OFFSET = {
    ["furn_de_p_chair_02"] = 1.2,
    ["ab_furn_demidchair"] = 1.2,
    ["furn_de_r_chair_03"] = 1.2,
}

local SIT_PIVOT_OFFSET_FALLBACK = {
    ["furn_com_rm_bar"]      = 38,
    ["ab_furn_demidtable02"] = 38,
    ["furn_de_r_table_07"]   = 38,
    default                  = 26,
}

-- ---------------------------------------------------------------------------
-- RUNTIME MERGE
-- ---------------------------------------------------------------------------

local seatsByRecord = {}
for id, seat in pairs(BASE_SEATS) do
    seatsByRecord[id:lower()] = seat
end

local seatAnim = {}
for seat, group in pairs(SEAT_ANIM) do
    seatAnim[seat] = group
end

local loadedPlugins = {}
for _, file in ipairs(core.contentFiles.list) do
    loadedPlugins[file:lower()] = true
end

for plugin, records in pairs(MOD_SEAT_DATABASE) do
    if loadedPlugins[plugin:lower()] then
        for id, seat in pairs(records) do
            seatsByRecord[id:lower()] = seat
        end
    end
end

for plugin, groups in pairs(MOD_ANIM_DATABASE) do
    if loadedPlugins[plugin:lower()] then
        for seat, group in pairs(groups) do
            seatAnim[seat] = group
        end
    end
end

-- ---------------------------------------------------------------------------
-- LOOKUP
-- ---------------------------------------------------------------------------

local seatTypeCache = {}

local function getSeatType(recordId)
    if not recordId then return nil end
    local cached = seatTypeCache[recordId]
    if cached ~= nil then return cached or nil end

    local lower  = recordId:lower()
    local result = false

    if not BLACKLIST[lower] then
        result = seatsByRecord[lower] or false
        if not result then
            for _, entry in ipairs(SEAT_TYPE_PATTERNS) do
                for _, p in ipairs(entry.patterns) do
                    if lower:find(p, 1, true) then result = entry.seat; break end
                end
                if result then break end
            end
        end
    end

    seatTypeCache[recordId] = result
    return result or nil
end

local function isSittable(recordId)
    return getSeatType(recordId) ~= nil
end

local function animForSeat(seatType)
    return seatAnim[seatType or T.BACKED_CHAIR]
end

local function pivotOffset(recordId)
    if not recordId then return nil end
    return SIT_PIVOT_OFFSET[recordId:lower()]
end

local function fallbackOffset(recordId)
    if not recordId then return SIT_PIVOT_OFFSET_FALLBACK.default end
    local lower = recordId:lower()
    for pattern, h in pairs(SIT_PIVOT_OFFSET_FALLBACK) do
        if pattern ~= "default" and lower:find(pattern, 1, true) then return h end
    end
    return SIT_PIVOT_OFFSET_FALLBACK.default
end

-- ---------------------------------------------------------------------------
-- GENERATED PROFILES
-- ---------------------------------------------------------------------------

local profiles = require('scripts.take_a_seat.furniture_profiles')

for recordId, seatType in pairs(profiles.SEATS) do
    if seatsByRecord[recordId] == nil then
        seatsByRecord[recordId] = seatType
    end
end

for recordId, z in pairs(profiles.PIVOTS) do
    if SIT_PIVOT_OFFSET[recordId] == nil then
        SIT_PIVOT_OFFSET[recordId] = z
    end
end

local bedsByRecord = {}
for recordId, bed in pairs(profiles.BEDS) do
    bedsByRecord[recordId] = {
        type = BED_TYPE[bed.type] or BED_TYPE.SINGLE,
        z    = bed.z,
        yaw  = bed.yaw,
    }
end

-- ---------------------------------------------------------------------------
-- ACCESSORS
-- ---------------------------------------------------------------------------

---@return string|nil bedType
local function getBedType(recordId)
    if type(recordId) ~= 'string' then return nil end
    local bed = bedsByRecord[recordId:lower()]
    return bed and bed.type or nil
end

---Bed type from an authored solver profile, keyed by MODEL.
---
---The record-id table above comes from the SDP harvest and names 39 beds. The
---solver pack carries 289, keyed by model path, so this is what lets a bed
---record from a mod this one has never heard of be recognised as long as it
---reuses a known mesh -- the same reason the seat path is model-keyed.
---@param model string|nil a VFS model path, any case, either slash
---@return string|nil bedType
local function bedTypeForModel(model)
    local profile = solverProfile(model)
    if not profile or profile.kind ~= 'sleep' then return nil end
    local fixed = BED_TYPE_BY_MODEL[model:lower():gsub('\\', '/')]
    if fixed then return fixed end
    local name = profile.bedType and profile.bedType:upper() or nil
    return (name and BED_TYPE[name]) or BED_TYPE.SINGLE
end

---@param recordId string|nil
---@param model string|nil optional, widens the check to the 289 pack profiles
local function isBed(recordId, model)
    if not BEDS_ENABLED then return false end
    if getBedType(recordId) ~= nil then return true end
    return bedTypeForModel(model) ~= nil
end

---Placement for a bed record: sleep-root vertical offset and pose yaw.
local function bedPlacement(recordId)
    if type(recordId) ~= 'string' then return nil end
    return bedsByRecord[recordId:lower()]
end

local function getMiscType(recordId)
    if type(recordId) ~= 'string' then return nil end
    return MISC_ITEMS[recordId:lower()]
end

local function isMiscItem(recordId)
    return getMiscType(recordId) ~= nil
end

---@param recordId string|nil
---@param model string|nil optional; lets a bed be recognised from the
---       model-keyed solver pack when the record id is not in the SDP list
---@return string|nil kind, string|nil subType
local function classify(recordId, model)
    local misc = getMiscType(recordId)
    if misc then return TARGET_KIND.MISC, misc end
    if BEDS_ENABLED then
        -- The pack's type wins when the model has a profile: it is the same
        -- source as the slots being placed (a pack "bunk" has sleep_bottom and
        -- sleep_top), whereas the SDP record list calls every vanilla bunk
        -- "single" (docs/tickets/0003). The record list remains the source for
        -- beds the pack does not cover.
        local bed = bedTypeForModel(model) or getBedType(recordId)
        if bed then return TARGET_KIND.BED, bed end
    end
    local seat = getSeatType(recordId)
    if seat then return TARGET_KIND.SEAT, seat end
    return nil, nil
end

---Facing correction in degrees for a bed type's pose (0 for anything else).
local function bedPoseYaw(bedType)
    return BED_POSE_YAW[bedType] or 0
end

---Idle animation group for any target kind.
local function idleAnimFor(kind, subType)
    if kind == TARGET_KIND.BED then return BED_ANIM[subType] end
    if kind == TARGET_KIND.MISC then return MISC_ANIM[subType] end
    return seatAnim[subType]
end

local function enterAnimFor(kind, subType)
    if kind == TARGET_KIND.BED then return BED_ENTER_ANIM[subType] end
    if kind == TARGET_KIND.MISC then return MISC_ENTER_ANIM[subType] end
    return SEAT_ENTER_ANIM[subType]
end

---One-shot played after the idle ends. nil means stand straight up.
local function exitAnimFor(kind, subType)
    if kind == TARGET_KIND.BED then return BED_EXIT_ANIM[subType] end
    if kind == TARGET_KIND.MISC then return MISC_EXIT_ANIM[subType] end
    return SEAT_EXIT_ANIM[subType]
end

return {
    SEAT_TYPE                = SEAT_TYPE,
    SEAT_ANIM                = seatAnim,
    SEATS                    = seatsByRecord,

    TARGET_KIND              = TARGET_KIND,
    buildAnimProfiles        = buildAnimProfiles,
    groupFallbacks           = groupFallbacks,
    poseDelta                = poseDelta,
    solverProfile            = solverProfile,
    solverSlot               = solverSlot,
    solverContract           = SOLVER_CONTRACT,

    BED_TYPE                 = BED_TYPE,
    BEDS_ENABLED             = BEDS_ENABLED,
    BED_ANIM                 = BED_ANIM,
    BEDS                     = bedsByRecord,
    getBedType               = getBedType,
    bedTypeForModel          = bedTypeForModel,
    bedPoseYaw               = bedPoseYaw,
    BED_POSE_YAW             = BED_POSE_YAW,
    isBed                    = isBed,
    bedPlacement             = bedPlacement,

    MISC_TYPE                = MISC_TYPE,
    MISC_ITEMS               = MISC_ITEMS,
    getMiscType              = getMiscType,
    isMiscItem               = isMiscItem,

    classify                 = classify,
    idleAnimFor              = idleAnimFor,
    enterAnimFor             = enterAnimFor,
    exitAnimFor              = exitAnimFor,
    SEAT_TYPE_PATTERNS       = SEAT_TYPE_PATTERNS,
    BLACKLIST                = BLACKLIST,
    SIT_PIVOT_OFFSET         = SIT_PIVOT_OFFSET,
    SIT_PIVOT_OFFSET_FALLBACK = SIT_PIVOT_OFFSET_FALLBACK,

    getSeatType    = getSeatType,
    isSittable     = isSittable,
    animForSeat    = animForSeat,
    pivotOffset    = pivotOffset,
    fallbackOffset = fallbackOffset,

    DEFAULTS = {
        CAMERA_OFFSET_ENABLED = true,
        FP_OFFSET_V           = 0,
        FP_OFFSET_H           = 0,
        TP_OFFSET_V           = -75,
        TP_OFFSET_H           = 0,
        DEBUG                 = false,
    },
}
