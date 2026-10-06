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
