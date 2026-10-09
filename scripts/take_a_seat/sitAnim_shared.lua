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
    THRONE            = "dbssit8",
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
    -- BACKED_CHAIR = "dbssit5_enter",
    -- THRONE       = "dbssit8_enter",
}, "SEAT_ENTER_ANIM")

local SEAT_EXIT_ANIM = resolveByType({
    -- BACKED_CHAIR = "dbssit5_exit",
    -- THRONE       = "dbssit8_exit",
}, "SEAT_EXIT_ANIM")

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
    local P, B = anim.PRIORITY, anim.BLEND_MASK
    return {
        [TARGET_KIND.SEAT] = {
            -- Whole body, and everything else held still.
            idle  = { priority = P.Weapon, blendMask = B.All, loops = 0 },
            enter = { priority = P.Weapon, blendMask = B.All, loops = 0 },
            exit  = { priority = P.Weapon, blendMask = B.All, loops = 0 },
        },
        [TARGET_KIND.BED] = {
            idle  = { priority = P.Scripted, blendMask = B.All, loops = 0 },
            enter = { priority = P.Scripted, blendMask = B.All, loops = 0 },
            exit  = { priority = P.Scripted, blendMask = B.All, loops = 0 },
        },
        [TARGET_KIND.MISC] = {
            idle  = { priority = P.Weapon, blendMask = B.LowerBody, loops = 0 },
            enter = { priority = P.Weapon, blendMask = B.All, loops = 0 },
            exit  = { priority = P.Weapon, blendMask = B.All, loops = 0 },
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
    SINGLE  = "sleepT1",
    DOUBLE  = "sleepT2",
    BUNK    = "sleepT5",
    BEDROLL = "sleepT1",
    HAMMOCK = "sleepT6",
}, "BED_ANIM")

local BED_ENTER_ANIM = resolveBedByName({}, "sleeptTE1")
local BED_EXIT_ANIM  = resolveBedByName({}, "getup1")

local BEDS_ENABLED = true

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
}

-- ---------------------------------------------------------------------------
-- SEATS -- PER PLUGIN
-- ---------------------------------------------------------------------------

local MOD_SEAT_DATABASE = {
    ["tamriel_data.esm"] = {
        -- throne
        ["t_ayl_dngruin_f_throne_01"] = T.BACKED_CHAIR,
        ["t_ayl_dngruin_f_chair_01"]  = T.BACKED_CHAIR,
        ["t_ayl_dngruin_f_chair_02"]  = T.BACKED_CHAIR,

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

local function isBed(recordId)
    if not BEDS_ENABLED then return false end
    return getBedType(recordId) ~= nil
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

---@return string|nil kind, string|nil subType
local function classify(recordId)
    local misc = getMiscType(recordId)
    if misc then return TARGET_KIND.MISC, misc end
    if BEDS_ENABLED then
        local bed = getBedType(recordId)
        if bed then return TARGET_KIND.BED, bed end
    end
    local seat = getSeatType(recordId)
    if seat then return TARGET_KIND.SEAT, seat end
    return nil, nil
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

    BED_TYPE                 = BED_TYPE,
    BEDS_ENABLED             = BEDS_ENABLED,
    BED_ANIM                 = BED_ANIM,
    BEDS                     = bedsByRecord,
    getBedType               = getBedType,
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
