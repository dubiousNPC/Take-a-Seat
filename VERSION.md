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
