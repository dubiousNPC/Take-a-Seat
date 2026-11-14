---@omw-context none
--[[
    solver_profiles.lua -- GENERATED, do not edit by hand.

    Authored seating geometry from the ProceduralChatter solver
    profile pack, contract version 3. Regenerate with
    tools/gen_solver_profiles.py.

    KEYED BY MODEL, not by record id. A record uses a profile when its
    own record.model resolves to that path, which is why this covers
    furniture from mods this one has never heard of.

    `root` is the SOLVED ACTOR ROOT for the reference pose (pcdbssit5),
    in object-local game units. It is not a seat surface and not a
    cushion centre: there is no legacy -36 / -7 offset to apply on top.

        worldRoot = objectPosition + objectRotation * (root * scale)
        worldYaw  = objectYaw + rad(yaw)

    `yaw` is DEGREES relative to the object, 0 meaning object-local +Y.
    It already encodes which way a seated actor faces -- do not negate
    it and do not add 180 again.

    `anchor`/`poseDelta` are present on slots whose facing is not fixed
    (two_sided, free). anchor is the seat point with the pose offset
    removed, so a root for a chosen facing is rebuilt from it.

    BEDS (kind = 'sleep') use the SAME contract, with `bedType`
    in place of `seatType` and named slots: sleep_main, or
    sleep_left/sleep_right for a double and sleep_bottom/sleep_top
    for a bunk. Every bed profile is fixed-facing, so the facing
    chooser is never consulted for one.

    Their roots are solved for the reference pose (slee8),
    which this mod does not ship -- it plays sleept1/2/5/6. That
    costs nothing, and the reason is measured rather than assumed:
    tools/kf_root_offsets.py on animations/xbase_anim/xSleepT.kf
    reports Bip01 (6.264, 0.782, 2.328) and Bip01 Pelvis
    (2.904, 0, 0) for every sleept*/sleepte* group, the same
    translations the seated reference carries. Morrowind animates
    bone rotations, not bone translations, so POSE_DELTA is empty
    for beds exactly as it is for seats.

    Do NOT fold in the slee8 row from
    sdp/animationNormalizationOffsets.txt (W=15, D=25, H=15): that
    file is pose normalization for SDP's calibration UI and says
    in its own header not to use it for bed placement.
]]

local M = {}

M.contractVersion = 3

-- model -> profile
M.PROFILES = {
    ['meshes/f/active_de_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.4644, -0.0145, 19.9438 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -13.7116, 0.2278, -12.1049 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 15.1363, 0.4704, -19.2309 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.1368, 0.4716, 62.682 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 17.9889, -1.0885, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_05.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.2526, 28.763, 26.1405 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.2526, -31.237, 26.1405 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_06.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 17.6907, -30.0081, 21.2121 }, yaw = 270 },
            { id = 'sleep_right', root = { 17.6907, 29.9919, 21.2121 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_07.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.4677, 0.0747, 1.423 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_08.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 0.3936 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 0.3936 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_09.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 15.1823, 0.498, -23.4626 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.1829, 0.4992, 66.9137 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_10.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.1833, -1.0571, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_11.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.1833, -1.0571, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_12.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.1833, -1.0571, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_13.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.1833, -1.0571, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_14.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.1833, -1.0571, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_15.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.243, 28.7732, 26.1405 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.243, -31.2268, 26.1405 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_16.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.2433, 28.7652, 26.1405 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.2433, -31.2348, 26.1405 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_17.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9755, -0.2119, 19.9438 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_18.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9755, -0.2119, 19.9438 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_19.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9755, -0.2119, 19.9438 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_20.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.153, -29.9977, 21.2121 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.153, 30.0023, 21.2121 }, yaw = 270 },
        },
    },
    ['meshes/f/active_de_bed_21.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.3953, 0.0792, 1.4229 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_22.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.3953, 0.0792, 1.4507 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_23.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.3953, 0.0792, 1.4751 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_24.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.3953, 0.0791, 1.3725 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_25.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.3953, 0.0791, 1.3751 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_26.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 0.3936 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 0.3936 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_27.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 0.3936 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 0.3936 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_28.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -13.8535, 0.0162, -7.2411 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_29.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.2136, -0.0205, -26.7213 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bed_30.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.2327, -0.0205, -41.24 }, yaw = 90 },
        },
    },
    ['meshes/f/active_de_bedroll.nif'] = {
        kind = 'sleep',
        bedType = 'bedroll',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 9.5862, -0.1123, 3.995 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.3067, -2.2627, -0.8589 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_chieftains_chair.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, 47.9789, 24.841 }, yaw = 0 },
        },
    },
    ['meshes/f/furn_com_barstool.nif'] = {
        kind = 'sit',
        seatType = 'barstool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.0029, 4.6182, 20.8137 }, yaw = 180, anchor = { 0.0029, 0.0019, 20.8137 }, poseDelta = { 0, -4.6163, 0 } },
        },
    },
    ['meshes/f/furn_com_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.3237, 0.0698, -27.5262 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9248, 0.4081, 27.4912 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bed_05.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9248, 0.4081, 27.4912 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bed_06.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 20.2077, -29.9094, -26.9248 }, yaw = 270 },
            { id = 'sleep_right', root = { 20.2077, 30.0906, -26.9248 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bed_07.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9172, -29.5961, 25.8541 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9172, 30.4039, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.6667, 5.8968, 20.6706 }, yaw = 180, anchor = { 26.6667, 0, 20.6706 }, poseDelta = { 0, -5.8968, 0 } },
            { id = 'seat_b', root = { -26.6667, 5.8968, 20.6706 }, yaw = 180, anchor = { -26.6667, 0, 20.6706 }, poseDelta = { 0, -5.8968, 0 } },
        },
    },
    ['meshes/f/furn_com_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { 21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
            { id = 'seat_b', root = { -21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { -21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/f/furn_com_bunk_01.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_bunk_02.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/f/furn_com_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -2.8505, -9.8273 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_com_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 1.636, -0.0164, 13.9229 }, yaw = 90, anchor = { 0.0116, -0.0164, 13.9229 }, poseDelta = { 0, 1.6244, 0 } },
        },
    },
    ['meshes/f/furn_com_chair_03.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.0678, -1.2871, -4.9636 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_com_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 6.0786, 17.3034 }, yaw = 180, anchor = { 0, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/f/furn_com_stool_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.6379, 4.0691, 15.9639 }, yaw = 180, anchor = { 0.6379, 0, 15.9639 }, poseDelta = { 0, -4.0691, 0 } },
        },
    },
    ['meshes/f/furn_de_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.7279, 6.864, 20.7175 }, yaw = 180, anchor = { 26.7279, -0.0236, 20.7175 }, poseDelta = { 0, -6.8876, 0 } },
            { id = 'seat_b', root = { -26.7027, 6.864, 20.7175 }, yaw = 180, anchor = { -26.7027, -0.0236, 20.7175 }, poseDelta = { 0, -6.8876, 0 } },
        },
    },
    ['meshes/f/furn_de_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 7.7126, -0.0089, 17.2357 }, yaw = 90, anchor = { 0.0193, -0.0089, 17.2357 }, poseDelta = { 0, 7.6933, 0 } },
        },
    },
    ['meshes/f/furn_de_bench_03.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 27.3316, 5.8487, 20.4434 }, yaw = 180, anchor = { 27.3316, 0.4951, 20.4434 }, poseDelta = { 0, -5.3536, 0 } },
            { id = 'seat_b', root = { -27.6873, 5.8487, 20.4434 }, yaw = 180, anchor = { -27.6873, 0.4951, 20.4434 }, poseDelta = { 0, -5.3536, 0 } },
        },
    },
    ['meshes/f/furn_de_bench_04.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -0.0135, 7.087, 16.9637 }, yaw = 180, anchor = { -0.0135, 1.2561, 16.9637 }, poseDelta = { 0, -5.8308, 0 } },
        },
    },
    ['meshes/f/furn_de_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 3.854, -6.748, -4.2834 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_de_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.3067, -2.2627, -0.8589 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_de_chair_03.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.2065, -4.8823, -3.3198 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_de_ex_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.8947, -0.7543, 16.7272 }, yaw = 180, anchor = { 26.8947, 0.5022, 16.7272 }, poseDelta = { 0, 1.2565, 0 } },
            { id = 'seat_b', root = { -25.9127, -0.7543, 16.7272 }, yaw = 180, anchor = { -25.9127, 0.5022, 16.7272 }, poseDelta = { 0, 1.2565, 0 } },
        },
    },
    ['meshes/f/furn_de_ex_stool_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.3996, -0.7543, 16.7049 }, yaw = 180, anchor = { 0.3996, 0.2987, 16.7049 }, poseDelta = { 0, 1.053, 0 } },
        },
    },
    ['meshes/f/furn_de_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 1.5456, 20.8573 }, yaw = 180, anchor = { 0, 0, 20.8573 }, poseDelta = { 0, -1.5456, 0 } },
        },
    },
    ['meshes/f/furn_de_stool_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 3.5313, 18.2238 }, yaw = 180, anchor = { 0, 0, 18.2238 }, poseDelta = { 0, -3.5313, 0 } },
        },
    },
    ['meshes/f/furn_dwrv_bed00.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -0.3832, 14.0825, -31.0715 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_dwrv_bench00.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 22.6075, 7.7126, 23.3393 }, yaw = 180, anchor = { 22.6075, 0, 23.3393 }, poseDelta = { 0, -7.7126, 0 } },
            { id = 'seat_b', root = { -22.6075, 7.7126, 23.3393 }, yaw = 180, anchor = { -22.6075, 0, 23.3393 }, poseDelta = { 0, -7.7126, 0 } },
        },
    },
    ['meshes/f/furn_dwrv_bench10.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 7.7126, 0.01, 25.1508 }, yaw = 90, anchor = { 0, 0.01, 25.1508 }, poseDelta = { 0, 7.7126, 0 } },
        },
    },
    ['meshes/f/furn_dwrv_chair00.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1623, -5.2872, 8.9992 }, yaw = 180 },
        },
    },
    ['meshes/f/furn_dwrv_stool00.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 1.5456, 16.1208 }, yaw = 180, anchor = { 0, 0, 16.1208 }, poseDelta = { 0, -1.5456, 0 } },
        },
    },
    ['meshes/f/furn_dwrv_stool10.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, -0.3816, 16.6167 }, yaw = 180, anchor = { 0, 0, 16.6167 }, poseDelta = { 0, 0.3816, 0 } },
        },
    },
    ['meshes/f/furn_kneeling_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.0048, 5.4784, 3.6807 }, yaw = 180, anchor = { -0.0048, -0.0783, 3.6807 }, poseDelta = { 0, -5.5567, 0 } },
        },
    },
    ['meshes/f/furn_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 1.5456, 20.8573 }, yaw = 180, anchor = { 0, 0, 20.8573 }, poseDelta = { 0, -1.5456, 0 } },
        },
    },
    ['meshes/f/furn_throne_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.5176, -12.0424, 71.5188 }, yaw = 180 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed01a.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed01b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed01c.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed01d.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed02a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9203, -29.5911, 10.7625 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9203, 30.4089, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed02b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9203, -29.5911, 10.7625 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9203, 30.4089, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed02c.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9203, -29.5911, 10.7625 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9203, 30.4089, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed02d.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9203, -29.5911, 10.7625 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9203, 30.4089, 10.7625 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed03a.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.9294, 0.4142, 104.2715 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed03b.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.9294, 0.4142, 104.2715 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed03c.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.9294, 0.4142, 104.2715 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bed03d.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.9294, 0.4142, 10.7625 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.9294, 0.4142, 104.2715 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_bench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.729, 6.6855, 18.5224 }, yaw = 180, anchor = { 21.729, 0, 18.5224 }, poseDelta = { 0, -6.6855, 0 } },
            { id = 'seat_b', root = { -23.1033, 6.6855, 18.5224 }, yaw = 180, anchor = { -23.1033, 0, 18.5224 }, poseDelta = { 0, -6.6855, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_chair01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, 2.5438, 37.6204 }, yaw = 0 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_chair03a.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.5279, 7.0097, 31.7646 }, yaw = 180 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_chair03b.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.5279, 7.0097, 31.7646 }, yaw = 180 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_stool01a.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.835, 2.4413, 31.5296 }, yaw = 180, anchor = { 0.835, -3.5072, 31.5296 }, poseDelta = { 0, -5.9485, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_m_stool01b.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.835, 2.4413, 31.5296 }, yaw = 180, anchor = { 0.835, -3.5072, 31.5296 }, poseDelta = { 0, -5.9485, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed01a.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 10.2709, 0.1119, 36.0074 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed01b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 10.2709, 0.1119, 36.0074 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed01c.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 10.2709, 0.1119, 36.0074 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed02a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 10.1691, -30.0681, 36.1438 }, yaw = 270 },
            { id = 'sleep_right', root = { 10.1691, 29.9319, 36.1438 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed02b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 10.1691, -30.0681, 36.1438 }, yaw = 270 },
            { id = 'sleep_right', root = { 10.1691, 29.9319, 36.1438 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed02c.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 10.1691, -30.0681, 36.1438 }, yaw = 270 },
            { id = 'sleep_right', root = { 10.1691, 29.9319, 36.1438 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed03a.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 10.2551, 0.1119, 36.0074 }, yaw = 270 },
            { id = 'sleep_top', root = { 10.2709, 0.1119, 129.0229 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed03b.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 10.2551, 0.1119, 36.0074 }, yaw = 270 },
            { id = 'sleep_top', root = { 10.2709, 0.1119, 129.0229 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bed03c.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 10.2551, 0.1119, 36.0074 }, yaw = 270 },
            { id = 'sleep_top', root = { 10.2709, 0.1119, 129.0229 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_bench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.9732, 5.4859, 20.7472 }, yaw = 180, anchor = { 26.9732, 0.1877, 20.7472 }, poseDelta = { 0, -5.2982, 0 } },
            { id = 'seat_b', root = { -26.2347, 5.4859, 20.7472 }, yaw = 180, anchor = { -26.2347, 0.1877, 20.7472 }, poseDelta = { 0, -5.2982, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_chair01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.2825, -14.305, 31.8862 }, yaw = 180 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_stool01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.4463, -0.151, 31.1055 }, yaw = 90, anchor = { 0.6026, -0.151, 31.1055 }, poseDelta = { 0, -1.0489, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_p_stool02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.5777, 4.4494, 31.1492 }, yaw = 180, anchor = { 0.5777, 0.3447, 31.1492 }, poseDelta = { 0, -4.1046, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed01a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.8826, 28.6715, 29.5232 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.8826, -31.3285, 29.5232 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed01b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.8826, 28.6715, 29.5232 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.8826, -31.3285, 29.5232 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed01c.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.8826, 28.6715, 29.5232 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.8826, -31.3285, 29.5232 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed01d.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.8826, 28.6715, 29.5232 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.8826, -31.3285, 29.5232 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed02a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.1021, 28.8035, 29.9942 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.1021, -31.1965, 29.9942 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed02b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.1021, 28.8035, 29.9942 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.1021, -31.1965, 29.9942 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed02c.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.1021, 28.8035, 29.9942 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.1021, -31.1965, 29.9942 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed02d.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.1021, 28.8035, 29.9942 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.1021, -31.1965, 29.9942 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed03a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -15.6113, 29.7936, 41.8852 }, yaw = 90 },
            { id = 'sleep_right', root = { -15.6113, -30.2064, 41.8852 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed03b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -15.6113, 29.7936, 41.8852 }, yaw = 90 },
            { id = 'sleep_right', root = { -15.6113, -30.2064, 41.8852 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed03c.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -15.6113, 29.7936, 41.8852 }, yaw = 90 },
            { id = 'sleep_right', root = { -15.6113, -30.2064, 41.8852 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed03d.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -15.6113, 29.7936, 41.8852 }, yaw = 90 },
            { id = 'sleep_right', root = { -15.6113, -30.2064, 41.8852 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed04a.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -8.0728, -4.0857, 40.2211 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed04b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -8.0728, -4.0857, 40.2211 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed04c.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -8.0728, -4.0857, 40.2211 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed04d.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -8.0728, -4.0857, 40.2211 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed05a.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -7.2918, -3.8091, 39.6836 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed05b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -7.2918, -3.8091, 39.6836 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed05c.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -7.2918, -3.8091, 39.6836 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed05d.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -7.2918, -3.8091, 39.6836 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed06a.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -9.7432, -4.4482, 54.3158 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed06b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -9.7432, -4.4482, 54.3158 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed06c.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -9.7432, -4.4482, 54.3158 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bed06d.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -9.7432, -4.4482, 54.3158 }, yaw = 90 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_bench1.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -5.5149, 0, 37.5267 }, yaw = 90, anchor = { 0, 0, 37.5267 }, poseDelta = { 0, -5.5149, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_chair1.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 1.4079, 0, 39.3692 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_r_chair2.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -1.8351, 0, 31.4757 }, yaw = 270 },
        },
    },
    ['meshes/hf/f/hf_furn_rga_x_bench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 32.3494, 3.4873, 48.6966 }, yaw = 180, anchor = { 32.3494, 0, 48.6966 }, poseDelta = { 0, -3.4873, 0 } },
            { id = 'seat_b', root = { -32.3494, 3.4873, 48.6966 }, yaw = 180, anchor = { -32.3494, 0, 48.6966 }, poseDelta = { 0, -3.4873, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_x_bench02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 32.3494, 3.4873, 48.6966 }, yaw = 180, anchor = { 32.3494, 0, 48.6966 }, poseDelta = { 0, -3.4873, 0 } },
            { id = 'seat_b', root = { -32.3494, 3.4873, 48.6966 }, yaw = 180, anchor = { -32.3494, 0, 48.6966 }, poseDelta = { 0, -3.4873, 0 } },
        },
    },
    ['meshes/hf/f/hf_furn_rga_x_stool01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 3.4873, 48.6966 }, yaw = 180, anchor = { 0, 0, 48.6966 }, poseDelta = { 0, -3.4873, 0 } },
        },
    },
    ['meshes/hf/x/hf_ex_rh_flowbed_01a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 20.1199 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 20.1199 }, yaw = 270 },
        },
    },
    ['meshes/hf/x/hf_ex_rh_flowbed_01b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 20.1199 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 20.1199 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed01a.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.436, 0, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed01b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.436, 0, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed01c.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.436, 0, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed01d.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.436, 0, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed02a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14.4495, -30, 17.6861 }, yaw = 270 },
            { id = 'sleep_right', root = { 14.4495, 30, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed02b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14.4495, -30, 17.6861 }, yaw = 270 },
            { id = 'sleep_right', root = { 14.4495, 30, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed02c.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14.4495, -30, 17.6861 }, yaw = 270 },
            { id = 'sleep_right', root = { 14.4495, 30, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed02d.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14.4495, -30, 17.6861 }, yaw = 270 },
            { id = 'sleep_right', root = { 14.4495, 30, 17.6861 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed03a.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 14.436, 0, 17.6861 }, yaw = 270 },
            { id = 'sleep_top', root = { 14.436, 0, 100.6198 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed03b.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 14.436, 0, 17.6861 }, yaw = 270 },
            { id = 'sleep_top', root = { 14.436, 0, 100.6198 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed03c.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 14.436, 0, 17.6861 }, yaw = 270 },
            { id = 'sleep_top', root = { 14.436, 0, 100.6198 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bed03d.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 14.436, 0, 17.6861 }, yaw = 270 },
            { id = 'sleep_top', root = { 14.436, 0, 100.6198 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0, 4.2342, 30.1226 }, yaw = 180, anchor = { 0, 0, 30.1226 }, poseDelta = { 0, -4.2342, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_bench02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 28.7598, 4.2342, 30.1226 }, yaw = 180, anchor = { 28.7598, 0, 30.1226 }, poseDelta = { 0, -4.2342, 0 } },
            { id = 'seat_b', root = { -28.7478, 4.2342, 30.1226 }, yaw = 180, anchor = { -28.7478, 0, 30.1226 }, poseDelta = { 0, -4.2342, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_chair01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.0024, -2.7378, 32.2725 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_chair02a.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1051, -2.7378, 33.9315 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_chair02b.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1051, -2.7378, 33.9315 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_chair02c.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1051, -2.7378, 33.9315 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_chair02d.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1051, -2.7378, 33.9315 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_m_stool01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, -4.0382, 33.3978 }, yaw = 180, anchor = { 0, 0, 33.3978 }, poseDelta = { 0, 4.0382, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed1.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.8109, 0.2086, 53.258 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed2.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.8109, 0.2086, 53.258 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed3.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.8109, 0.2086, 53.258 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed4.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 12.7735, -29.7549, 44.8629 }, yaw = 270 },
            { id = 'sleep_right', root = { 12.7735, 30.2451, 44.8629 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed5.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 12.7735, -29.7549, 44.8629 }, yaw = 270 },
            { id = 'sleep_right', root = { 12.7735, 30.2451, 44.8629 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed6.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 12.7735, -29.7549, 44.8629 }, yaw = 270 },
            { id = 'sleep_right', root = { 12.7735, 30.2451, 44.8629 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed7.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 11.7875, -1.5188, 53.258 }, yaw = 270 },
            { id = 'sleep_top', root = { 11.1091, -1.7049, 143.3444 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed8.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 11.7875, -1.5188, 53.258 }, yaw = 270 },
            { id = 'sleep_top', root = { 10.5476, -1.6854, 143.3444 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bed9.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 11.7875, -1.5188, 53.258 }, yaw = 270 },
            { id = 'sleep_top', root = { 10.5888, -1.6818, 143.3444 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bench1.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -1.2046, -3.121, 36.798 }, yaw = 180, anchor = { -1.2046, -0.4114, 36.798 }, poseDelta = { 0, 2.7096, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bench2.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'fixed',
        slots = {
            { id = 'seat_a', root = { -0.116, -2.3224, 36.3727 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_bstool.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.1659, 4.1815, 48.0741 }, yaw = 180, anchor = { -0.1659, -0.0005, 48.0741 }, poseDelta = { 0, -4.182, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_chair1.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.0827, -4.4235, 34.1937 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_chair2.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -2.323, 35.5577 }, yaw = 180 },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_stool1.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.4341, -0.2055, 34.1937 }, yaw = 90, anchor = { -0.161, -0.2055, 34.1937 }, poseDelta = { 0, -0.2731, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_bre_p_stool2.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 2.5906, 0, 35.5509 }, yaw = 90, anchor = { 0, 0, 35.5509 }, poseDelta = { 0, 2.5906, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_ex_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.8947, -0.7543, 16.7272 }, yaw = 180, anchor = { 26.8947, 0.5022, 16.7272 }, poseDelta = { 0, 1.2565, 0 } },
            { id = 'seat_b', root = { -25.9127, -0.7543, 16.7272 }, yaw = 180, anchor = { -25.9127, 0.5022, 16.7272 }, poseDelta = { 0, 1.2565, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_ex_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.3996, -0.7543, 16.7049 }, yaw = 180, anchor = { 0.3996, 0.2987, 16.7049 }, poseDelta = { 0, 1.053, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_wi_barstool01.nif'] = {
        kind = 'sit',
        seatType = 'barstool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -1.894, 0.2519, 21.858 }, yaw = 90, anchor = { 0.1319, 0.2519, 21.858 }, poseDelta = { 0, -2.026, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_01a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_01b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_02a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_02b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_03a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_03b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_04a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_04b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_05a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_05b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_06a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_06b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_07a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_07b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_08a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.0194, 29.9999, 16.2523 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.0194, -30.0001, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bed_08b.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -14.471, 0, 16.2523 }, yaw = 90 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 9.1568, -0.0592, 17.86 }, yaw = 90, anchor = { 0, -0.0592, 17.86 }, poseDelta = { 0, 9.1568, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_wi_bench02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 9.1568, -24.2704, 17.86 }, yaw = 90, anchor = { 0, -24.2704, 17.86 }, poseDelta = { 0, 9.1568, 0 } },
            { id = 'seat_b', root = { 9.1568, 24.3352, 17.86 }, yaw = 90, anchor = { 0, 24.3352, 17.86 }, poseDelta = { 0, 9.1568, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_wi_chair01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 25.2661, 0, 36.4248 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_chair02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 25.2661, 0, 36.4248 }, yaw = 270 },
        },
    },
    ['meshes/hr/f/hr_furn_wi_stool01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 4.856, 12.507 }, yaw = 180, anchor = { 0, 0.0158, 12.507 }, poseDelta = { 0, -4.8402, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_wi_stool02a.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.0282, 2.7826, 16.1195 }, yaw = 180, anchor = { -0.0282, 0, 16.1195 }, poseDelta = { 0, -2.7826, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_wi_stool02b.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 17.3495, 0, 24.438 }, yaw = 90, anchor = { -0.0199, 0, 24.438 }, poseDelta = { 0, 17.3694, 0 } },
        },
    },
    ['meshes/hr/f/hr_furn_wi_stool03.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 6.6627, 0.0814, 3.4237 }, yaw = 90, anchor = { 0.0192, 0.0814, 3.4237 }, poseDelta = { 0, 6.6435, 0 } },
        },
    },
    ['meshes/l/furn_de_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.3067, -2.2627, -0.8589 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/com_m_bed_d_brown.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9172, -29.5961, 18.2512 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9172, 30.4039, 18.2512 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_m_bed_d_red.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9172, -29.5961, 18.2512 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9172, 30.4039, 18.2512 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_m_bed_s_brown.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_m_chair02fold.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 10.4499, -0.0543, 24.3779 }, yaw = 90, anchor = { -0.1944, -0.0543, 24.3779 }, poseDelta = { 0, 10.6443, 0 } },
        },
    },
    ['meshes/oaab/u/com_p_bed_d_01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 16.6946, -29.5908, 20.7788 }, yaw = 270 },
            { id = 'sleep_right', root = { 16.6946, 30.4092, 20.7788 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_p_bed_d_02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 16.6946, -29.5908, 20.7788 }, yaw = 270 },
            { id = 'sleep_right', root = { 16.6946, 30.4092, 20.7788 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_p_loftbed.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.7586, -0.102, 87.9702 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_r_barstool.nif'] = {
        kind = 'sit',
        seatType = 'barstool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.0029, 4.6182, 20.8137 }, yaw = 180, anchor = { 0.0029, 0.0019, 20.8137 }, poseDelta = { 0, -4.6163, 0 } },
        },
    },
    ['meshes/oaab/u/com_r_bed_d2_blue.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 20.7651, -29.9885, 23.287 }, yaw = 270 },
            { id = 'sleep_right', root = { 20.7651, 30.0115, 23.287 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_r_bed_d2_red.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 20.7648, -29.9885, 23.5838 }, yaw = 270 },
            { id = 'sleep_right', root = { 20.7648, 30.0115, 23.5838 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_r_bed_d_red.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 86.1697 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 86.1697 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_r_bed_s2_blue.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.8969, -0.009, 23.8803 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_r_bed_s2_red.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.8969, -0.009, 23.8803 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_r_bed_s_red.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14, 0, 86.1697 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/com_r_bench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { 21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
            { id = 'seat_b', root = { -21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { -21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/oaab/u/com_r_prayerstool.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.0086, 4.0851, 3.6807 }, yaw = 180, anchor = { -0.0086, -0.0546, 3.6807 }, poseDelta = { 0, -4.1397, 0 } },
        },
    },
    ['meshes/oaab/u/com_rm_footstool.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -20.0101, 20.1337 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/comcookbench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0.1889, 3.5523, 32.9664 }, yaw = 180, anchor = { 0.1889, -0.003, 32.9664 }, poseDelta = { 0, -3.5552, 0 } },
        },
    },
    ['meshes/oaab/u/complnbedstraw.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 11.1831, 0.2191, 7.892 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/comrchcnpybed_bludwn.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 203.8394 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 203.8394 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/comrchcnpybed_bluup.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 203.8394 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 203.8394 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/comrchcnpybed_crown.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 232.1682 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 232.1682 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/comrchcnpybed_reddwn.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 203.8394 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 203.8394 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/comrchcnpybed_redup.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 203.8394 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 203.8394 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/comrchpraybench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0, 5.2245, 9.5743 }, yaw = 180, anchor = { 0, 0, 9.5743 }, poseDelta = { 0, -5.2245, 0 } },
        },
    },
    ['meshes/oaab/u/daebench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'fixed',
        slots = {
            { id = 'seat_a', root = { 26.0405, -3.925, 12.5112 }, yaw = 180 },
            { id = 'seat_b', root = { -26.0405, -3.925, 12.5112 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/daechair01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, 0.8971, 3.3107 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/de_bench_03.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 27.3098, 5.8487, 19.2218 }, yaw = 180, anchor = { 27.3098, 0.4954, 19.2218 }, poseDelta = { 0, -5.3533, 0 } },
            { id = 'seat_b', root = { -27.709, 5.8487, 19.2218 }, yaw = 180, anchor = { -27.709, 0.4954, 19.2218 }, poseDelta = { 0, -5.3533, 0 } },
        },
    },
    ['meshes/oaab/u/de_bench_04.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -0.0112, 7.087, 16.9706 }, yaw = 180, anchor = { -0.0112, 1.2561, 16.9706 }, poseDelta = { 0, -5.8309, 0 } },
        },
    },
    ['meshes/oaab/u/de_ex_chair.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 6.9097, 2.6721, 16.8917 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/de_p_bed_b_red.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 15.1823, 0.498, -23.4626 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.1829, 0.4992, 66.9137 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_p_bed_d_blue.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.2526, 28.763, 18.9044 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.2526, -31.237, 18.9044 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/de_p_bed_d_brown.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.2526, 28.763, 18.9044 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.2526, -31.237, 18.9044 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/de_p_bedsinglegreen.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.1833, -1.0571, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_r_bed_d2_blue.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 17.6924, -30.0108, 21.3044 }, yaw = 270 },
            { id = 'sleep_right', root = { 17.6924, 29.9892, 21.3044 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_r_bed_d2_green.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 17.6907, -30.0081, 21.2121 }, yaw = 270 },
            { id = 'sleep_right', root = { 17.6907, 29.9919, 21.2121 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_r_bed_d_blue.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 2.5207 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 2.5207 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/de_r_prayerstool.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 6.3925, 3.8807 }, yaw = 180, anchor = { -0.0095, -0.0836, 3.8807 }, poseDelta = { -0.0095, -6.4761, 0 } },
        },
    },
    ['meshes/oaab/u/de_rm_barstool.nif'] = {
        kind = 'sit',
        seatType = 'barstool',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 1.7291, -0.1871, 20.7543 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_b01.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 14.8493, -0.0004, -13.2013 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.6718, -0.005, 74.4447 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_b02.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 14.8493, -0.0004, -13.2013 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.6718, -0.005, 74.4447 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_b03.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 14.8493, -0.0004, -13.2013 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.6718, -0.005, 74.4447 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_d01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.1018, -30.0015, 32.4889 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.1018, 29.9985, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_d02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.1018, -30.0015, 32.4889 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.1018, 29.9985, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_d03.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.1019, -30.0015, 10.798 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.1019, 29.9985, 10.798 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_d04.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.1019, -30.0015, 10.798 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.1019, 29.9985, 10.798 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_d05.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.1018, -30.0015, 32.4889 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.1018, 29.9985, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_s01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.9643, -0.0008, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_s02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.9643, -0.0008, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_s03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.9643, -0.0008, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_s04.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.9643, -0.0008, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bed_s05.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14.9643, -0.0008, 32.4889 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/de_rm_bench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 24.1291, 6.1923, 22.6514 }, yaw = 180, anchor = { 24.1291, -0.6322, 22.6514 }, poseDelta = { 0, -6.8245, 0 } },
            { id = 'seat_b', root = { -24.6713, 6.1923, 22.6514 }, yaw = 180, anchor = { -24.6713, -0.6322, 22.6514 }, poseDelta = { 0, -6.8245, 0 } },
        },
    },
    ['meshes/oaab/u/de_rm_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -0.2711, 6.1923, 22.6514 }, yaw = 180, anchor = { -0.2711, -0.6322, 22.6514 }, poseDelta = { 0, -6.8245, 0 } },
        },
    },
    ['meshes/oaab/u/de_rm_chair01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.8042, 0.704, 0.93 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/de_rm_stool.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.5167, 0.7441, 20.6187 }, yaw = 180, anchor = { -0.5167, -0.7304, 20.6187 }, poseDelta = { 0, -1.4746, 0 } },
        },
    },
    ['meshes/oaab/u/deexworkbench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'fixed',
        slots = {
            { id = 'seat_a', root = { 34.4627, -28.2727, 31.5733 }, yaw = 180 },
            { id = 'seat_b', root = { -32.3813, -28.2727, 31.5733 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/deplnbedloft01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 15.1829, 0.4992, 66.9137 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/deplnbedloft03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 15.1829, 0.4992, 66.9137 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/deplnbedloft09.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 15.1829, 0.4992, 66.9137 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/deplnhammockrug01.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4264, 0.0183, -9.857 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/deplnhammockrug02.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4264, 0.0183, -9.857 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/deplnhammockrug03.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4264, 0.0183, -9.857 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/deplnhammockrug04.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4264, 0.0183, -9.857 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/deplnhammockrug05.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4264, 0.0183, -9.857 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/derchhammockrug01.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.2037, 0.1588, -10.8455 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/derchhammockrug02.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.2037, 0.1588, -10.8455 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/derchhammockrug03.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.2037, 0.1588, -10.8455 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/derchhammockrug04.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.2037, 0.1588, -10.8455 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/derchhammockrug05.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.2037, 0.1588, -10.8455 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/dk_6th_chair3.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -7.3464, -12.7735 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/dk_6th_pray_bench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0, 9.3326, -0.5634 }, yaw = 180, anchor = { 0, 0, -0.5634 }, poseDelta = { 0, -9.3326, 0 } },
        },
    },
    ['meshes/oaab/u/dwrvstooltall.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, -0.3816, 35.3864 }, yaw = 180, anchor = { 0, 0, 35.3864 }, poseDelta = { 0, 0.3816, 0 } },
        },
    },
    ['meshes/oaab/u/hammocklongrug01.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4889, 0.0001, -18.2632 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/hammocklongrug02.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4889, 0.0001, -18.2632 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/hammocklongrug03.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4889, 0.0001, -18.2632 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/hammocklongrug04.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4889, 0.0001, -18.2632 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/hammocklongrug05.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -15.4889, 0.0001, -18.2632 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/hammockshortrug01.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.9813, 0.0851, -15.627 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/hammockshortrug02.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.9813, 0.0851, -15.627 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/hammockshortrug03.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.9813, 0.0851, -15.627 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/hammockshortrug04.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.9813, 0.0851, -15.627 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/hammockshortrug05.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.9813, 0.0851, -15.627 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/prisonbed.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -13.5656, -38.9406, 10.9187 }, yaw = 90 },
        },
    },
    ['meshes/oaab/u/rem_nord_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'fixed',
        slots = {
            { id = 'seat_a', root = { 28.2603, 3.339, 25.3214 }, yaw = 180 },
            { id = 'seat_b', root = { -28.1112, 3.339, 25.3214 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/roughbedstraw.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -0.4572, 13.5833, 16.6436 }, yaw = 180 },
        },
    },
    ['meshes/oaab/u/roughhammock.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 19.4496, 0.1738, 51.5713 }, yaw = 270 },
        },
    },
    ['meshes/oaab/u/strawbed.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 2.0071, -9.8731, 12.037 }, yaw = 180 },
        },
    },
    ['meshes/pc/d/pc_in_ar_bed_01d.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 0, 14, -66.2365 }, yaw = 180 },
            { id = 'sleep_top', root = { 0, 14.0211, -16.4635 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_active_ex_bedroll.nif'] = {
        kind = 'sleep',
        bedType = 'bedroll',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.22, -0.0104, 3.8313 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_f_anvil_throne_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -2.1726, -6.4207, 42.045 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_f_anvil_throne_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -1.8509, -6.4207, 42.045 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_f_com_m_chair_brown.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -0.8368, -2.3737 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_f_com_m_chair_green.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -0.8368, -2.3737 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_f_com_m_chair_grey.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -0.8368, -2.3737 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_f_com_r_bedcpy01a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.2919, 30.0405, 58.1435 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.2919, -29.9595, 58.1435 }, yaw = 90 },
        },
    },
    ['meshes/pc/f/pc_f_com_r_bedcpy01b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.7081, -29.9595, 58.1435 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.7081, 30.0405, 58.1435 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_f_com_r_bedcpy02a.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -14.2919, 30.0405, 58.1435 }, yaw = 90 },
            { id = 'sleep_right', root = { -14.2919, -29.9595, 58.1435 }, yaw = 90 },
        },
    },
    ['meshes/pc/f/pc_f_com_r_bedcpy02b.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.7081, -29.9595, 58.1435 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.7081, 30.0405, 58.1435 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_f_com_r_praybench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0, 5.2245, 9.5743 }, yaw = 180, anchor = { 0, 0, 9.5743 }, poseDelta = { 0, -5.2245, 0 } },
        },
    },
    ['meshes/pc/f/pc_f_sutch_throne_uni.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -11.5326, -52.3913, 52.1878 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_furn_ar_throne_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -4.2173, 29.8433 }, yaw = 0 },
        },
    },
    ['meshes/pc/f/pc_furn_com_bunk_02.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_com_bunk_03.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_com_bunk_04.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_com_bunk_05.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_com_bunk_06.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_com_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -10.3706, 7.5546 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_furn_com_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -10.3706, 7.5546 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_furn_com_chair_03.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -10.3706, 7.5546 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_furn_com_chair_04.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -10.3706, 7.5546 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_furn_com_chair_05.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -10.3706, 7.5546 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_furn_com_r_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { 21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
            { id = 'seat_b', root = { -21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { -21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/pc/f/pc_furn_com_r_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { 21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
            { id = 'seat_b', root = { -21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { -21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/pc/f/pc_furn_ex_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.7147, -0.7543, 16.6991 }, yaw = 180, anchor = { 26.7147, 0.4844, 16.6991 }, poseDelta = { 0, 1.2387, 0 } },
            { id = 'seat_b', root = { -26.0927, -0.7543, 16.6991 }, yaw = 180, anchor = { -26.0927, 0.4844, 16.6991 }, poseDelta = { 0, 1.2387, 0 } },
        },
    },
    ['meshes/pc/f/pc_furn_ex_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.3989, -0.7543, 16.7049 }, yaw = 180, anchor = { 0.3989, 0.3155, 16.7049 }, poseDelta = { 0, 1.0698, 0 } },
        },
    },
    ['meshes/pc/f/pc_furn_impr_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 20.1763, -0.0304, 41.6882 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_impr_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 19.5683, -0.0313, -5.2297 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_impr_bunk_01.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { -14.9792, 0, 8.0425 }, yaw = 90 },
            { id = 'sleep_top', root = { -14.9792, 0, 102.976 }, yaw = 90 },
        },
    },
    ['meshes/pc/f/pc_furn_impr_bunk_02.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 12.6443, -0.2209, 8.0425 }, yaw = 270 },
            { id = 'sleep_top', root = { 12.5753, -0.2322, 117.0066 }, yaw = 270 },
        },
    },
    ['meshes/pc/f/pc_furn_r_chair_h_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -10.3706, 7.5546 }, yaw = 180 },
        },
    },
    ['meshes/pc/f/pc_furn_r_chair_p_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, 2.4722, -6.1398 }, yaw = 180 },
        },
    },
    ['meshes/pc/i/pc_in_ar_bed.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -8.2032, 29.0033, -1.1442 }, yaw = 90 },
            { id = 'sleep_right', root = { -8.2032, -30.9967, -1.1442 }, yaw = 90 },
        },
    },
    ['meshes/pc/i/pc_in_ar_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14, 0.0056, -10.6814 }, yaw = 270 },
        },
    },
    ['meshes/pc/i/pc_in_ar_bench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 30.1383, -0.4626, -1.5 }, yaw = 180, anchor = { 30.1383, 0.0236, -1.5 }, poseDelta = { 0, 0.4862, 0 } },
            { id = 'seat_b', root = { -30.1383, -0.4626, -1.5 }, yaw = 180, anchor = { -30.1383, 0.0236, -1.5 }, poseDelta = { 0, 0.4862, 0 } },
        },
    },
    ['meshes/pc/i/pc_in_ar_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 22, 3.8351, 30.5 }, yaw = 180, anchor = { 22, 0, 30.5 }, poseDelta = { 0, -3.8351, 0 } },
            { id = 'seat_b', root = { -22, 3.8351, 30.5 }, yaw = 180, anchor = { -22, 0, 30.5 }, poseDelta = { 0, -3.8351, 0 } },
        },
    },
    ['meshes/pc/i/pc_in_ar_bench_r01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 12.7504, -0.4626, -1.5 }, yaw = 180, anchor = { 12.7504, 0.2593, -1.5 }, poseDelta = { 0, 0.7219, 0 } },
            { id = 'seat_b', root = { -47.5263, -0.4626, -1.5 }, yaw = 180, anchor = { -47.5263, 0.2593, -1.5 }, poseDelta = { 0, 0.7219, 0 } },
        },
    },
    ['meshes/pc/i/pc_in_ar_bench_r02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'fixed',
        slots = {
            { id = 'seat_a', root = { 12.5163, 0.6118, 14.5439 }, yaw = 270 },
        },
    },
    ['meshes/pc/i/pc_in_ar_bench_r03.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'fixed',
        slots = {
            { id = 'seat_a', root = { -22.9772, 0.473, 14.5056 }, yaw = 90 },
        },
    },
    ['meshes/pc/i/pc_in_ar_benchbrk_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 25.4937, 3.8351, 30.5 }, yaw = 180, anchor = { 25.4937, 2.3762, 30.5 }, poseDelta = { 0, -1.4589, 0 } },
            { id = 'seat_b', root = { -18.5063, 3.8351, 30.5 }, yaw = 180, anchor = { -18.5063, 2.3762, 30.5 }, poseDelta = { 0, -1.4589, 0 } },
        },
    },
    ['meshes/pc/i/pc_in_ar_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -3.5257, -0.0136, -122.0158 }, yaw = 90 },
        },
    },
    ['meshes/pc/i/pc_in_ar_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, 9.807, 63.4023 }, yaw = 180 },
        },
    },
    ['meshes/pi/f/pi_furn_ca_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -13.7244, -38.0797, 10.8323 }, yaw = 90 },
        },
    },
    ['meshes/pi/f/pi_furn_ca_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -3.7327, 7.3944, 15.5804 }, yaw = 180, anchor = { -3.7327, 1.8529, 15.5804 }, poseDelta = { 0, -5.5415, 0 } },
        },
    },
    ['meshes/pi/f/pi_furn_ca_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -1.2423, 5.7227, 16.7048 }, yaw = 180, anchor = { -1.2423, -0.0246, 16.7048 }, poseDelta = { 0, -5.7473, 0 } },
        },
    },
    ['meshes/pi/f/tsa_furn_bed.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 29.9942, 13.3942, 48.747 }, yaw = 180 },
            { id = 'sleep_right', root = { -30.0058, 13.3942, 48.747 }, yaw = 180 },
        },
    },
    ['meshes/pi/f/tsa_furn_chair.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 16.2258, -0.0018, 76.3179 }, yaw = 270 },
        },
    },
    ['meshes/pi/f/tsa_furn_stool.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.0071, 1.4058, 61.2019 }, yaw = 180, anchor = { -0.0071, -0.0018, 61.2019 }, poseDelta = { 0, -1.4076, 0 } },
        },
    },
    ['meshes/pi/f/yn_furnm_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 0.0008, -24.3868, 36.9331 }, yaw = 0 },
        },
    },
    ['meshes/pi/f/yn_furnm_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -30.9895, -25.1957, 36.6133 }, yaw = 0 },
            { id = 'sleep_right', root = { 29.0105, -25.1957, 36.6133 }, yaw = 0 },
        },
    },
    ['meshes/pi/f/yn_furnm_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 4.5674, -31.6339, 43.1532 }, yaw = 90, anchor = { 0, -31.6339, 43.1532 }, poseDelta = { 0, 4.5674, 0 } },
            { id = 'seat_b', root = { 4.5674, 31.6339, 43.1532 }, yaw = 90, anchor = { 0, 31.6339, 43.1532 }, poseDelta = { 0, 4.5674, 0 } },
        },
    },
    ['meshes/pi/f/yn_furnm_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 4.5675, -0.4621, 35.9691 }, yaw = 90, anchor = { 0, -0.4621, 35.9691 }, poseDelta = { 0, 4.5674, 0 } },
        },
    },
    ['meshes/pi/f/yn_furnm_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 4.5675, 0.3195, 33.4559 }, yaw = 90 },
        },
    },
    ['meshes/pi/f/yn_furnm_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 4.5675, 0, 33.4559 }, yaw = 90 },
        },
    },
    ['meshes/pi/f/yn_furnm_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 3.6153, -0.0097, 33.4559 }, yaw = 90, anchor = { 0.513, -0.0097, 33.4559 }, poseDelta = { 0, 3.1024, 0 } },
        },
    },
    ['meshes/pi/f/yn_furnp_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 0.0122, 13.6119, 42.5487 }, yaw = 180 },
        },
    },
    ['meshes/pi/f/yn_furnp_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -29.9972, -13.3106, 43.3191 }, yaw = 0 },
            { id = 'sleep_right', root = { 30.0028, -13.3106, 43.3191 }, yaw = 0 },
        },
    },
    ['meshes/pi/f/yn_furnp_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 4.4668, -30.8412, 35.2403 }, yaw = 90, anchor = { -0.0029, -30.8412, 35.2403 }, poseDelta = { 0, 4.4697, 0 } },
            { id = 'seat_b', root = { 4.4668, 30.8677, 35.2403 }, yaw = 90, anchor = { -0.0029, 30.8677, 35.2403 }, poseDelta = { 0, 4.4697, 0 } },
        },
    },
    ['meshes/pi/f/yn_furnp_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 1.2799, -3.8319, 23.2693 }, yaw = 180 },
        },
    },
    ['meshes/pi/f/yn_furnp_hammock_01.nif'] = {
        kind = 'sleep',
        bedType = 'hammock',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -0.3815, -4.2161, 37.4073 }, yaw = 0 },
        },
    },
    ['meshes/pi/f/yn_furnp_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 1.1443, 37.7805 }, yaw = 180, anchor = { 0, 0, 37.7805 }, poseDelta = { 0, -1.1443, 0 } },
        },
    },
    ['meshes/pi/f/yn_furnp_stool_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 6.4795, 2.3418, 30.5062 }, yaw = 90, anchor = { 0.0696, 2.3418, 30.5062 }, poseDelta = { 0, 6.4098, 0 } },
        },
    },
    ['meshes/sky/f/sky_act_com_bunk_01.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 13.7569, -0.1026, -28.8382 }, yaw = 270 },
            { id = 'sleep_top', root = { 13.7586, -0.102, 70.0288 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_bedroll.nif'] = {
        kind = 'sleep',
        bedType = 'bedroll',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 12.22, -0.0104, 3.8313 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_bedst_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 16.2042, -12.0642, 8.5546 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9172, -29.5961, 25.8541 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9172, 30.4039, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9248, 0.4081, 27.4912 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_05.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9248, 0.4081, 27.4912 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_06.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 20.0304, 0.0859, -22.2113 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_07.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 20.0304, 0.0859, -22.2113 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_c_bed_08.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 35.2423, -0.1586, -23.4603 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_n_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 20.0304, 0.0859, -22.2113 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_n_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 20.0304, 0.0859, -22.2113 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_n_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 35.2423, -0.1586, -23.4603 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_n_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 22.723, -29.8891, -19.9822 }, yaw = 270 },
            { id = 'sleep_right', root = { 22.723, 30.1109, -19.9822 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_act_furn_n_bed_05.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 22.723, -29.8891, -19.9822 }, yaw = 270 },
            { id = 'sleep_right', root = { 22.723, 30.1109, -19.9822 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_furn_alt_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -30, -17.0117, 27.591 }, yaw = 0 },
            { id = 'sleep_right', root = { 30, -17.0117, 27.591 }, yaw = 0 },
        },
    },
    ['meshes/sky/f/sky_furn_alt_seat_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 1.5061, -22.0324, -1.5 }, yaw = 180, anchor = { 1.5061, 9.1054, -1.5 }, poseDelta = { 0, 31.1378, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_alt_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 6.5977, 42.5624 }, yaw = 180, anchor = { 0, 1.6036, 42.5624 }, poseDelta = { 0, -4.9941, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_01_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.6667, 5.8968, 20.6706 }, yaw = 180, anchor = { 26.6667, 0, 20.6706 }, poseDelta = { 0, -5.8968, 0 } },
            { id = 'seat_b', root = { -26.6667, 5.8968, 20.6706 }, yaw = 180, anchor = { -26.6667, 0, 20.6706 }, poseDelta = { 0, -5.8968, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_01_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { 21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
            { id = 'seat_b', root = { -21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { -21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_01_03.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.7279, 6.864, 20.7175 }, yaw = 180, anchor = { 26.7279, -0.0236, 20.7175 }, poseDelta = { 0, -6.8876, 0 } },
            { id = 'seat_b', root = { -26.7027, 6.864, 20.7175 }, yaw = 180, anchor = { -26.7027, -0.0236, 20.7175 }, poseDelta = { 0, -6.8876, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_01_04.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 7.7126, -0.0089, 17.2357 }, yaw = 90, anchor = { 0.0193, -0.0089, 17.2357 }, poseDelta = { 0, 7.6933, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_01_05.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 27.3316, 5.8487, 20.4434 }, yaw = 180, anchor = { 27.3316, 0.4951, 20.4434 }, poseDelta = { 0, -5.3536, 0 } },
            { id = 'seat_b', root = { -27.6873, 5.8487, 20.4434 }, yaw = 180, anchor = { -27.6873, 0.4951, 20.4434 }, poseDelta = { 0, -5.3536, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_01_06.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -0.0135, 7.087, 16.9637 }, yaw = 180, anchor = { -0.0135, 1.2561, 16.9637 }, poseDelta = { 0, -5.8308, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_02_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.6667, 5.8968, 20.6706 }, yaw = 180, anchor = { 26.6667, 0, 20.6706 }, poseDelta = { 0, -5.8968, 0 } },
            { id = 'seat_b', root = { -26.6667, 5.8968, 20.6706 }, yaw = 180, anchor = { -26.6667, 0, 20.6706 }, poseDelta = { 0, -5.8968, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_02_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { 21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
            { id = 'seat_b', root = { -21.8911, 6.0786, 17.3034 }, yaw = 180, anchor = { -21.8911, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_02_03.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.7279, 6.864, 20.7175 }, yaw = 180, anchor = { 26.7279, -0.0236, 20.7175 }, poseDelta = { 0, -6.8876, 0 } },
            { id = 'seat_b', root = { -26.7027, 6.864, 20.7175 }, yaw = 180, anchor = { -26.7027, -0.0236, 20.7175 }, poseDelta = { 0, -6.8876, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_02_04.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 7.7126, -0.0089, 17.2357 }, yaw = 90, anchor = { 0.0193, -0.0089, 17.2357 }, poseDelta = { 0, 7.6933, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_02_05.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 27.3316, 5.8487, 20.4434 }, yaw = 180, anchor = { 27.3316, 0.4951, 20.4434 }, poseDelta = { 0, -5.3536, 0 } },
            { id = 'seat_b', root = { -27.6873, 5.8487, 20.4434 }, yaw = 180, anchor = { -27.6873, 0.4951, 20.4434 }, poseDelta = { 0, -5.3536, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_bench_02_06.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -0.0135, 7.087, 16.9637 }, yaw = 180, anchor = { -0.0135, 1.2561, 16.9637 }, poseDelta = { 0, -5.8308, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_n_m_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0, 3.583, 21.0532 }, yaw = 180, anchor = { 0, 0, 21.0532 }, poseDelta = { 0, -3.583, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_n_m_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 24.6365, 3.583, 21.0532 }, yaw = 180, anchor = { 24.6365, 0, 21.0532 }, poseDelta = { 0, -3.583, 0 } },
            { id = 'seat_b', root = { -24.6365, 3.583, 21.0532 }, yaw = 180, anchor = { -24.6365, 0, 21.0532 }, poseDelta = { 0, -3.583, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_n_m_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 5.5722, 2.922, -6.2839 }, yaw = 90 },
        },
    },
    ['meshes/sky/f/sky_furn_n_m_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, 0.8833, -6.2839 }, yaw = 180 },
        },
    },
    ['meshes/sky/f/sky_furn_n_m_chair_03.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -2.5144, -6.2839 }, yaw = 180 },
        },
    },
    ['meshes/sky/f/sky_furn_n_m_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 0.6479, 21.0532 }, yaw = 180, anchor = { 0, 0, 21.0532 }, poseDelta = { 0, -0.6479, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_orc_bedr_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 0.073, -55.3732, -4.0655 }, yaw = 180 },
        },
    },
    ['meshes/sky/f/sky_furn_orc_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 8.7676, 1.3152, 36.7479 }, yaw = 90, anchor = { -0.4025, 1.3152, 36.7479 }, poseDelta = { 0, 9.1702, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_rea_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.2265, -0.0284, -9.0184 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_furn_rea_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.2265, -0.0284, -9.0184 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_furn_rea_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 19.5265, -30.0671, -9.7675 }, yaw = 270 },
            { id = 'sleep_right', root = { 19.5265, 29.9329, -9.7675 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_furn_rea_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 19.5265, -30.0671, -9.7675 }, yaw = 270 },
            { id = 'sleep_right', root = { 19.5265, 29.9329, -9.7675 }, yaw = 270 },
        },
    },
    ['meshes/sky/f/sky_furn_stool_02_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 6.0786, 17.3034 }, yaw = 180, anchor = { 0, 0, 17.3034 }, poseDelta = { 0, -6.0786, 0 } },
        },
    },
    ['meshes/sky/f/sky_furn_stool_02_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.6379, 4.0691, 15.9639 }, yaw = 180, anchor = { 0.6379, 0, 15.9639 }, poseDelta = { 0, -4.0691, 0 } },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -0.0025, 10.3748, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -0.0025, 10.3748, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -0.0025, 10.3748, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -0.0025, 10.3748, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_05.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 29.995, 13.3486, 57.1275 }, yaw = 180 },
            { id = 'sleep_right', root = { -30.005, 13.3486, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_06.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 29.995, 13.3486, 57.1275 }, yaw = 180 },
            { id = 'sleep_right', root = { -30.005, 13.3486, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_07.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 29.995, 13.3486, 57.1275 }, yaw = 180 },
            { id = 'sleep_right', root = { -30.005, 13.3486, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_08.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 29.995, 13.3486, 57.1275 }, yaw = 180 },
            { id = 'sleep_right', root = { -30.005, 13.3486, 57.1275 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_09.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { -0.0025, 10.9667, 57.1275 }, yaw = 180 },
            { id = 'sleep_top', root = { 0.0693, 12.7955, 145.8681 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_10.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { -0.0025, 10.9667, 57.1275 }, yaw = 180 },
            { id = 'sleep_top', root = { 0.0693, 12.7955, 145.8681 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_11.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { -0.0025, 10.9667, 57.1275 }, yaw = 180 },
            { id = 'sleep_top', root = { 0.0693, 12.7955, 145.8681 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bed_12.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { -0.0025, 10.9667, 57.1275 }, yaw = 180 },
            { id = 'sleep_top', root = { 0.0693, 12.7955, 145.8681 }, yaw = 180 },
        },
    },
    ['meshes/sum/f/sum_furn_p_bench_01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 21.9767, 6.6042, 41.45 }, yaw = 180, anchor = { 21.9767, 0.0031, 41.45 }, poseDelta = { 0, -6.6012, 0 } },
            { id = 'seat_b', root = { -21.9767, 6.6042, 41.45 }, yaw = 180, anchor = { -21.9767, 0.0031, 41.45 }, poseDelta = { 0, -6.6012, 0 } },
        },
    },
    ['meshes/sum/f/sum_furn_p_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0, 6.6042, 41.45 }, yaw = 180, anchor = { 0, 0.0031, 41.45 }, poseDelta = { 0, -6.6012, 0 } },
        },
    },
    ['meshes/sum/f/sum_furn_p_bstool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 3.1976, 58.6515 }, yaw = 180, anchor = { 0, -2.1951, 58.6515 }, poseDelta = { 0, -5.3928, 0 } },
        },
    },
    ['meshes/sum/f/sum_furn_p_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, 0.0873, 41.45 }, yaw = 0 },
        },
    },
    ['meshes/sum/f/sum_furn_p_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0, -1.3372, 45.8681 }, yaw = 0 },
        },
    },
    ['meshes/sum/f/sum_furn_p_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0.1428, 0.0044, 41.45 }, yaw = 90, anchor = { 0, 0.0044, 41.45 }, poseDelta = { 0, 0.1428, 0 } },
        },
    },
    ['meshes/sum/f/sum_furn_p_stool_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.0008, 0.9338, 45.5303 }, yaw = 180, anchor = { -0.0008, 0.0001, 45.5303 }, poseDelta = { 0, -0.9338, 0 } },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 15.1363, 0.4704, -19.2309 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.1368, 0.4716, 62.682 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9248, 0.4081, 27.4912 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 17.9889, -1.0885, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -13.2526, 28.763, 17.1405 }, yaw = 90 },
            { id = 'sleep_right', root = { -13.2526, -31.237, 17.1405 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_05.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_06.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_07.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.4677, 0.0747, 1.423 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_08.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.4677, 0.0747, 1.423 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_09.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.4677, 0.0747, 1.423 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_10.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.4677, 0.0747, 1.423 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_11.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -11.4677, 0.0747, 1.423 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_12.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 0.3936 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 0.3936 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_13.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 0.3936 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 0.3936 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_14.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 0.3936 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 0.3936 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_de_bed_15.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { -11.3259, 30.0924, 0.3936 }, yaw = 90 },
            { id = 'sleep_right', root = { -11.3259, -29.9076, 0.3936 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_act_t_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.1833, -1.0571, 26.9492 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 20.7651, -29.9885, 23.287 }, yaw = 270 },
            { id = 'sleep_right', root = { 20.7651, 30.0115, 23.287 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_bed_05.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.8969, -0.009, 23.8803 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -2.8505, -9.8273 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_com_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -2.8505, -9.8273 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_com_chair_03.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -2.8505, -9.8273 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_com_chair_04.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -2.8505, -9.8273 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_com_chair_05.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.1935, -2.8505, -9.8273 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_com_m_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9172, -29.5961, 18.2512 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9172, 30.4039, 18.2512 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_m_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 13.9172, -29.5961, 18.2512 }, yaw = 270 },
            { id = 'sleep_right', root = { 13.9172, 30.4039, 18.2512 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_m_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 13.9233, 0.4047, 25.8541 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_p_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 16.6946, -29.5908, 20.7788 }, yaw = 270 },
            { id = 'sleep_right', root = { 16.6946, 30.4092, 20.7788 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_p_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 16.6946, -29.5908, 20.7788 }, yaw = 270 },
            { id = 'sleep_right', root = { 16.6946, 30.4092, 20.7788 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_p_bedpri.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -13.5656, -38.9406, 10.9187 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_furn_com_p_bedstr.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 11.1831, 0.2191, 7.892 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_r_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 14, -30, 86.1697 }, yaw = 270 },
            { id = 'sleep_right', root = { 14, 30, 86.1697 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_r_bed_02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 20.7648, -29.9885, 23.5838 }, yaw = 270 },
            { id = 'sleep_right', root = { 20.7648, 30.0115, 23.5838 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_r_bed_03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 14, 0, 86.1697 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_r_bed_04.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 18.8969, -0.009, 23.8803 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_com_throne.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.5176, -12.0424, 71.5188 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_de_p_bench_03.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 27.3098, 5.8487, 19.2218 }, yaw = 180, anchor = { 27.3098, 0.4954, 19.2218 }, poseDelta = { 0, -5.3533, 0 } },
            { id = 'seat_b', root = { -27.709, 5.8487, 19.2218 }, yaw = 180, anchor = { -27.709, 0.4954, 19.2218 }, poseDelta = { 0, -5.3533, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_de_p_bench_04.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { -0.0112, 7.087, 16.9706 }, yaw = 180, anchor = { -0.0112, 1.2561, 16.9706 }, poseDelta = { 0, -5.8309, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_de_r_chair.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.7254, 2.4149, 0.93 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_de_r_stool_01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 1.5456, 20.857 }, yaw = 180, anchor = { 0, 0, 20.857 }, poseDelta = { 0, -1.5456, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_de_r_stool_02.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, 1.5456, 22.857 }, yaw = 180, anchor = { 0, 0, 22.857 }, poseDelta = { 0, -1.5456, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_de_r_stool_03.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.2185, -0.0391, 12.2916 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_b01.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 15.7757, -0.0009, -14.6555 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.0529, 0.0001, 67.3505 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_b02.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 15.7757, -0.0009, -14.6555 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.0529, 0.0001, 67.3505 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_b03.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 15.7757, -0.0009, -14.6555 }, yaw = 270 },
            { id = 'sleep_top', root = { 15.0529, 0.0001, 67.3505 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_d01.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.3508, -30.0027, 23.3956 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.3508, 29.9973, 23.3956 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_d02.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.3508, -30.0027, 23.3956 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.3508, 29.9973, 23.3956 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_d03.nif'] = {
        kind = 'sleep',
        bedType = 'double',
        facing = 'fixed',
        slots = {
            { id = 'sleep_left', root = { 15.3508, -30.0027, 23.3956 }, yaw = 270 },
            { id = 'sleep_right', root = { 15.3508, 29.9973, 23.3956 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_s01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 15.1009, 0, 22.2709 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_s02.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 15.1009, 0, 22.2709 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bed_s03.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { 15.1009, 0, 22.2709 }, yaw = 270 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bench.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 26.1215, 7.0083, 22.7572 }, yaw = 180, anchor = { 26.1215, -0.0948, 22.7572 }, poseDelta = { 0, -7.1031, 0 } },
            { id = 'seat_b', root = { -25.5475, 7.0083, 22.7572 }, yaw = 180, anchor = { -25.5475, -0.0948, 22.7572 }, poseDelta = { 0, -7.1031, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_bench_02.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 0.0002, 7.1138, 22.7412 }, yaw = 180, anchor = { 0.0002, 0.0107, 22.7412 }, poseDelta = { 0, -7.1031, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_chair01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.8042, 0.704, 0.93 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_chair02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { -0.3823, -7.7853, 37.4189 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_stool.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { -0.5167, 0.7441, 20.6187 }, yaw = 180, anchor = { -0.5167, -0.7304, 20.6187 }, poseDelta = { 0, -1.4746, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_de_rm_stool_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 1.6465, -0.1871, 20.7543 }, yaw = 90 },
        },
    },
    ['meshes/tr/f/tr_furn_dreu_bed_01.nif'] = {
        kind = 'sleep',
        bedType = 'bunk',
        facing = 'fixed',
        slots = {
            { id = 'sleep_bottom', root = { 0.6664, -40.7352, 95.5127 }, yaw = 180 },
            { id = 'sleep_top', root = { 4.1952, -62.2635, 197.2558 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_dreu_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 0.6243, -16.7026, -14.5388 }, yaw = 0 },
        },
    },
    ['meshes/tr/f/tr_furn_dreu_chair_02.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 4.8171, -45.1183, 17.188 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_dreu_throne_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 12.4492, 38.0915, 656.1566 }, yaw = 0 },
        },
    },
    ['meshes/tr/f/tr_furn_dwrv_bed00.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -3.4049, 20.8704, -32.4211 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_dwrv_bed01.nif'] = {
        kind = 'sleep',
        bedType = 'single',
        facing = 'fixed',
        slots = {
            { id = 'sleep_main', root = { -3.4049, 20.8704, -32.4211 }, yaw = 180 },
        },
    },
    ['meshes/tr/f/tr_furn_dwrv_stool01.nif'] = {
        kind = 'sit',
        seatType = 'stool',
        facing = 'free',
        slots = {
            { id = 'default', root = { 0, -0.3816, 35.3864 }, yaw = 180, anchor = { 0, 0, 35.3864 }, poseDelta = { 0, 0.3816, 0 } },
        },
    },
    ['meshes/tr/f/tr_furn_t_chair_01.nif'] = {
        kind = 'sit',
        seatType = 'backed_chair',
        facing = 'fixed',
        slots = {
            { id = 'default', root = { 3.854, -6.748, -4.2834 }, yaw = 180 },
        },
    },
    ['meshes/tr/x/tr_ex_dres_bench01.nif'] = {
        kind = 'sit',
        seatType = 'bench',
        facing = 'two_sided',
        slots = {
            { id = 'seat_a', root = { 40.96, -14.8491, 65.7003 }, yaw = 180, anchor = { 40.96, 0, 65.7003 }, poseDelta = { 0, 14.8491, 0 } },
            { id = 'seat_b', root = { -40.96, -14.8491, 65.7003 }, yaw = 180, anchor = { -40.96, 0, 65.7003 }, poseDelta = { 0, 14.8491, 0 } },
        },
    },
}

return M
