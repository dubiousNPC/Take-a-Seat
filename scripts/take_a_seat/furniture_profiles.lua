---@omw-context none
--[[
    furniture_profiles.lua -- GENERATED, do not edit by hand.

    Harvested from the ProceduralChatter / SDP profile set, which
    calibrates the same furniture this mod sits on and is kept far more
    current than a hand-maintained list. Regenerate with
    tools/gen_furniture_profiles.py.

    The generator asserts every SeatType here is one Take a Seat defines,
    so a profile naming an unknown type stops the build instead of
    classifying furniture as nil at runtime -- which is how the THRONE
    and BATH faults both reached players.
]]

local M = {}

-- recordId -> seat type string. Merged UNDER the mod's own table, so a
-- hand-authored entry always wins over a generated one.
M.SEATS = {
    ['ab_furn_commidchaircushgreen'] = 'backed_chair',
    ['ab_furn_demidbench'] = 'bench',
    ['ab_furn_demidchair'] = 'backed_chair',
    ['furn_com_p_bench_01'] = 'bench',
    ['furn_com_pm_chair_02'] = 'bench',
    ['furn_com_pm_stool_02'] = 'stool',
    ['furn_com_r_chair_01'] = 'backed_chair',
    ['furn_com_rm_barstool'] = 'barstool',
    ['furn_com_rm_bench_02'] = 'bench',
    ['furn_com_rm_chair_03'] = 'backed_chair',
    ['furn_com_rm_stool_01'] = 'bench',
    ['furn_de_bench_03'] = 'bench',
    ['furn_de_ex_bench_01'] = 'bench',
    ['furn_de_ex_stool_02'] = 'stool',
    ['furn_de_p_bench_03'] = 'bench',
    ['furn_de_p_bench_04'] = 'bench',
    ['furn_de_p_chair_01'] = 'backed_chair',
    ['furn_de_p_chair_02'] = 'backed_chair',
    ['furn_de_p_stool_01'] = 'stool',
    ['furn_de_r_bench_01'] = 'bench',
    ['furn_de_r_bench_02'] = 'bench',
    ['furn_de_r_chair_03'] = 'backed_chair',
    ['t_imp_furnm_chair01brown'] = 'backed_chair',
    ['t_imp_furnm_chair01green'] = 'backed_chair',
    ['t_imp_furnr_chair_02'] = 'backed_chair',
    ['t_imp_furnr_chair_04'] = 'backed_chair',
    ['t_imp_furnr_chair_05'] = 'backed_chair',
    ['t_nor_furnm_bench_01'] = 'bench',
    ['t_nor_furnm_chair_01'] = 'backed_chair',
    ['t_nor_furnm_chair_02'] = 'backed_chair',
    ['t_nor_furnm_chair_03'] = 'backed_chair',
    ['t_nor_furnm_stool_01'] = 'stool',
}

-- Seat-surface drop, only where the profile differs from the -36 default.
M.PIVOTS = {
}

-- recordId -> bed placement. `z` is the sleep-root vertical offset and
-- `yaw` the pose rotation the profile expects, both in the source units.
M.BEDS = {
    ['ab_furn_comrchbeddouble03'] = { type = 'DOUBLE', z = -180, yaw = -90, slots = 'sleep_a|0,0,0||14.019,68.796,-7.5|-58;sleep_b|0,0,0||14.019,-68.796,-7.5|58' },
    ['ab_furn_demidbedbunk03'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||39.778,-87.556,10' },
    ['ab_furn_demidbedsingle02'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||39.778,82.444,6' },
    ['ab_furn_deplnhammockrug04'] = { type = 'HAMMOCK', z = -180, yaw = -90, slots = 'default' },
    ['active_com_bed_01'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'default' },
    ['active_com_bed_02'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'default' },
    ['active_com_bed_03'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||20,-45,5' },
    ['active_com_bed_04'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'default' },
    ['active_com_bed_05'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||-8,84,2' },
    ['active_com_bed_06'] = { type = 'DOUBLE', z = -180, yaw = -90, slots = 'sleep_right|0,0,0|-150,0,0|0,30,8|-58;sleep_left|0,0,0|150,0,0|0,-30,8|58' },
    ['active_com_bed_07'] = { type = 'DOUBLE', z = -180, yaw = -90, slots = 'sleep_a|0,0,0|-150,0,0|0,95,-32|-58;sleep_b|0,0,0|150,0,0|0,-95,-32|58' },
    ['active_com_bunk_01'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||19.778,-4.556,65' },
    ['active_com_bunk_02'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||20,14,-2' },
    ['active_de_bedroll'] = { type = 'BEDROLL', z = -180, yaw = -90, slots = 'default' },
    ['active_de_p_bed_03'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||1.576,-27.788,10' },
    ['active_de_p_bed_04'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||29.778,82.444,23' },
    ['active_de_p_bed_09'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||29.778,82.444,10' },
    ['active_de_p_bed_10'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||37.778,0.444,19' },
    ['active_de_p_bed_11'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||40,-78,8' },
    ['active_de_p_bed_13'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'default' },
    ['active_de_p_bed_14'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'default' },
    ['active_de_p_bed_15'] = { type = 'DOUBLE', z = -180, yaw = -270, slots = 'sleep_a|0,0,0||-20.222,-77.556,5|-58;sleep_b|0,0,0||-20.222,77.556,5|58' },
    ['active_de_p_bed_16'] = { type = 'DOUBLE', z = -180, yaw = -270, slots = 'sleep_a|0,0,0||-20.222,-15.556,0|-58;sleep_b|0,0,0||-20.222,15.556,0|58' },
    ['active_de_p_bed_28'] = { type = 'HAMMOCK', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||34.778,32.444,-30' },
    ['active_de_pr_bed_08'] = { type = 'DOUBLE', z = -180, yaw = -270, slots = 'sleep_a|0,0,0||1.576,-27.788,10|-58;sleep_b|0,0,0||1.576,27.788,10|58' },
    ['active_de_pr_bed_26'] = { type = 'DOUBLE', z = -180, yaw = -270, slots = 'sleep_a|0,0,0||141.576,-92.788,-15|-58;sleep_b|0,0,0||141.576,82.212,-20|58' },
    ['active_de_r_bed_06'] = { type = 'DOUBLE', z = -180, yaw = -90, slots = 'sleep_a|0,0,0||-10.222,33.444,-16|-58;sleep_b|0,0,0||-10.222,-33.444,-16|58' },
    ['active_de_r_bed_20'] = { type = 'DOUBLE', z = -180, yaw = -90, slots = 'sleep_right|0,0,0|150,0,0|19.778,-82.556,12|58;sleep_left|0,0,0|-150,0,0|19.778,82.556,12|-58' },
    ['chargen_bed'] = { type = 'BEDROLL', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||22.5,0,-25' },
    ['meshes/f/active_de_bedroll.nif'] = { type = 'BEDROLL', z = -180, yaw = -90, slots = 'default' },
    ['sky_act_com_bunk_01'] = { type = 'BUNK', z = -180, yaw = -90, slots = 'sleep_bottom|0,0,0||7.783,-41.975,-40;sleep_top|0,0,0||7.783,-41.975,40' },
    ['t_com_furn_bed_01'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||5.422,-16.788,9.308' },
    ['t_com_furn_bed_02'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||26.576,2.212,11' },
    ['t_com_furn_bed_03'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||26.576,85.212,0' },
    ['t_com_furn_bunk_02'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||7.783,-41.975,7' },
    ['t_nor_furnm_bed_01'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||5.422,-16.788,9.308' },
    ['t_nor_furnm_bed_02'] = { type = 'SINGLE', z = -180, yaw = -90, slots = 'sleep_main|0,0,0||5.422,-16.788,9.308' },
    ['t_nor_furnm_bed_08'] = { type = 'DOUBLE', z = -180, yaw = -90, slots = 'sleep_a|0,0,0||26.576,42.788,-80|-58;sleep_b|0,0,0||26.576,-42.788,-80|58' },
}

return M
