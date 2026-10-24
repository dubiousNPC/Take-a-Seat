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
-- A group a skeleton does not define plays nothing, silently. The beast
-- skeleton gets its chair transitions from xdbsTASsitTkna.kf, which carries
-- the tassit* groups, so the RA-set groups used by floor seating resolve to
-- their chair equivalents there rather than to nothing.
--
-- Checked per actor with animation.hasGroup at play time, not here: the same
-- install serves human, female and beast skeletons.
local GROUP_FALLBACKS = {
    rasitd1  = { "tassitd1" },
    rasitd2  = { "tassitd2", "tassitd1" },
    rasitu1  = { "tassitu1" },
    rasitu2  = { "tassitu2", "tassitu1" },
    rasitup1 = { "tassitu1" },
    tassitd2 = { "tassitd1" },
    tassitu2 = { "tassitu1" },
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
-- The authored solver roots are solved for the reference pose pcdbssit5, which
-- is dbssit5 (confirmed by the pack's author). Every seat type here plays a
-- different clip, so the obvious worry is that a root solved for one pose puts
-- the body somewhere else in another.
--
-- Measured, not assumed. tools/kf_root_offsets.py reads the root and pelvis
-- tracks straight out of the shipped .kf files. Across every seated clip this
-- mod plays -- dbssit2/4/5/6/8 (xdbssitting.kf), dbssitting24 (xSitting2.kf)
-- and rasit6 (xdbsRAsitting1.kf) -- Bip01 and Bip01 Pelvis have the SAME
-- translation (2.904, 0, 0) and the SAME rotation, to 0.000 units and 0.00
-- degrees. Morrowind animates bone rotations, not bone translations: these
-- poses first differ at the spine (26-59 degrees of lean), which is the
-- per-seat variety, not a placement error. The hips land in the same place
-- whichever clip plays, so pcdbssit5-solved roots are valid for all of them
-- and this table is empty because the correction measures zero.
--
-- If one SEAT TYPE ever sits high, low or fore/aft, the correction belongs
-- here, keyed by its animation group -- one entry fixes every record that uses
-- that clip. Per-record offsets are the wrong tool and the pack says so: check
-- for a double-applied provider or animation correction first.
--
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
-- Model-keyed authored geometry, generated from the solver pack. This is the
-- primary positioner; the raycast chain in take_a_seat.lua is the fallback for
-- models the pack does not cover.
local solver = require('scripts.take_a_seat.solver_profiles')

local SOLVER_CONTRACT = 3

-- A contract bump changes the meaning of root/yaw. Refusing to read it is the
-- documented behaviour, and silently misreading coordinates is the failure it
-- exists to prevent.
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

    -- `priority` takes either one value for every bone group or a table
    -- mapping bone group to priority (openmw.animation.playBlended). Split it,
    -- because the legs and the upper body want opposite things:
    --
    --   LEGS carry the pose. They must outrank what the engine plays by
    --   itself -- Movement, Jump, Hit -- or the seated legs are replaced by a
    --   walk cycle the moment anything nudges the player.
    --
    --   UPPER BODY should lose. A seated player still wants hit reactions, a
    --   drawn weapon, a torch, and the conversation gestures other mods play
    --   on the torso and arms. Procedural Chatter is the reference: it poses
    --   seated NPCs at PRIORITY.Movement and then plays gestures on bone mask
    --   14 (torso + both arms) at a higher priority, expecting the pose to
    --   yield there. A pose held at one high priority across all four groups
    --   blocks exactly that, which is what this mod did.
    --
    -- Bone groups left out of the table default to PRIORITY.Default, so all
    -- four are always named.
    local function split(legs, upper)
        return {
            [BG.LowerBody] = legs,
            [BG.Torso]     = upper,
            [BG.LeftArm]   = upper,
            [BG.RightArm]  = upper,
        }
    end

    -- Transitions outrank the idle on the legs: a stand-up is a leg movement
    -- and it is competing with locomotion the instant controls come back.
    -- Knockdown is the highest tier below Scripted, and Scripted is avoided
    -- deliberately -- it pauses every animation on the actor that is not also
    -- Scripted, which would freeze the very gestures the idle is making room
    -- for (RESEARCH 3.2).
    local TRANSITION_LEGS = P.Knockdown
    local TRANSITION_UPPER = P.Weapon
    local IDLE_LEGS = P.Weapon
    local IDLE_UPPER = P.Movement
    -- A prone body's legs must never walk, so they stay at the top; the upper
    -- body matches the seat idle so hits, weapons and torches still read.
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
