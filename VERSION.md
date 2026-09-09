# Take a Seat v0.20

Sit on furniture. Raycast-resolved seat surface, per-record pivot offsets, and a
settling camera — with no `onFrame` handler anywhere.

---

## Two bugs fixed in this version

### 1. Female characters could not sit — no animation at all

`animations/xbase_anim_female/` **did not exist**. The other three skeleton
folders were present and each declared the same 31 groups; the female one was
simply absent.

OpenMW resolves additional animation sources **per skeleton**: a female actor
uses `xbase_anim_female.nif` and therefore looks in
`animations/xbase_anim_female/`. There is no fallback to `animations/xbase_anim/`.
So every one of the six groups this mod plays was unavailable to female
characters — and `playBlended` on a group the skeleton does not define is a
**silent no-op**, so the seat resolved, the camera settled, the state machine
advanced, and the character never changed pose.

Fixed by shipping the three `.kf` files in the female folder too. The clips are
skeleton-compatible, which is why the other mods in this suite ship the same
file in all four folders.

```
  ABSENT    xbase_anim_female    no such folder      <- before
  ok        xbase_anim_female    3 file(s), 31 group(s)   <- after
```

### 2. A debug line that crashes the moment you enable debugging

`take_a_seat.lua:399` had an **unescaped quote** inside a string literal:

```lua
print(string.format("[sit] TIP: if correct, add SIT_PIVOT_OFFSET["%s"] = %.1f to sitAnim_shared.lua",
```

The literal ends at `SIT_PIVOT_OFFSET[`. Lua then reads `% s "..."` as a modulo
followed by a **call to an undeclared global `s`** — which is valid syntax, so
it parses cleanly and `luacheck` passes it. It raises at runtime:

```
attempt to call a nil value (global 's')
```

`DEBUG` is `false`, so it is latent — but the branch it sits in exists purely to
print the tip telling you what `SIT_PIVOT_OFFSET` value to add for a new chair.
It would fire the first time anyone turned debugging on to tune a pivot, which
is the one moment it is guaranteed to be in the way.

Quotes escaped, with the reason recorded at the call site.

Worth noting which tool caught it: **`check_names.py`, and only that one.**
`luacheck` passes because it parses; `globalcheck.py` missed it because `s`
appears in a *call* position rather than an index, and its candidate pattern is
tuned for reads (RESEARCH §4.4).

---

## One removal

`sliderAvailable()` wrapped `installedRenderers:get("SuperSlider")` in a
`pcall`. `storage.playerSection` is available in this context and creates the
section on demand, and `:get` on an absent key returns `nil` — which is exactly
the case being tested for. The wrap could only ever hide a genuine storage error
behind the same `nil` the absent-renderer path already produces (RESEARCH §2.4).

**The mod's own scripts now contain zero `pcall`s.** The two remaining in the
package are the subscriber-callback isolation in `AnimRefresh_v2.lua` and
`SharedRay_v2.lua` — third-party callback boundaries, the justified case
(RESEARCH §2.3).

---

## Verification

Cod3x 0.4. Everything below run against this package.

| Check | Result |
|---|---|
| `luacheck.py` — syntax | 5 files, **0 failures** |
| `globalcheck.py` — undeclared globals | **0** |
| `check_names.py` — undefined names, unused requires | **clean** (was 1 finding — see above) |
| `api_sweep.py` — every `module.member` vs Cod3x 0.4 | **nothing unrecognised** |
| `ctxcheck.py` — `---@omw-context` vs the 0.4 policy | 5 files, **0 issues** |
| `check_manifest.py` — one path, one flag set | **0 mismatches** |
| `check_anims.py` — groups played vs groups shipped | **0 unplayable** (was 6) |
| `pcall` in `scripts/take_a_seat/` | **none** |

### `check_anims.py` is new

Written for this review, and it is the analogue of `check_bones.py` for IED.
Nothing else in the toolchain opens a `.kf`, so nothing else could see that six
groups were unplayable for half of all characters.

It reads text keys out of every shipped `.kf` — OpenMW takes the group name from
the part before the colon, so `dbssit4: start` declares group `dbssit4` — and
cross-references them against the group-name literals in the Lua. It reports
**per-skeleton-folder** coverage rather than a single union, because the usual
failure is not a typo but a skeleton variant nobody made files for.

```
python3 tools/check_anims.py . --groups "dbssit4,dbssit5,dbssit6,dbssit8,dbssitting24,rasit6"
```

### Tools that were missing

`tools/` did not exist. All the checkers above are now included.

---

## What is already right, and worth not regressing

- **No `onFrame`, anywhere.** Every path is entered from a discrete event:
  activation, an `addAnimationEndedHandler` callback, an
  `async:newUnsavableSimulationTimer` for the camera settle, and
  `time.runRepeatedly` at 1 s for fatigue regen. The header says so and the code
  matches it.
- **`time.runRepeatedly` is started at init**, not on sit — it stops evaluating
  across a save load otherwise, and the comment says why.
- **`SharedRay_v2` and `AnimRefresh_v2` are bundled and version-guarded**, so
  only the newest loaded copy runs.
- **`MOD_ANIM_DATABASE` is an empty commented template**, not a live table with
  a placeholder id in it. The `yourpack_sit_floor_01` name is inside a comment
  and is correctly ignored by the group check.

---

## Not addressed

- **No `README.md`, `LICENSE` or `l10n/`.** The settings page builds its labels
  from literal strings rather than l10n keys, which is self-consistent — there
  is no `l10n` context declared on the group — so this is a packaging gap rather
  than a bug.
- The `.1st` folder names two of its three files `*.1st.kf` and one plain
  `xSitting2.kf`. Filenames do not affect group resolution — OpenMW scans every
  `.kf` in the folder — so this is cosmetic, but the inconsistency is the kind
  of thing that later reads as significant.
