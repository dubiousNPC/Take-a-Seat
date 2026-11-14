# Take a Seat v0.44

Beds, as tested in OpenMW 0.52 RC1 on real data (see `docs/tickets/`).

- **Facing** (0001): `BED_POSE_YAW` per bed type. The pack's bed yaws face its `slee8` reference, and `sleept*` lies the other way, which put the feet on the pillow on every bed. The fix adds 180 for single, double, bunk and bedroll, and 90 for hammocks (`sleept6` lies across the pack yaw).
- **Upper berth** (0002): a bed slot is chosen by the aim point on the bed, not the feet, so `sleep_top` is reachable. Seats still choose from the feet.
- **Bed type** (0003): the pack's `bedType` wins over the SDP record list, which called every vanilla bunk single. `active_de_bed_28/29/30` are corrected to hammock by model.
- **Clip timing** (0004): the one-shot backstop is the clip's own length (`getTextKeyTime` start/stop) + 0.25 s, so `sleepte*` and `getup1` play in full, and the step off a bed waits for `getup1` to end.
- **For other mods** (0005):
  - `I.TakeASeat` v1: `isSeated`, `isBusy`, `getState`, `standUp`.
  - `TakeASeat_Seated` gains `kind`, `subType`, `slot`, and a lowercase `animGroup`.
  - `TakeASeat_Stood` carries `furniture`, `kind`, `subType`, `slot` and `reason`.
  - New `TakeASeat_StandComplete`.
  - Both events are sent with `reason = 'load'` when loading a save made seated.
- **Rest menu** (0006): the bed's vanilla activation is held back for the press that lies down. New setting "Activate on a bed lies down" (default on): Sneak + Activate opens the Rest menu.
- **Tools and tests** (0007, 0008): `check_bed_surfaces.py` finds `es3` through `TAS_ES3_LIB`; `test_solver_profiles.lua` fixtures are deterministic under Lua 5.4. New checks for berth choice, the clip-length backstop and the activation guard.
- **README** (0009): beds, the interface and the events are documented.
- **Bed movement over the transition** (2026-11-14): lying down no longer teleports onto the mattress. The body glides from where you stand to the slot over 1 s (`BED_GLIDE_TIME`, smoothstep) as the lie-down clip starts. Getting up glides off over the last 1 s of `getup1`, landing as it ends (was a 0.35 s glide after it). The seat keeper waits for the glide to land.

# Take a Seat v0.43

Beds move onto the authored placement path. The bed prototype placed the
sleeper at the furniture's bounding-box centre, which is the middle of the
mattress: a double or a bunk had both of its authored slots collapse onto one
point. Beds now use the same contract as seats --

    worldRoot = objectPosition + objectRotation * (slot.root * scale)
    worldYaw  = objectYaw + rad(slot.yaw)

-- reading the 289 bed profiles (430 named slots) the solver pack has carried
all along. `gen_solver_profiles.py --sleep` emits them; see docs/positioning.md
for the full contract and the measurements behind it.

What changed:
- `solver_profiles.lua` now holds 478 profiles / 660 slots (was 189 / 230).
  Bed profiles carry `bedType` and named slots: `sleep_main`,
  `sleep_left`/`sleep_right`, `sleep_bottom`/`sleep_top`.
- Beds are recognised by **model** as well as record id, so the reach goes
  from the 39 beds the SDP harvest named to all 289 the pack covers --
  including beds from mods this one has never heard of that reuse a known
  mesh. `isSittable` takes the object rather than a bare record id for the
  same reason; without that a pack bed was placed correctly and then never
  offered as a target.
- `POSE_DELTA` stays empty for beds, measured not assumed: every `sleept*` and
  `sleepte*` group carries the same `Bip01` (6.264, 0.782, 2.328) and
  `Bip01 Pelvis` (2.904, 0, 0) as the seated reference `dbssit5`. The `slee8`
  row in `sdp/animationNormalizationOffsets.txt` must not be applied.
- The bed ENTER transitions `sleepte1..6` ship only in the three third-person
  animation folders; the `.1st` copies have `sleept1..6` only. They now fall
  back to the matching held pose, so first person no longer skips the lie-down
  silently.
- The bounding-box path survives as the no-profile fallback only, and a bed can
  no longer fall through to `resolveChairPosition` (seat pivot offsets and a
  seat-height raycast mean nothing on a mattress).
- `gen_solver_profiles.py` now asserts bed types against the clips the mod maps
  and that every bed is fixed-facing, so a pack change stops the build instead
  of playing no clip at runtime.

Checks: 15 jobs green, including `test_beds_sweep.lua` (all 289 profiles and
430 slots at all four 90-degree object yaws, 2284 assertions) and
`check_bed_surfaces.py`, which validates the authored roots against the real
game meshes out of the BSAs -- on the 41 vanilla beds every root is inside the
mesh footprint, median +1.44 units above the visible surface beneath it.

Not re-run in the engine: the real-data harness needs a prebuilt OpenMW
0.52-rc1 binary, and only the source tree was available this session. The v0.42
seat results below still stand.

---

# Take a Seat v0.42

Tested in OpenMW 0.52 on real Morrowind, Tribunal and Bloodmoon data, with
real key presses under vanilla bindings (Activate is Space, Jump is E, the
view toggle is Tab). 20 distinct vanilla seat records, from Seyda Neen and
Balmora interiors where the game places them, cover every seat type:
- backed chairs (fixed solver);
- benches (two-sided);
- stools and barstools (free);
- cushions (the raycast path).

18 seats ran the full cycle with 162/162 checks passing on the final code,
and no Lua errors. Each checks:
- it sits;
- the enter clip hands over to the seated idle;
- the player lands on the seat;
- drift is 0 over 2 s;
- the view toggles both ways;
- it stands up into a sane, unembedded spot;
- collision is back on.

The other two are out of reach, not failures: one record is a disabled quest
prop, and one chair is boxed in by its storage room.

## Fixed: a player seated in third person could not get back to first person
The seated idle played the legs at **Weapon** priority. The engine refuses to
switch the camera to first person while any animation state holds Hit,
Weapon, Knockdown or Death (`MWRender::Animation::upperBodyReady`), and queues
the switch instead. So for the whole sit, Tab from third person did nothing
until the player stood up. Measured on a chair, a bench and a cushion.

The idle's legs are now **Block**:
- still above every engine leg state (Movement, Jump, Hit, Weapon);
- still under the transitions' Knockdown;
- a non-uniform tuple, so a shield's Block cannot erase it.

`test_priorities` pins the engine rule for the seat and misc idles.

## Fixed: Jump never stood the player up
Jump was in the stand-up list, but OpenMW 0.52 has Jump as a **trigger**, not
a named action. The binder only looked at actions and printed "this build has
no Jump". It now falls back to the trigger: "Jump (trigger)".

## Fixed: a save made while seated loaded with the player standing on the seat
Collision came back on load, but nothing moved the player off the furniture.
On a barstool they stood on top of it; at a table that is the push onto the
tabletop that v0.41 exists to prevent.

The save now carries the gate-validated exit, or the spot the player stood on
to sit. On load the player is placed there first, and collision comes back
0.15 s later. Verified with a real F5/F9: the player loads on the floor beside
the seat, with collision on and free to move.

## Parkourwind FLOW is yielded while seated
A seated player is placed with collision off and is never grounded, so FLOW
sat in Airborne for the whole sit. With Jump now standing the player up, that
same held jump would reach FLOW during the glide beside a table. The sit now
calls `I.Flow.yield` **before** taking the shared movement override, and
resumes after releasing it. Optional: without FLOW, nothing happens.

In-engine with FLOW loaded, on a bench and two chairs at tables (39/39):
- FLOW is Idle and yielded while seated;
- E stands the player up;
- no FLOW move fires;
- FLOW is handed back afterwards.

## Requirement now stated
**"Use additional animation sources"** must be on, and it is off by default.
Without it the player sits in the standing idle. The README says so, and the
mod prints a one-time hint naming the setting.

## Tests
- `test_solver_profiles` extracted its helpers up to a `---Facing choice`
  comment that an edit had removed, so it stopped testing anything while
  every other job stayed green. It is now anchored on code
  (`local FACING_SCAN_RANGE`).
- `test_controls` gains the FLOW yield order and the Jump trigger. Against
  the v0.41 file, 6 of its checks fail.
- `test_priorities` gains the camera rule. With the idle back at Weapon, 2
  checks fail.
- All 8 suites pass on Lua 5.4 and on LuaJIT; `run_check_all` runs 14 jobs
  with 0 failures.

# Take a Seat v0.41

Both things reported from in-game testing of v0.40: the drift back onto the
tabletop, and the jarring exit. Stage 6 of the rework proposal, and a revision
of stage 4's commit.

## Stage 6: the tabletop drift

Confirmed necessary in game — the player drifts back onto the table, quickly.
The cause is not the placement: the authored root is right. The player's
collision capsule is standing height whether they are standing or sitting, so
at a table it overlaps the table top, and the physics solver resolves the
overlap by pushing the player up.

**Collision now comes off while seated** (setting `COLLISION_OFF`, default on).
That removes the cause instead of correcting the symptom: no overlap to
resolve, nothing to push, and no per-tick work of any kind.

`debug.toggleCollision` is the engine's own TCL and is not reference counted,
so the mod is careful with it:

- it only ever toggles a state it checked first, and only gives back what it
  took — **a player who turned collision off themselves keeps it off** when
  they stand up;
- the flag is saved with the game, so a save made while seated **restores
  collision on load** rather than leaving someone noclipping with nothing on
  screen to say why;
- the restore after standing is skipped if the player has already sat down
  again inside the glide window, which would otherwise hand collision back
  while seated.

**The seat keeper** is the backstop for when collision is on — the setting
turned off, or another mod holding it. Every 0.25s while seated it compares the
player's position with the seat point they were placed on, and re-asserts it
only past 6 units of drift. Started on sitting, stopped on standing, so there
is no idle timer and nothing per frame; with collision off it never fires at
all. `DEBUG = true` prints how many times it had to hold the seat.

Not done, deliberately: the per-frame re-teleport the Procedural Chatter
seating uses for this. It works by brute force, and costs a teleport every
frame of every seated actor.

## The exit was jarring, and this is why

v0.40 teleported at the *end* of the stand-up clip. The clip carries no root
motion, so the player stood up in place for a second and then jumped to their
feet position. Correct, and horrible.

**The move now starts with the clip** and takes 0.35s with an ease-out, so it
reads as stepping away from the chair. The clip not moving the root is exactly
what makes this safe rather than a fight: there is nothing for the glide to
contradict.

It stays a short, bounded move to a point validated **before** anything moved —
not a lerp through unknown geometry, which is the stuck case the v0.40 gate
exists to prevent. Collision is still off while it runs and comes back when it
lands, so neither the seat nor the table can push the player mid-glide. With
collision on (setting off, or another mod holding it) the straight line is
checked with one ray at torso height first, and a blocked line falls back to
the snap — a glide through a closed door is worse than the teleport it
replaces.

`EXIT_GLIDE` (default on) turns it off for the old snap.

The tween runs in the global script, which is the only place that can move the
player, as `onUpdate` — one nil check wide unless a move is actually running. A
tween is the one thing a timer cannot do smoothly, and 0.35s of it per stand-up
is bounded. Everything else in this mod is still event- or timer-driven.

## Two settings, one new group

Settings → Take a Seat → **Sitting**:

- **Hold the seat with collision off** (default on) — the fix above.
- **Glide out of the seat** (default on) — the exit move.

## Three checkers were not checking

All three found by planting the fault they should have caught, after writing
the feature that needed them.

**`ctxcheck` had stopped resolving requires at all.** v0.40 switched its
stripper to the one-pass `luastrip`, which blanks string literals — and a
module name *is* a string literal, so `local x = require('openmw.debug')` came
out as `require('    ')`. Zero aliases meant zero module checks and zero member
checks, and it printed "0 issues" having looked at nothing. api_sweep
documents this exact trap and avoids it with a separate comments-only strip for
the alias scan; ctxcheck now does the same, reports how many requires it
resolved (**33**), and refuses to report clean if it ever finds none again.
With it fixed, a planted `openmw.debug` require in the global script is
reported as `openmw.debug is ['player'], file is global` — which is also how
the player-script use in this release was verified.

**`ctxcheck` passed any module it had no policy for.** The Cod3x plugin's
AVAILABILITY table covers 25 modules; a module outside it was silently allowed
in every context. It now falls back to each stub file's own
`---@omw-context` line, and reports `NO-POLICY` for anything neither source
covers rather than passing it.

**`globalcheck` never checked writes.** It reported undeclared *reads*, and
root-level accidental globals — but an indented `move = nil` inside a function,
with `local move` fifty lines further down, matched neither. Valid Lua, so
luacheck passes it; OpenMW's script sandbox rejects assignment to an undeclared
global, so it would have raised on the first stand-up. I wrote exactly that bug
in the global script while building the tween. Now reported as
`WRITE-BEFORE-DECL`, with table-constructor keys (`{ position = target }`)
excluded by brace depth rather than by guessing.

## Tests

`tools/run_check_all.py`: **16 jobs, 0 failed, 0 skipped.**

- `tools/test_standup.lua` — new: loads the real global script and calls its
  real handlers. Both yaw conventions, the furniture only moving when it
  should, a bare place being one teleport, the glide arming nothing by itself,
  easing front-loading the movement, never overshooting, landing *exactly* on
  the validated point, stopping itself, costing a handful of teleports rather
  than a stream, a new sit cancelling a glide in flight, and a zero duration
  snapping instead of dividing by zero.
- `tools/test_exit_safety.lua` — adds the glide path check, with a ray mock
  that answers a downward probe and a level probe differently, because
  `pathClear` and `groundBelow` ask the same engine function different
  questions.
- `tools/test_targeting.lua` — the move starting with the clip rather than in
  its callback, the keeper stopping before the player is moved, collision
  restored on a timer sized by the move and only there, the re-sit guard, the
  keeper's tolerance and its "only while seated" early-out, that collision is
  only taken when it was on, that the setting is honoured, and that the state
  is saved and restored.

## Not in this release

- The pack still covers four seat types (`backed_chair`, `bench`, `stool`,
  `barstool`); CUSHION, BATH, THRONE and SINGLE_SEAT_BENCH take the raycast
  path.
- Beds remain off (`BEDS_ENABLED = false`).
- The v0.40 log line is still worth a look on first run — it reports which
  movement actions the stand-up is bound to.
