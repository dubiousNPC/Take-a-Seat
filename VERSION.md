# Take a Seat v0.38

## Sit-down and stand-up transitions wired to the new clips

`xdbsTASsitT*.kf` installed on all six skeleton folders (base, .1st, female,
female.1st, kna, kna.1st) and wired as the seat enter/exit one-shots.

**The group names are `tassitd1/2` (down) and `tassitu1/2` (up) -- double s.**
The handover note spelled them `tasistd1/2` and `tasitu1/2`; neither exists in
any of the three files. A group name the `.kf` does not define plays nothing
and reports nothing, so these were read out of the binaries. `check_anims.py`
now reports all four as present on all six skeletons.

Variant 1 is used everywhere; variant 2 is the authored alternative in the same
file. CUSHION is the exception at both ends -- it is floor sitting, posed from
the RA set, so it keeps `rasitup1` for standing and has no chair sit-down.

This replaces the `getup1` exit wired in v0.36. `getup1`/`getup2` (now in
`xdbsWakeUp*.kf`) are no longer referenced by anything, and
`xbase_animkna/xdbsgetup01.kf` duplicates the same two groups the beast
skeleton already gets from `xdbsWakeUpkna.kf` -- both are dead weight unless
beds get their transitions wired.

## The one-shot backstop was racing the new clips

`ONE_SHOT_TIMEOUT` was 1.0s. Measured from the text keys in the new file:
`tassitd1` 1.000s, `tassitd2` 0.967s, `tassitu1` 1.033s, `tassitu2` 1.033s.

That backstop exists for a clip that never reports an end, but the seated idle
waits on it and the exit releases controls on it, so at 1.0s it fired a hair
*before* the stand-up finished -- cutting the pose in and returning input
early. Now 1.5s, with the measurements in the comment and a check in
`test_oneshot.lua` so a future clip longer than the backstop is caught.

## Blending configs for the new clips

Every other clip in this mod ships a `.yaml` blending rule; the new ones did
not, so they would cut in hard while everything else eases. Added the same base
rule the other files use (`sineOut`, 0.25s) for all six copies. The comment
records the measured clip lengths and what a per-clip override at about a third
of length would be, which is the pattern `xdbsRAsitting1.yaml` follows -- that
tuning is a judgement call and was left alone.

## AnimRefresh v6 shipped without being registered

`scripts/AnimRefresh/AnimRefresh_v6.lua` was added back to the package, but
`take_a_seat.omwscripts` had no line for it -- the manifest still carried the
v0.37 comment saying AnimRefresh was *not* bundled. A script file that is not
registered is shipped and never loaded, so the sit pose would still be dropped
on every perspective change, Rest, Travel and game load with the file sitting
right there in the mod.

- Registered as `PLAYER: scripts/AnimRefresh/AnimRefresh_v6.lua`, before the
  mod's own player script.
- Manifest comment corrected.
- The absent-interface warning no longer names a specific version; it points at
  the registration instead, which is the thing that was actually wrong.
- `tools/test_animrefresh.lua` now finds whichever `AnimRefresh_v*.lua` is
  bundled rather than hardcoding v5, and asserts version >= 5. Hardcoded, it
  reported SKIP while a testable v6 sat beside it.

v6's own wiring checks out: `UiModeChanged` is in `eventHandlers`, and
`check_handlers.py` passes over all 12 handler and event keys.

## Checks

With the Cod3x 0.4 stubs restored, the two that could not run for v0.37 now do:

luacheck 6/6, check_load 6/6, globalcheck 0, check_handlers 0 (12 keys),
**ctxcheck 0 issues**, **api_sweep 10 items, all known false positives**
(inherited `self.id`/`self.position`, and the two bundled interfaces that have
no Cod3x stub), check_manifest 0, check_anims 0 unplayable across all six
skeletons. All five test files pass.

One standing gap, unchanged and unplayed: `sleepte1`-`sleepte6` are missing
from the three `.1st` folders. Nothing plays them -- bed enter is not wired --
so it costs nothing today.

---

# Take a Seat v0.37

## Activating a seated NPC sat the player on their chair

The furniture search **pierces** anything that is not sittable, so a ray went
straight through an NPC and returned the chair underneath them. Looking at a
seated NPC therefore found furniture, the mod sat the player down on top of
them, and the NPC could never be talked to.

Three changes:

- `castPiercing` gained a third verdict. `onHit` may now return `'stop'`, which
  ends that column without a result, instead of only accept/pierce.
- The furniture filter returns `'stop'` for an actor. An NPC between the player
  and a chair now blocks that line of sight entirely, so no furniture is found
  and the activation reaches the NPC.
- The SharedRay fast path reports `blocked` when the crosshair is on an actor,
  so the slower piercing search is not run as a fallback and cannot find the
  chair behind them.

Also added: `seatOccupied`. An actor within 30 units horizontally and 90
vertically of the furniture's origin means the seat is taken, and `beginSit`
refuses. Sitting into a seated NPC was the other half of why they could not be
reached.

## A chair at a table left the player floating with knees above the table

The player's collision capsule keeps its standing height while seated, so a
seat under a table top leaves the capsule intersecting the table and the engine
resolves that the only way it can: it pushes the player **up**, out of the
chair and onto the table.

The chair-push stage cannot fix this. It is capped at `CHAIR_PUSH_MAX_MOVE`
(22 units) and a tucked-in chair needs more than that to clear a table, and
shoving world furniture further is the more invasive repair.

New resolve stage `clearOverhead`, between the wall push and the commit:

- Cast up from the seat through `OVERHEAD_CLEARANCE` (115, a standing actor).
  Nothing there, no change -- the common case costs one ray.
- Blocked: try a ring of escapes (radii 18/30/42, eight directions), ordered
  nearest first and, within a radius, closest to **straight back from where the
  seated player looks**. A chair at a table faces the table, so that is out
  from under it.
- The winner is reach-tested with one horizontal ray, so a clear ceiling behind
  a wall is not chosen.
- Nothing clear in the ring: sit anyway and log under `DEBUG`. Refusing to sit
  would be worse, and the log names the case that still looks like the old bug.

All probes go out in **one batch**. Walking 24 candidates serially would cost
~50 async round-trips and could lose the race against `RESOLVE_TIMEOUT`,
leaving a press of Activate doing nothing. This costs three round-trips.

The facing is taken from the global script, not the chair: `take_a_seat_global`
teleports the player with `rotateZ(yaw + math.pi)`, so a seated player looks
along `yaw + pi`. Reading the chair's own forward instead would have pushed the
player **further under** the table. A test pins both halves of that
relationship so they cannot drift apart.

## AnimRefresh is no longer bundled, and nothing said so

`scripts/AnimRefresh/AnimRefresh_v5.lua` is gone from the package and its
manifest line with it, while the manifest comment still claimed "Both are
bundled" and `tools/test_animrefresh.lua` still tried to load the file and
errored.

AnimRefresh is what re-issues the sit pose after the engine rebuilds the player
model -- a perspective switch, Rest, Travel, a game load. Without it the pose is
simply lost on those events. In this suite that is fine, because CAKE, DED and
WhyWalk all ship `AnimRefresh_v5.lua` and the version guard resolves it, but a
standalone install of Take a Seat silently loses the mod's main effect.

- `subscribeRefresh` now logs once when the interface is absent, naming the file
  to install. Same shape Bardcraft uses for the same dependency.
- The manifest comment says what is bundled and what is expected from the load
  order.
- `tools/test_animrefresh.lua` skips with a reason instead of erroring, so a
  sweep of this mod stays readable and the contract test still runs for whoever
  does ship the file.

## Tests

`tools/test_targeting.lua`, 22 checks: actor recognition, a ray through an NPC
finding nothing while the same chair is still found without them, clutter still
being pierced, seat occupancy including the player not blocking their own seat,
the escape-ring ordering under rotation, the clearance height, and the facing
relationship with the global script. None of it can run against v0.36 -- the
functions do not exist there.

Suite: luacheck 5/5, check_load 5/5, globalcheck 0, check_handlers 0,
check_anims 0 unplayable, check_manifest 0, and `test_oneshot`,
`test_priorities`, `test_controls` all pass.

Not run: `api_sweep.py` and `ctxcheck.py`, which need the Cod3x 0.4 stubs. They
were not available in this session. The new code calls only what this file
already used -- `nearby.actors`, `nearby.asyncCastRenderingRay`,
`types.NPC/Creature.objectIsInstance` -- so re-running them is worth doing but
nothing in the diff is a new API surface.

---

# Take a Seat v0.36

## Menus could not be opened while seated

`CONTROL_SWITCH.Controls` is vanilla's `DisablePlayerControls`, and in OpenMW it
gates more than walking: the inventory, journal and quick keys are refused
while it is off. The mod turned it off for the whole sit, so no menu would
open. Nothing else it did could cause this -- the only other switch it touched
was `Jumping`.

The lock now uses `I.Controls.overrideMovementControls(true)`, which stops the
engine processing movement (including jump and sneak) and leaves UI controls
alone. The engine's own docs point the other way for the heavy case ("if
movement should be disallowed completely, consider to use
`types.Player.setControlSwitch` instead"), so the switch was the sledgehammer.
`overrideCombatControls` is set alongside it to keep the old side effect that
you cannot swing a weapon out of a chair. Activation is deliberately left to
the engine -- the Activate trigger is what stands you up. If the Controls
interface is missing, the old switches are used as a fallback.

Caveat: these overrides are one global flag each, not reference counted, so a
release clears any other mod's override too. The control switches had the same
problem, so it is not a regression.

## Animation priorities split between legs and upper body

`priority` accepts a table mapping bone group to priority, and the legs and the
upper body want opposite things:

| | legs | torso + arms |
|---|---|---|
| seated idle | `Weapon` (7) | `Movement` (5) |
| enter / exit | `Knockdown` (9) | `Weapon` (7) |

- **Legs** must outrank what the engine plays by itself -- Movement, Jump, Hit
  -- or a nudge replaces the seated legs with a walk cycle.
- **The upper body must lose**, so hit reactions, a drawn weapon, a torch and
  other mods' conversation gestures can take the torso and arms. Procedural
  Chatter is the reference: it poses seated NPCs at `PRIORITY.Movement` and
  plays gestures on bone mask 14 at a higher priority, expecting the pose to
  yield there. One flat priority across all four groups blocked that.
- **Transitions outrank the idle on the legs**, because a stand-up is a leg
  movement competing with locomotion the instant controls return.
- `PRIORITY.Scripted` is avoided in seat profiles: it pauses every
  non-Scripted animation on the actor, which would freeze the very gestures
  this split makes room for. Beds still use it, with a comment saying why.

## Stand-up animations are now actually played

`SEAT_EXIT_ANIM` was commented out, so the stand-up clips were never played
even though they ship on all four skeletons: `getup1`/`getup2`
(`xdbsgetup01.kf`) and `rasitup1` (`xdbsRAsitting1.kf`). Every seat type now
exits with `getup1`, except `CUSHION`, whose idle (`rasit6`) comes from the RA
set, so it exits with `rasitup1`. `getup2` is the alternative in the same file
if `getup1` reads wrong for a type.

Enter stays unwired: no shipped `.kf` contains a sit-DOWN clip, and naming a
group that does not exist attaches nothing silently.

**Sequencing fix that follows from it.** `stopSitting` released controls before
the exit clip played. With the clip now playing at a transition priority that
outranks locomotion, returning input first would move the player while the
stand-up animates -- sliding out of the chair. Controls are released in the
one-shot's callback instead, which runs immediately when there is no clip, on
the clip ending, or on its 1s backstop.

## Positioning data synced with Procedural Chatter

`sdp/chairProfiles.txt` and `sdp/chairProfileVariants.txt` updated from the
Procedural Chatter "Sitting and Sleeping Fixed" build (6 rows changed).
Regenerating `furniture_profiles.lua` produces identical data: the generator
reads `RecordID`, `SeatType` and `FinalZOffset`, and the update touched
`YawOffset`, `DepthOffset` and `HeightOffset` -- columns this mod does not use.
See `docs/positioning.md` for what that means and what adopting them would
take.

## Tests

- `tools/test_priorities.lua` -- 24 checks on the per-bone priorities and the
  exit wiring. 10 fail on v0.35.
- `tools/test_controls.lua` -- 14 checks that the lock overrides movement and
  combat and never touches `CONTROL_SWITCH.Controls` when the interface exists,
  plus the fallback path. Cannot even extract the functions from v0.35.

Sweep clean: luacheck 6/6, check_load 6/6, globalcheck 0, ctxcheck 0,
check_handlers 0, check_manifest 0, check_anims 0 unplayable,
`test_animrefresh` and `test_oneshot` pass.

---

# Take a Seat v0.35

## Fixes
- **Seated pose replays used a different priority.** The first play used the seat idle profile (`Weapon`, full body). Replays after a perspective change, load, or loop end used a separate `Scripted` constant with no blend mask. All plays now use the idle profile; `SIT_PRIORITY` is gone.
- **The pose restarted right after sitting.** AnimRefresh delivers once to a new subscriber, 0.1s after it joins, which landed just after the pose started and replayed it from frame 0. The refresh now re-issues only when `animation.isPlaying` says the pose was lost.
- **Saving while seated left the chair moved.** The push that clears the chair from walls is undone on stand, but a save made while seated kept the moved position and the load forgot the original. `onSave` now stores it and `onLoad` restores it.
- **Sitting lowered fortified fatigue.** The restore capped at `base`, so fatigue above base (Fortify Fatigue) was pulled down every second. It now caps at `base + modifier` and never lowers.
- **Hiding the HUD blocked sitting and standing.** Activate was ignored while the HUD was toggled off. The gate now checks for an open menu instead.

## Cleanup
- Removed the unused `SitPushChair` / `SitChairReady` path, routine and commented-out prints, unused locals, and empty section headers.
- Corrected the bed enter/exit table labels (clip names had been passed as the error label).
- AnimRefresh v5 comments moved to `docs/animrefresh.md`; code unchanged, same file as FLOW's copy. `tools/__pycache__` removed.
- New `README.md` with the shared-data API and design notes.

Note: the v0.30 profile table below predates the current values. Current: seat idle/enter/exit `Weapon`, full body; misc idle `Weapon`, lower body.

---

# Take a Seat v0.34

## AnimRefresh v4 -> v5: the Rest/Travel refresh had never run

`UiModeChanged` is an EVENT, and v4 registered it under `engineHandlers`, so
OpenMW rejected it with one log line per game:

```
Not supported handler 'UiModeChanged' in scripts/animrefresh/animrefresh_v4.lua
```

The consequence was that v4's Rest/Travel/Training/Jail refresh never fired in
any mod shipping that file. For this mod that is the sit pose not being
re-issued after resting.

Fixed in `scripts/AnimRefresh/AnimRefresh_v5.lua`. The number moved because
every mod bundles this file at one shared VFS path, so a corrected v4 and an
uncorrected one are indistinguishable until install order picks one; the `>=`
guard now settles it instead. Details in `docs/animrefresh.md`.

- Manifest line updated to the new filename.
- `tools/test_animrefresh.lua` now asserts the wiring (it previously called
  `engineHandlers.UiModeChanged` directly and passed on a file the engine
  refuses). It fails on the old v4 file.
- New `tools/check_handlers.py`: loads each module and validates its handler
  and event table keys against the documented engine handlers.

This mod's subscriber is unchanged, including its deliberate omission of
`{ verify = true }` — re-issuing a looping pose must not happen twice.

Sweep clean: luacheck 6/6, check_load 6/6, check_handlers (11 keys, 0
findings), globalcheck 0, ctxcheck 0, check_manifest 0.
`test_animrefresh.lua` and `test_oneshot.lua` pass.

---

# Take a Seat v0.33

## AnimRefresh v3 -> v4

Bundled AnimRefresh is now `scripts/AnimRefresh/AnimRefresh_v4.lua`, rewritten
after a review by the author of Sun's Dusk. It fires once per real model
rebuild instead of four times per POV press, stops firing at all for
vanity/preview (which rebuild nothing), and now covers the two causes v3
missed entirely: **Rest/Travel/Training/Jail** and **loading a save**. The
manifest line changed with the filename.

This mod deliberately does **not** pass `{ verify = true }`: it re-issues a
looping pose, and a second delivery would restart it from frame 0. That,
plus v4 ignoring vanity, is what stops the sit pose twitching when the
player idles in a chair and the camera drifts into vanity.

Full reasoning and the subscriber contract: `docs/animrefresh.md` (v5 supersedes v4).
Tested by `tools/test_animrefresh.lua` (19 checks) plus this mod's own suite.

---

# Take a Seat v0.32

## Enter/exit one-shots called a function that does not exist

`playOneShot` registered its "clip finished" callback with

```lua
anim.addAnimationEndedHandler(self, function(endedGroup) ... end)
```

`openmw.animation` has no `addAnimationEndedHandler`. It exists only as
`I.AnimationController.addAnimationEndedHandler(handler)`, which takes no
actor. The call is to nil, so it raises before `playBlended`, before the
timeout backstop is armed, and before `done` can ever run.

**Latent in v0.31.** Every enter/exit clip table ships empty, so `playOneShot`
returned at `if not group`. The first entry uncommented in `SEAT_ENTER_ANIM`
(the documented way to add a clip) would have broken sitting on that seat.
The idle pose would never start. On standing up, the raise would have skipped
`currentKind, currentSubType = nil, nil`.

It surfaced only because `api_sweep.py` was fixed. Until now that tool had
never checked anything (see project doc `claude/api-sweep-was-vacuous.md`).

### Fix

- One file-scope dispatcher. `pendingOneShot[group] = finish`, and the
  existing `I.AnimationController` ended handler resolves it before its
  sit-idle replay logic. `I.AnimationController` has no way to remove a
  handler, so registering one per play would have leaked a handler for every
  sit.
- `finish` clears its own entry, and only if it is still its own. A replayed
  group cannot finish someone else's one-shot.
- If `I.AnimationController` is absent, the 1s timeout still guarantees `done`.

### Test

`tools/test_oneshot.lua` extracts the real `playOneShot` and the real ended
handler and drives them. 10/10. The v0.31 file fails it.

```
python3 tools/luarun.py tools/test_oneshot.lua
```

### Sweep (all clean)

luacheck 6/6 · check_load 6/6 · globalcheck 0 · ctxcheck 0 issues ·
check_manifest 0 · api_sweep: the only items left to check by hand are
`self.position` (an inherited GameObject field) and third-party interfaces.
`tools/api_sweep.py` and `tools/check_load.py` are replaced with the fixed
versions.

---

# Take a Seat v0.30

---

## The mod was inert again — same fault, new seat type

```
sitAnim_shared.lua:75: table index is nil
```

`SEAT_ANIM` contained `[T.BATH] = "dbssit2"`, and `BATH` was not in `SEAT_TYPE`.
Referenced in four places, defined in none. `[nil] = v` inside a table
constructor raises while the chunk is loading, so `take_a_seat.lua` could not
start and nothing listened for activation — exactly what `THRONE` did last
release.

`check_load.py` caught it in one second. It is the check that exists for this.

### The structural fix, so there is no third time

The pattern `[T.SOMETHING] = value` is the problem, not the missing name. A nil
key in a constructor raises before any validation could run, and the engine
reports a line number rather than the offender.

`SEAT_ANIM`, `SEAT_ENTER_ANIM`, `SEAT_EXIT_ANIM` and the bed tables are now
**keyed by the seat-type NAME**, then resolved through a loop that reports by
name:

```
[take a seat] SEAT_ANIM references unknown seat type 'BATH' --
add it to SEAT_TYPE or remove the row
```

A string key cannot be nil. `BATH` is also now defined.

---

## Furniture profiles assessed

`furniture_profiles.zip` is ProceduralChatter / SDP calibration data, and it is
both broader and more current than this mod's hand-kept tables.

The telling detail: every SDP chair row carries `FinalForwardOffset = -7` and
`FinalZOffset = -36`, which is exactly the pair already hand-written in this
mod's own `furn_com_p_stool_01` entry. The same convention, arrived at
independently — so the two sets can be merged without reconciling units.

Harvested into `scripts/take_a_seat/furniture_profiles.lua`:

| | |
|---|---|
| seat records with a calibrated type | **32** |
| bed records with placement data | **38** |
| pivot overrides | 0 (every profile uses the -36 default) |

Also present and **not** used yet, but worth knowing about:

- `chairProfileVariants.txt` — per-orientation corrections keyed on a 90° yaw
  bucket. A chair placed at 180° sometimes needs a different offset than the
  same chair at 0°. This mod has no yaw-bucket concept; adding one is the
  obvious next accuracy step.
- `animationNormalizationOffsets.txt` — per-animation-group offsets, e.g. a
  global vertical lift for `slee8` to keep a sleeper out of the mattress. That
  becomes directly relevant the moment beds are switched on.
- `ApproachOffsets`, `RotationMode` (`faceOpenSide`, `faceNearestTableOrCounter`,
  `respectFurnitureForward`) and `Slots` — multi-seat benches and where to stand
  before sitting.

Generated, not pasted (RESEARCH §4.3). `tools/gen_furniture_profiles.py`
**asserts every SeatType in the data is one this mod defines**, so a profile
naming an unknown type stops the build rather than classifying furniture as nil
at runtime — which is how both THRONE and BATH reached players.

Generated rows merge **under** the hand-authored tables: an entry written here
always wins.

---

## Enter / exit one-shots

`seats.enterAnimFor(kind, subType)` and `seats.exitAnimFor(kind, subType)`.
Both **optional at every type and in each direction** — a type with no entry
cuts straight to the idle, which is what all eight shipped types do today.

`playOneShot(group, phase, done)` in `take_a_seat.lua` handles the awkward part.
A group the skeleton does not define is a silent no-op: `playBlended` neither
errors nor fires the ended handler, so waiting on it would hang the sit forever.
There is a 1.0 s timeout backstop, and `done` runs exactly once either way.

The exit clip fires **after** the state is cleared, so nothing waits on it — the
player is already standing and free to move. An exit animation is a flourish,
never a gate.

---

## Separate priority masks per target type

`SIT_PRIORITY = anim.PRIORITY.Scripted` was one constant for everything.
`Scripted` pauses every non-Scripted animation on the actor, globally. For a
full-body seated idle that is correct and deliberate. For a short one-shot it is
wrong — it freezes movement for the length of the clip, and RESEARCH §3.2 names
it as the mistake to avoid for gestures.

`seats.buildAnimProfiles(anim)` returns idle/enter/exit per kind:

| kind | idle | enter / exit |
|---|---|---|
| **seat** | `Scripted`, `BLEND_MASK.All` | `Weapon`, `UpperBody` — legs keep walking through the settle |
| **bed** | `Scripted`, `All` | `Scripted`, `All` — lying down is whole-body; an upper-body mask leaves the legs standing |
| **misc** | `Weapon`, `UpperBody` | `Weapon`, `UpperBody` — props never take control away |

`blendMask` takes `BLEND_MASK` (bitmask 1/2/4/8), never `BONE_GROUP` (index
1/2/3/4). The module is passed in rather than required, so `sitAnim_shared`
still requires nothing.

---

## Beds — section added, and switched OFF

`BED_TYPE`, `BED_ANIM`, 38 calibrated records, placement accessors, its own
priority profile. All present.

**`BEDS_ENABLED = false`.** This mod ships no sleeping animation. `slee8` is the
group SDP calibrates and `check_anims.py` reports it absent from all four
skeleton folders. Leaving beds on would teleport the player onto a mattress and
leave them standing in it — no error, nothing in the log.

That is worse than not supporting beds, so `isBed` returns false and `classify`
skips the bed branch while the flag is down. Flip it when a sleeping clip ships
and `check_anims.py` reports `slee8` present.

---

## Miscellaneous items — stub

`MISC_TYPE`, `MISC_ANIM`, `MISC_ENTER_ANIM`, `MISC_EXIT_ANIM`, `MISC_ITEMS`,
`getMiscType`, `isMiscItem`, and a misc entry in the priority profiles.
All empty, all wired.

`isMiscItem` is false for everything and every accessor returns nil, so no code
path changes behaviour by this section existing. Adding the first prop is a data
change, not a structural one.

---

## AnimRefresh v3

**Upgraded, and v2's hole was real here too — it was just being masked.**

v2 fires off the TogglePOV key press and its settle timer writes
`lastMode = camera.getMode()` 0.10 s later. If the engine finishes rebuilding
the model after that, the attached pose is dropped and neither path fires again:
the trigger has already run, and `checkMode` compares against a baseline that is
already the new mode.

You have seen no issue with v2 here because **this mod has its own recovery
net**: `addAnimationEndedHandler` plus `REPLAY_BURST_LIMIT` re-issues a pose that
ends unexpectedly. IED had no equivalent, which is why the same service bug
showed there as gear vanishing until a weapon was drawn.

That net does not cover everything — it fires when the animation *ends*, not
when the animation object is *replaced* — so v3 is still worth taking:

- `lastMode` is owned by `checkMode` alone, so the poll still observes the real
  transition.
- Every delivery is followed by a confirmation pass 0.5 s later.

**No change was needed to this mod's subscriber.** Both fixes are service-side.
The file is renamed `AnimRefresh_v3.lua` because the version guard only helps
when two copies load as two different scripts — two mods both shipping
`AnimRefresh_v2.lua` occupy one VFS path, and whichever data directory wins is
the only file that exists.

---

## Verification

| Check | Result |
|---|---|
| `luacheck.py` | 6 files, **0 failures** |
| `check_load.py` | 6 files, **0 failures** (was 2) |
| `globalcheck.py` | **0** |
| `api_sweep.py` vs Cod3x 0.4 | **nothing unrecognised** |
| `ctxcheck.py` | **0 issues** |
| `check_manifest.py` | **0 mismatches** |
| `check_anims.py` | **0 unplayable** |
| `pcall` in `scripts/take_a_seat/` | **none** |

One known false positive: `check_names.py` reports `a, references, s, take,
unknown` in `sitAnim_shared.lua`. Those are words from the new `error(...)`
message text; its string stripper does not handle a parenthesised
`("..."):format(...)` split across lines. `globalcheck.py` — the reliable one
for this class, per RESEARCH §4.4 — is clean.

The SDP source data is included under `data_furniture_profiles/` so
`tools/gen_furniture_profiles.py` can be re-run.
