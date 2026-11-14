# 0008: `test_solver_profiles.lua` fails about 1 run in 8 under Lua 5.4

- **Status:** fixed on `fixes-v0.44`

## Cause
Two fixtures were picked with `pairs()` over `solver.PROFILES`: "a fixed-facing profile" and "a multi-slot profile". Since v0.43 those can be two-slot beds, and Lua 5.4 randomises the string-hash seed, so the pick changes between runs. Measured on v0.43: 1 failure in 8 runs ("a one-seat profile returns its slot").

## Fix
The fixtures now require a non-sleep, one-slot profile and a non-sleep multi-slot profile. Measured: 8 runs out of 8 pass.
