# 0001: Lying backwards on beds (feet on the pillow)

- **Status:** fixed on `fixes-v0.44` (`BED_POSE_YAW`). Confirmed in-engine on singles, doubles, the upper bunk berth, the bedroll and hammocks. The lower bunk berth can't be photographed from outside the bunk.
- **Severity:** high (visible on every bed)
- **Found:** v0.43 in-engine run, 2026-11-13

## Symptom
On every single and both sides of every double photographed (`active_de_p_bed_04`, `active_de_r_bed_06` L/R, `active_de_r_bed_20` L/R, `active_de_p_bed_05` L/R, `active_de_pr_bed_27` L/R), the body lies with its feet on the pillow. The root is exact: 0.0 units and 0.0 degrees from the authored slot.

## Cause
The pack solved bed yaws for its reference pose `slee8`. `kf_root_offsets.py` shows that the hips land in the same place for `sleept*`, but it does not measure facing, and `sleept1`/`sleept2`/`sleept5` lie the other way along the bed.

Hammocks are a separate case. `sleept1` happened to look right at the pack yaw, but once hammocks were typed correctly (0003) they play `sleept6`, which lies **across** the pack yaw. Photographed at 0, 90, 180 and 270 on `active_de_bed_29` and `active_de_bed_30`, only +90 lies along the hammock with the head at the pillow end.

## Fix
`BED_POSE_YAW` in `sitAnim_shared.lua`, per bed type: single, double, bunk and bedroll get 180; hammock gets 90. It is applied in `authoredPlacement` for beds only. `test_beds_sweep.lua` asserts the composition at all four object yaws.

## Verify
- Photo pass `tas_beds43_shots.lua`: head on the pillow on 4 singles, both sides of 4 doubles, and the bedroll (brightened).
- `tas_orient.lua` variant runs: hammock at 0/90/180/270, bunk at 0/180.
