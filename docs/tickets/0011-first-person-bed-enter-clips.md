# 0011: No bed enter clips in first person (asset)

- **Status:** open (degrades cleanly)

The `.1st` copies of `xSleepT.kf` carry `sleept1..6` only, with no `sleepte*`. v0.43 falls back to the held pose: lying down from first person has no transition, but the pose and stand-up are correct (8 of 8 in-engine). Authoring `sleepte1..6` in the three `.1st` folders would give first person the lie-down.
