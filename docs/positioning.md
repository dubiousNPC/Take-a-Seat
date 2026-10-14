# Seat positioning: what this mod uses, and what it ignores

## The sync

`data_furniture_profiles/sdp/` is harvested from Procedural Chatter / SDP,
which calibrates the same furniture against real NPC seating and is kept more
current than a hand-maintained list. Synced 2026-10-14 from the "Sitting and
Sleeping Fixed" build. Six rows changed:

| record | column | SDP now | was |
|---|---|---|---|
| `furn_com_r_chair_01` | YawOffset | 180 | 0 |
| `t_imp_furnm_chair01green` | Depth / Height | 5 / 4 | -10 / -40 |
| `t_imp_furnr_chair_02` | Height | 0 | -40 |
| `t_imp_furnr_chair_04` | Height | 0 | -35 |
| `t_imp_furnm_chair01green` (variants, yaw 0 and yaw 90) | Depth / Height | 5 / 4 | -10 / -40, -7 / -35 |

**None of it changes this mod's behaviour.** `tools/gen_furniture_profiles.py`
reads three columns -- `RecordID`, `SeatType`, `FinalZOffset` -- and the update
touched none of them. Regenerating `furniture_profiles.lua` before and after
the sync gives byte-identical data.

## The gap behind that

This mod consumes **no** per-record placement offset for chairs. It takes the
furniture's own yaw (`getObjectYaw`), finds the seat plane by raycast, applies
`SIT_PIVOT_OFFSET` where a record needs it, and pushes clear of obstructions.
Beds get a yaw from their profile; chairs do not.

SDP's table says that is not enough. Of the 32 records this mod seats, **13
carry a yaw correction of roughly ±180°**, and several carry height
corrections up to 39 units:

| record | yaw | depth | height | rotation mode |
|---|---|---|---|---|
| `ab_furn_commidchaircushgreen` | -195 | 10 | 5 | respectFurnitureForward |
| `ab_furn_demidchair` | -185 | -9 | -39 | respectFurnitureForward |
| `furn_com_r_chair_01` | 180 | 0 | 0 | respectFurnitureForward |
| `furn_com_rm_chair_03` | 165 | 10 | 2 | respectFurnitureForward |
| `furn_de_p_chair_02` | 165 | 12 | -30 | respectFurnitureForward |
| `furn_de_r_chair_03` | 190 | 17 | 2 | respectFurnitureForward |
| `t_imp_furnm_chair01brown` / `01green` | -180 | 5 | 4 | respectFurnitureForward |
| `t_imp_furnr_chair_02` / `_04` / `_05` | -180 | 0–2 | 0 | respectFurnitureForward |
| `t_nor_furnm_chair_01` / `_02` / `_03` | -180 | 10 | -20 | respectFurnitureForward |

Every `respectFurnitureForward` chair in the table is corrected by about half a
turn, which says those models' forward axis points away from where a seated
actor should face. SDP also has two rotation modes this mod has no equivalent
for: `faceOpenSide` (11 records) and `faceNearestTableOrCounter` (6).

## Before adopting any of it

**The frame of reference is not known to be the same.** SDP's offsets are
applied on top of its own animation normalization
(`sdp/animationNormalizationOffsets.txt`) and its own seat-root maths, against
its own sit clips. This mod places the player differently and uses different
clips, so a ±180 that is correct for SDP may be already baked into this mod's
poses. Applying them blind would seat the player backwards on 13 records.

The question that settles it is a single in-game look: on a common chair
(`furn_com_r_chair_01`) or a TR Imperial chair, does the player face out from
the seat, or into the backrest? If facing is already correct, these offsets are
SDP-frame-only and must stay unused. If it is wrong on exactly those records,
the port is worth doing and looks like this:

1. `gen_furniture_profiles.py` emits `M.YAWS` (and optionally depth/height)
   from `YawOffset` / `DepthOffset` / `HeightOffset`, only where non-zero.
2. `sitAnim_shared.lua` exposes `yawOffsetFor(recordId)` beside
   `pivotOffset`, merged under any hand-authored table so a local correction
   still wins.
3. `commitSit` adds it to `getObjectYaw(furniture)` before the teleport, and
   depth is applied along the seated forward axis, in the same place the push
   offset already is.
4. One record per rotation mode gets checked in game before the table is
   trusted wholesale -- the modes are not interchangeable.
