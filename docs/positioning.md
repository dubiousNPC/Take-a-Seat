# Seat positioning: what this mod uses, and what it ignores

## What places the player (v0.39)

Two positioners, in this order.

1. **Authored, from the solver pack.** If the furniture's `record.model` is one
   of the 189 sit profiles in `scripts/take_a_seat/solver_profiles.lua`, the
   seat point and the facing come from the pack:
   `worldRoot = objectPosition + objectRotation * (slot.root * scale)` and
   `worldYaw = objectYaw + rad(slot.yaw)`, scale clamped to 0.25–4.0. No ray is
   cast for position. `slot.root` is a solved **actor root** for the reference
   pose `pcdbssit5` (= `dbssit5`), so **nothing** is layered on top of it: not
   `SIT_PIVOT_OFFSET`, not the TSV offsets below, not a half turn.
2. **Raycast, for everything else.** The chain that was the only positioner
   before: push the chair clear, find the seat plane, push the player clear.
   Unchanged except that the v0.37 overhead escape is gone.

Which path ran is visible with `DEBUG = true`: the authored path logs
`[sit] authored <record> (<seatType>/<facing>) model=... slot=... yaw=...`, and
a model with no profile logs `no authored profile for <record>; raycasting`.

The pack covers four seat types — `backed_chair`, `bench`, `stool`, `barstool`.
CUSHION, BATH, THRONE and SINGLE_SEAT_BENCH have no authored profiles and take
the raycast path.

### The reference pose is not a problem, and that is measured

Every authored root is solved for one pose, but this mod plays a different
seated clip per seat type. `tools/kf_root_offsets.py` reads the root and pelvis
tracks out of the shipped `.kf` files: across `dbssit2/4/5/6/8`,
`dbssitting24` and `rasit6`, `Bip01` and `Bip01 Pelvis` hold the same
translation and the same rotation to 0.000 units and 0.00 degrees. The poses
differ from the spine up (26–59° of lean), which is the per-seat variety, not a
placement error. Reproduce it with:

```
python3 tools/kf_root_offsets.py animations/xbase_anim/xSitting2.kf \
    animations/xbase_anim/xdbsRAsitting1.kf \
    --ref-file animations/xbase_anim/xdbssitting.kf --ref dbssit5 \
    --bone 'Bip01 Pelvis' --groups dbssitting24,rasit6
```

`POSE_DELTA` in `sitAnim_shared.lua` is therefore empty, and wired in anyway so
that a correction measured later takes effect.

## Staying in the seat (v0.41)

The player's collision capsule is standing height whether they are standing or
sitting. At a table that capsule overlaps the table top, the physics solver
resolves the overlap by pushing the player up, and in game that reads as
drifting back onto the tabletop -- quickly, as reported.

Two answers, in this order:

1. **Collision off while seated** (`COLLISION_OFF`, default on). Removes the
   cause: no overlap to resolve, nothing to push, and no per-tick work at all.
   `debug.toggleCollision` is the engine's own TCL and is not reference
   counted, so the mod only ever toggles a state it checked first and only
   gives back what it took -- a player who turned collision off themselves
   keeps it off. The flag is saved with the game, so a save made while seated
   restores collision on load instead of leaving someone noclipping.
2. **The seat keeper**, for when collision is on -- the setting turned off, or
   another mod holding it. Every `SEAT_KEEP_RATE` (0.25s) while seated it
   compares the player's position with the seat point they were placed on and
   re-asserts it only past `SEAT_KEEP_TOLERANCE` (6 units). Started on sitting
   and stopped on standing, so there is no idle timer, and zero teleports when
   there is nothing to correct.

Not done: the per-frame re-teleport the Procedural Chatter seating uses. It
works by brute force and costs a teleport every frame of every seated NPC.

## Getting up (v0.41)

Sitting down and standing up are symmetric: both end on a point that was
checked first. Standing up glides there rather than snapping, because the
stand-up clip carries no root motion -- the player stood up in place and then
jumped, which is how v0.40 read in game.

The move starts **with** the clip, not after it, and takes `EXIT_GLIDE_TIME`
(0.35s) with an ease-out, so it reads as stepping away from the chair rather
than sliding. The clip not moving the root is what makes this safe: the two
cannot fight. Collision is still off while it runs and comes back when the move
lands, so neither the seat nor the table can push the player mid-glide. With
collision on, the straight line is checked with one ray at torso height first
(`pathClear`), and a blocked line falls back to the snap -- a glide through a
closed door is worse than the teleport it replaces.

`EXIT_GLIDE` turns the glide off for the snap.

The stand-up point, best first:

1. **The position the player was standing in when they sat.** The strongest
   candidate there is -- they walked to it. Validated by a ground ray and the
   same-floor tolerance; the navmesh is used to snap it when it has an answer
   but is not required, because a gap in an interior navmesh must not refuse a
   sit that plainly works. Dropped entirely if the cell changed while they sat.
2. **Forward of the seated facing**, `EXIT_FORWARD` 48 units out of the chair
   rather than into its back. Invented by the mod, so the navmesh *is*
   required here.
3. **The seat itself**, which is where the player already is.

Each candidate is grounded by a physics ray (`nearby.castRay`, ignoring the
furniture), snapped to the navmesh for the player's own agent bounds
(`types.Actor.getPathfindingAgentBounds`), and rejected if the floor it lands
on is more than `GROUND_Z_TOLERANCE` (35) from the floor the player sat down
from -- that is the stairwell case: a point directly below the seat, on the
storey underneath. The chosen point is lifted `EXIT_LIFT` (8) clear of the
floor so the engine settles the player onto it rather than resolving an overlap
with the seat.

If none of them validate, nothing moves. That is deliberately the pre-v0.40
behaviour: no teleport is safer than a teleport to an unchecked point.

The teleport happens in the stand-up clip's completion callback -- never during
it, so the animation is not fighting a moving root -- and the movement override
is released after it, not before.

### Refusing, instead of coping

The same validation runs *before* the sit, while the player is still standing
somewhere they demonstrably reached on foot. A seat is refused when:

- the furniture is tipped over (`furniture.rotation` applied to world up has
  `z < 0.7`, about 45°) -- the player path had no such test and would seat you
  on a chair lying on its side; or
- no stand-up candidate validates, which in practice means the player is not
  standing on anything (levitating, swimming) and the invented candidates have
  no navmesh either.

A refusal says so in a message box rather than doing nothing, because a sit
that silently fails reads as a broken mod.

What this does NOT do: no route is *pathfound* from the seat to the exit, and
no clearance check is made above the seat. The first is unnecessary while the
exit point is a place the player stood a moment ago; the second was the v0.37
overhead escape, which is what put players on tabletops.

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

## The gap behind that (what motivated the rework)

Before v0.39 this mod consumed **no** per-record placement offset for chairs. It takes the
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

## Why the TSV offsets are still unused

v0.39 closed this gap from the other end: the solver pack supplies a solved
actor root and a facing per **model**, which is a complete answer for the
records it covers, in a frame whose arithmetic is documented and testable. The
TSV columns below are in SDP's own frame, on top of SDP's own animation
normalisation, and the two must not be combined — applying both would
double-correct. They stay unused, and the note below is kept only for the
records the pack does not cover.

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
