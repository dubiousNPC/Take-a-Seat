---@omw-context runtime
--[[
    sitAnim_shared.lua -- chair and animation profiles for Take a Seat

    Data only. No engine handlers, no state, no camera or animation calls --
    just the tables that say WHICH objects are seats, WHAT kind of seat they
    are, and WHICH animation group each kind plays.

    Split out of take_a_seat.lua so the profiles can be extended without
    touching the controller, and so other mods can read the same lists.

    OTHER MODS: require this file and read the exported tables. Nothing here
    mutates, so it is safe to hold a reference:

        local seats = require('scripts.take_a_seat.sitAnim_shared')
        local kind  = seats.getSeatType(obj.recordId)   -- "bench" | nil
        local group = kind and seats.SEAT_ANIM[kind]

    ADDING SEATS
      * A record from a plugin that may not be installed goes in
        MOD_SEAT_DATABASE under that plugin's filename. It is merged in at
        load only when the plugin is actually present, so an absent mod costs
        nothing and cannot pollute the lookup.
      * A vanilla record goes straight in BASE_SEATS.
      * Anything not listed anywhere still gets caught by SEAT_TYPE_PATTERNS,
        which is the fallback for third-party furniture nobody has profiled.

    Exact record IDs always beat patterns. Record names lie: three vanilla
    records are typed against their own names in the profile data this was
    built from, and pattern matching alone gets all three wrong.
]]

local core = require('openmw.core')

-- ---------------------------------------------------------------------------
-- SEAT TYPES
-- ---------------------------------------------------------------------------
-- Pose classification, not mesh category. Derived from the SeatType column of
-- the furnitureProfiles pack, plus CUSHION which that pack does not cover
-- (it profiles chairs, stools and benches; floor cushions are a separate
-- interaction with no seat plane).

local SEAT_TYPE = {
    BACKED_CHAIR      = "backed_chair",
    BENCH             = "bench",
    STOOL             = "stool",
    BARSTOOL          = "barstool",
    SINGLE_SEAT_BENCH = "single_seat_bench",
    CUSHION           = "cushion",
}
local T = SEAT_TYPE

-- ---------------------------------------------------------------------------
-- ANIMATION GROUPS
-- ---------------------------------------------------------------------------
-- One group per seat type. Every group needs matching start/stop text keys or
-- playBlended silently does nothing.

local SEAT_ANIM = {
    [T.BACKED_CHAIR]      = "dbssit5",
    [T.BENCH]             = "dbssit4",
    [T.STOOL]             = "dbssitting24",
    [T.BARSTOOL]          = "dbssit6",
    [T.SINGLE_SEAT_BENCH] = "dbssit4",
    [T.CUSHION]           = "rasit6",
    [T.THRONE]            = "dbssit8",
}

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
-- Merged at load only if the plugin is in the load order, so records from mods
-- you do not have never enter the lookup. Plugin keys are matched lowercase.

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
        ["ab_furn_demidstool"]           = T.BARSTOOL,  -- named stool, poses as a barstool
    },
}

-- ---------------------------------------------------------------------------
-- PATTERN FALLBACK
-- ---------------------------------------------------------------------------
-- For furniture nobody has profiled. ORDER IS SIGNIFICANT: these substrings
-- nest, so the most specific type must be tested first -- "barstool" contains
-- "stool", and "throne" is a backed chair. First match wins.
--
-- CUSHION has no patterns on purpose: "cushion" as a substring would also
-- catch OAAB's cushioned CHAIR, and the point of exact IDs is that they cannot
-- misfile anything. Floor cushions are listed explicitly or not at all.

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
-- Measured offset from a record's origin up to its seat plane. When a record
-- is listed here the controller skips its seat-surface probing entirely, which
-- is the single biggest latency saving available per record -- so adding
-- entries here is worth doing for furniture you use often.
--
-- To measure one: set DEBUG = true in take_a_seat.lua, sit on it, and read the
-- suggested value out of the console.

local SIT_PIVOT_OFFSET = {
    ["furn_de_p_chair_02"] = 1.2,
    ["ab_furn_demidchair"] = 1.2,
    ["furn_de_r_chair_03"] = 1.2,
}

-- Used when probing finds nothing and there is no calibration above. Matched
-- as substrings against the record id; `default` applies when none hit.
local SIT_PIVOT_OFFSET_FALLBACK = {
    ["furn_com_rm_bar"]      = 38,
    ["ab_furn_demidtable02"] = 38,
    ["furn_de_r_table_07"]   = 38,
    default                  = 26,
}

-- ---------------------------------------------------------------------------
-- RUNTIME MERGE
-- ---------------------------------------------------------------------------
-- Build the final lookup once at load. Plugin sections whose file is absent
-- are skipped, so an uninstalled mod's records never exist as far as the
-- controller is concerned.

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

-- Memoized: recordId is static per record, and this runs on every raycast hit
-- in the controller's resolve loops, so the pattern scan must not repeat per
-- ray. `false` is the cache sentinel for "not a seat" (nil would re-scan).
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

return {
    SEAT_TYPE                = SEAT_TYPE,
    SEAT_ANIM                = seatAnim,
    SEATS                    = seatsByRecord,
    SEAT_TYPE_PATTERNS       = SEAT_TYPE_PATTERNS,
    BLACKLIST                = BLACKLIST,
    SIT_PIVOT_OFFSET         = SIT_PIVOT_OFFSET,
    SIT_PIVOT_OFFSET_FALLBACK = SIT_PIVOT_OFFSET_FALLBACK,

    getSeatType    = getSeatType,
    isSittable     = isSittable,
    animForSeat    = animForSeat,
    pivotOffset    = pivotOffset,
    fallbackOffset = fallbackOffset,

    -- Defaults for take_a_seat's own settings. The FPV_experimental add-on
    -- registers and owns its settings separately.
    DEFAULTS = {
        CAMERA_OFFSET_ENABLED = true,
        FP_OFFSET_V           = 0,
        FP_OFFSET_H           = 0,
        TP_OFFSET_V           = -75,
        TP_OFFSET_H           = 0,
        DEBUG                 = false,
    },
}
