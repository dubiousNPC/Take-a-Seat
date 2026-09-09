# Take a Seat v0.21

Sit on furniture. Raycast-resolved seat surface, per-record pivot offsets, and a
settling camera — with no `onFrame` handler anywhere.

---

## The mod did nothing. Here is why.

```
[17:45:15 E] Can't start L@0x1[scripts/take_a_seat/take_a_seat.lua];
             Lua error: [scripts/take_a_seat/sitanim_shared.lua]:66:
             table index is nil
```

`sitAnim_shared.lua` declared six seat types and then keyed a seventh:

```lua
local SEAT_TYPE = { BACKED_CHAIR=..., BENCH=..., STOOL=...,
                    BARSTOOL=..., SINGLE_SEAT_BENCH=..., CUSHION=... }
local T = SEAT_TYPE

local SEAT_ANIM = {
    ...
    [T.THRONE] = "dbssit8",     -- THRONE was never defined
}
```

`T.THRONE` is `nil`, and `[nil] = "dbssit8"` inside a table constructor raises
**while the chunk is still loading**. The module never returned, so
`take_a_seat.lua` could not start, so nothing was listening for activation.
The global script loaded fine and logged cheerfully — which is why the log looks
almost normal.

`THRONE` was referenced **twice**: as that key, and in the pattern rules at line
233 (`{ seat = T.THRONE, patterns = { "throne" } }`). The second would have
failed more quietly still, classifying every throne as seat type `nil`. So the
type was missing, not the entry — `THRONE = "throne"` is now defined and both
uses work. `dbssit8` is a real group present in all four skeletons.

A stale comment claiming "throne is a backed chair" contradicted both uses and
has been corrected.

---

## This was in v0.20, and my checks missed it

Worth stating plainly, because the interesting part is not the typo.

The bug shipped past **six** checkers — syntax, undeclared globals, undefined
names, an API sweep against Cod3x 0.4, a context check and a manifest check.
Not one of them caught it, for one reason:

> **Not one of them ever RAN the file.**

`luacheck` proves a file *parses*. `[nil] = x` parses perfectly. It is a runtime
error at chunk level, and the only way to see it is to execute the chunk.

`check_anims.py` made it worse rather than better. It reported `dbssit8` as
`ok` — because I passed the group list on the command line by hand. It validated
a list I typed rather than the list the code defines, so it confirmed the
animation existed while the code that names it was dead. That is RESEARCH §4.1's
"a mock that accepts everything tests nothing", wearing a different hat: a
checker fed by hand instead of by the artifact.

### `check_load.py` is the answer

New tool. It loads every module with `openmw.*` and `openmw_aux.*` stubbed and
reports anything that raises at chunk level — table constructors, concatenation
on a nil, a missing project-local require, any top-level call.

```
  LOAD    scripts/take_a_seat/sitAnim_shared.lua
            sitAnim_shared.lua:66: table index is nil
  LOAD    scripts/take_a_seat/take_a_seat.lua
            sitAnim_shared.lua:66: table index is nil
```

Same file, same line number as the engine.

Building it took three passes, and each correction is a rule in its own right:

- **The stub must be comparable.** `I.AnimRefresh.version >= MY_VERSION`
  compares a number against the stub. Without `__lt`/`__le`, every bundled
  shared library reported a false failure — and a checker that cries wolf gets
  switched off (RESEARCH §4.4).
- **The stub must return `nil` for numeric keys.** `sitAnim_shared.lua:285`
  runs `for _, file in ipairs(core.contentFiles.list)` at chunk level. With a
  stub that answers every index, `ipairs` never runs out and the checker hangs
  forever. A checker that hangs is worse than one that misses.
- **Project-local requires must resolve for real**, or a load error *inside*
  `sitAnim_shared` hides behind a require failure in `take_a_seat`.

It stubs generously on purpose: a clean result does not prove a module is
correct, but a **failure is always real**.

---

## Verification

Cod3x 0.4. Everything run against this package.

| Check | Result |
|---|---|
| `luacheck.py` — syntax | 5 files, **0 failures** |
| `check_load.py` — **chunk executes** | 5 files, **0 failures** (was 2) |
| `globalcheck.py` — undeclared globals | **0** |
| `check_names.py` — undefined names, unused requires | **clean** |
| `api_sweep.py` — every `module.member` vs Cod3x 0.4 | **nothing unrecognised** |
| `ctxcheck.py` — `---@omw-context` vs the 0.4 policy | 5 files, **0 issues** |
| `check_manifest.py` — one path, one flag set | **0 mismatches** |
| `check_anims.py` — groups played vs groups shipped | **0 unplayable** |
| `pcall` in `scripts/take_a_seat/` | **none** |

---

## Carried over from v0.20

- **Female characters can sit.** `animations/xbase_anim_female/` did not exist;
  OpenMW resolves animation sources per skeleton with no fallback, so all six
  groups were unavailable to female characters and `playBlended` on an undefined
  group is a silent no-op. The three `.kf` files now ship in all four folders.
- **The debug tip line no longer crashes.** An unescaped quote made Lua read
  `% s "..."` as a call to an undeclared global `s` — valid syntax, so it parsed,
  and it raised the moment `DEBUG` was turned on. Which is the one moment it was
  guaranteed to be in the way, since that branch exists to print the tip you
  turn debugging on to read.
- **Zero `pcall`s in the mod's own scripts.** The two in the package are the
  subscriber-callback isolation in `AnimRefresh_v2` and `SharedRay_v2` — the
  justified third-party-boundary case.

## Still not addressed

No `README.md` or `l10n/`. The settings page builds labels from literal strings
with no `l10n` context declared on the group, so that is self-consistent — a
packaging gap rather than a bug.
