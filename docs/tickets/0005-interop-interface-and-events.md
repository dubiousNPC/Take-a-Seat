# 0005: Other mods can't query the seated state; the events are thin and mistimed

- **Status:** fixed on `fixes-v0.44`
- **Severity:** high for interop (WhyWalk mount and board while seated, cases A and E)

## Before
- There was no interface.
- `TakeASeat_Seated` had `seatType = nil` for beds, no kind or slot, and a mixed-case `animGroup`.
- `TakeASeat_Stood {}` was empty, sent at the start of getting up, and never sent on load.

## Fix
- **`I.TakeASeat` v1:**
  - `isSeated()`;
  - `isBusy()` (seated, or still getting up);
  - `getState()` returns `{phase = entering|seated|standing, kind, subType, furniture, slot, animGroup}`;
  - `standUp()`.
- **`TakeASeat_Seated`:** adds `kind`, `subType` and `slot`. `animGroup` is lowercase.
- **`TakeASeat_Stood`:** `{furniture, kind, subType, slot, reason = activate|move|api|load}`.
- **New `TakeASeat_StandComplete`:** sent when both the clip and the glide have finished (controls and collision back).
- **On load:** if the save was made seated, both events are sent with `reason = 'load'`.
- The README "For other mods" section documents all of it.

## Remaining (other repos)
See 0010: WhyWalk and Hookshot should call `I.TakeASeat.isBusy()` / `standUp()` before mounting, boarding or firing.
