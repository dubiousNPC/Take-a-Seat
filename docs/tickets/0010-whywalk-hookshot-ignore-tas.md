# 0010 (cross-mod): WhyWalk and Hookshot act while the player is seated

- **Status:** fixed on local branches. WhyWalk `take-a-seat-interop` (`8fa4b37`) and Hookshot-Redux `take-a-seat-interop` (`938f5d3`), both on top of the 2026-11-13 uploads.
- **Severity:** high

## Symptom
- `ww_cross_owner` case A: seated and mounted at once (`seated=true mounted=true`).
- `ww_boat_seating` case 3: seated, then asked to board.
- Nothing in WhyWalk, Hookshot or FLOW referenced Take a Seat.

## Fix
- **WhyWalk Core (player):**
  - An Activate press while `I.TakeASeat.isBusy()` belongs to Take a Seat, which stands you up; WhyWalk no longer mounts on it too.
  - The player script relays `TakeASeat_Seated` and `TakeASeat_StandComplete` to the global scripts as `WhyWalk_PlayerSeated`, and reports again after a load.
- **WhyWalk Core (global):** a mount request while seated is refused with `WhyWalk_MountRefused { reason = 'seated' }` ("Get up first.").
- **WhyWalk Boats:**
  - `board()` refuses with `WWBoats_Refused { reason = 'seated' }`.
  - The player's Activate path is skipped while seated.
- **Hookshot:** drawing (from IDLE) and firing are refused with "Get up first" while `isBusy()`. An absent or erroring interface counts as free.

## Verified (OpenMW 0.52 RC1, real data)
| check | result |
|---|---|
| `tas_interop44` (Activate on a guar while seated; mount by event while seated, mid stand-up, after StandComplete; hookshot draw and fire while seated; draw after standing) | 13 / 13 |
| `ww_cross_owner` | **20 / 20** (case A now passes: `refused seated`) |
| `ww_boat_seating` | 14 / 14 |
| `arena_interop`, `arena_states`, `ww_mount_flow`, `ww_seat_transitions`, `boat`, `tas_flow` | 11/11, 19/19, 16/16, 7/7, 4/4, 39/39 |
| `ww_mount_transitions` | 76/84 and 79/84 patched, against 79/84 and 82/84 for the unmodified upload. The failures are the same flaky creature family both ways (durzog climb speed, cliff racer and clannfear seat height, netch put-down), so they are not from this change. |
| WhyWalk Core `check_all.sh` | all pass except `check_anims` on `wwrun1` (known asset issue, reported in 12c) |
| WhyWalk Boats `check_all.sh` | 69 / 69 |
| Hookshot suite under LuaJIT | 100 / 100, including the new `seat_gate_test.lua` (7) |
