# Take a Seat v0.40

Stages 4 and 5 of the rework proposal: the exit commit, the recorded origin,
stand-up on movement input, the pre-sit gate and the tipped-furniture check.
v0.39's authored placement from the solver pack is unchanged and still the
primary positioner.

## Standing up now ends somewhere that was checked first

One teleport, in the stand-up clip's completion callback — never during the
clip, so the animation is not fighting a moving root — and the movement
override is released after it rather than before.

The stand-up point, best first:

1. **Where the player was standing when they sat.** The strongest candidate
   there is: they walked to it. Re-validated at the moment they get up, not
   trusted from sit time, because a door may have closed or something may have
   been dropped there since.
2. **Forward of the seated facing**, 48 units — out of the chair, not into its
   back.
3. **The seat itself**, which is where the player already is.

Each one is grounded with a physics ray that ignores the furniture, snapped to
the navmesh for the player's **own** agent bounds
(`types.Actor.getPathfindingAgentBounds` — a point something smaller can stand
on says nothing about the player), and rejected if the floor it lands on is
more than 35 units from the floor the player sat down from. That last one is
the stairwell: a point directly under the seat, on the storey below. The chosen
point is lifted 8 units clear of the floor, which is the "slight push off the
mesh" — the engine settles the player onto the floor instead of resolving an
overlap with the seat.

**If nothing validates, nothing moves.** That is deliberately the old
behaviour: no teleport is safer than a teleport to an unchecked point.

It is a teleport and not a lerp, in or out. Lerping a player through interior
geometry is the stuck case this whole stage exists to prevent, and the
transition clips already supply the visual motion. The NPC-side lerp in the
Procedural Chatter pair exists because NPCs walk to their seat under AI; the
player does not.

**A cell change while seated drops the recorded origin.** A script or a door
can move the player mid-sit, and those coordinates in a different cell may well
find a floor and a navmesh — somewhere the player has never been.

## Refuse, don't cope

The same validation runs **before** the sit, while the player is still standing
somewhere they reached on foot. The old order committed the teleport and dealt
with the consequences; this is what makes "stuck in a cramped interior"
unreachable rather than mitigated.

A seat is refused when:

- **the furniture is tipped over** — local up tilted more than about 45° from
  world up. The player path had no such test and would happily seat you on a
  chair lying on its side. This check costs no rays at all, and runs first.
- **no stand-up candidate validates** — in practice, the player is not standing
  on anything (levitating, swimming) and the invented candidates have no
  navmesh either.

A refusal shows a message rather than doing nothing, because a sit that
silently fails reads as a broken mod.

Being honest about the scope: no route is *pathfound* from the seat to the exit,
and nothing is checked above the seat. The first is unnecessary while the exit
is a place the player stood moments ago; the second was v0.37's overhead escape,
which is exactly what put players on tabletops.

The whole gate is synchronous — physics rays and one navmesh query — so it adds
**no async round-trip** to a sit, no timer, and cannot be overtaken by a second
Activate mid-chain.

## Movement input stands you up

The reported "safer but feels bad or unresponsive" was real: while seated the
movement override swallows input, so pushing forward did nothing. The override
stays — releasing it lets a seated player slide out of the chair before
anything notices — and the first movement press now stands them up in the same
frame. `registerActionHandler` fires on value change, so this costs nothing per
frame and adds no timer. A press during the sit-down clip is ignored, so the
transition is not cut in half.

**The action names are not guessed.** `input.actions` is the engine's own
registry of named actions, so only names this build actually has are bound, and
the mod prints one line at load saying what it bound and what was missing:

```
[sit] stand up on movement: MoveForward, MoveBackward, MoveLeft, MoveRight, Jump
```

A handler registered against a name the engine does not have would never fire
and never say so — the same silent failure as an animation group a `.kf` does
not declare. If this build has no named actions at all, the line says that and
Activate still stands you up.

**Please check that line in your log on the first run** — it is the one thing
here that cannot be verified without the engine.

## New file

`scripts/take_a_seat/seat_safety.lua` holds all of the above decision-making
and **requires no openmw module**: `nearby`, `util` and the agent-bounds getter
are passed in. That is what lets `tools/test_exit_safety.lua` drive it against
a scripted world — a cramped interior, a stairwell, a hole in the floor, a
navmesh that answers across the room, a knocked-over chair — rather than
asserting on comments.

Two things from the Procedural Chatter pair deliberately **not** copied: its
per-frame re-teleport while seated, and its `pcall` density.

## Fixed: a checker had stopped reading halfway through a file

Found while making the injected modules checkable, and worth more than the
feature that found it.

`api_sweep`, `globalcheck` and `ctxcheck` each stripped Lua comments **before**
string literals. `sitAnim_shared.lua` contains this, which is ordinary Lua:

```lua
error(("[take a seat] %s references unknown seat type '%s' -- " ..
       "add it to SEAT_TYPE or remove the row"):format(label, name))
```

The `--` inside that string starts a comment as far as a comment-first regex is
concerned, so the rest of the line was deleted — **including the quote that
closed the string**. Every double quote after that point then paired up one
position out, and whole stretches of real code were blanked as "string
contents" and never checked. `anim.PRIORITY` on line 191 was invisible to
`api_sweep`; planting `anim.PRIORITYY` there was reported as clean.

`tools/luastrip.py` replaces all three strippers with one left-to-right pass
that tracks state, handles long strings and long comments, and preserves
offsets and line numbers. With it, the planted `anim.PRIORITYY` is reported.

## api_sweep now checks injected modules too

Dependency injection is what makes `seat_safety.lua` and
`buildAnimProfiles(anim)` testable, and it also hid their engine calls from the
sweep: `env.nearby.castRay` parses as an ordinary table field. Worse than
elsewhere, because the mocks in the tests define whatever name the code asks
for, so a misspelling would pass the tests too.

`api_sweep` now takes an `INJECTED` table naming those prefixes and checks them
like any other API use — proven by planting `env.nearby.castRayy`, which it
reports. A file listed with a prefix it no longer uses fails an assertion
instead of quietly checking nothing; that assertion is also what caught the
stripper bug.

## Tests

`tools/run_check_all.py`: **15 jobs, 0 failed, 0 skipped.**

- `tools/test_exit_safety.lua` — new, 25 checks: the tipped-chair threshold and
  that it costs no rays, the ordinary case and its probe budget, the stairwell,
  the hole in the floor, the navmesh answering across the room, no navmesh at
  all (origin still allowed; invented candidates refused), candidate order and
  fall-through, the exit direction following the seated facing, the agent bounds
  being named in the query, and an older build with no navmesh query at all.
- `tools/test_targeting.lua` — the gate is the only caller of `commitSit`, the
  teleport is in the clip callback and happens once, controls release after it,
  the cell-change drop, and the action binding going through `input.actions`.

## Not in this release

- **Stage 6, the capsule versus the tabletop.** Still needs drift measured in
  game: sit at a table and watch whether the player creeps upward. If they do
  not, that stage is unnecessary, which is the best outcome.
- The pack still covers four seat types (`backed_chair`, `bench`, `stool`,
  `barstool`); CUSHION, BATH, THRONE and SINGLE_SEAT_BENCH take the raycast
  path.
- Beds remain off (`BEDS_ENABLED = false`).
