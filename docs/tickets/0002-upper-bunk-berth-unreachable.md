# 0002: The upper bunk berth can never be chosen

- **Status:** fixed on `fixes-v0.44`
- **Severity:** medium

## Symptom
On all 4 vanilla bunks, approaching the `sleep_top` side put the player in `sleep_bottom` (0.0 units from its root).

## Cause
`nearestSlot` measures from the player's feet. From the floor, the lower berth is always nearer.

## Fix
For sleep profiles, the slot nearest the aim point (`I.SharedRay` hit on that bed) wins, with a fallback to the feet. Seats still choose from the feet, which is what their two-sided benches expect. Tests in `test_solver_profiles.lua`: no aim gives the lower berth; aiming high gives the upper; aiming low gives the lower; an aim at another object is ignored; benches are unchanged.
