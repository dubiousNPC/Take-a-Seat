# Tickets

One file per finding. Status as of branch `fixes-v0.44`.

| # | title | status |
|---|---|---|
| [0001](0001-bed-pose-faces-wrong-way.md) | Lying backwards on beds (feet on the pillow) | fixed on `fixes-v0.44` (`BED_POSE_YAW`) |
| [0002](0002-upper-bunk-berth-unreachable.md) | The upper bunk berth can never be chosen | fixed on `fixes-v0.44` |
| [0003](0003-bed-type-precedence-and-hammocks.md) | Bunks and hammocks play the single pose | fixed on `fixes-v0.44` |
| [0004](0004-one-shot-backstop-cuts-bed-clips.md) | The fixed 1.5 s one-shot backstop cuts the bed clips short | fixed on `fixes-v0.44` |
| [0005](0005-interop-interface-and-events.md) | Other mods can't query the seated state; the events are thin and mistimed | fixed on `fixes-v0.44` |
| [0006](0006-vanilla-rest-menu-over-lie-down.md) | The bed's Rest menu opens on top of the lie-down | fixed on `fixes-v0.44` |
| [0007](0007-check-bed-surfaces-hardcoded-path.md) | `check_bed_surfaces.py` only runs on one machine | fixed on `fixes-v0.44` |
| [0008](0008-flaky-test-fixtures.md) | `test_solver_profiles.lua` fails about 1 run in 8 under Lua 5.4 | fixed on `fixes-v0.44` |
| [0009](0009-readme-stale.md) | The README is out of date on beds and events | fixed on `fixes-v0.44` |
| [0010](0010-whywalk-hookshot-ignore-tas.md) | WhyWalk and Hookshot act while the player is seated | fixed on local WhyWalk and Hookshot branches; verified in-engine |
| [0011](0011-first-person-bed-enter-clips.md) | No bed enter clips in first person (asset) | open (degrades cleanly) |
| [0012](0012-kna-xsitting2-broken-groups.md) | `xSitting2.kf` groups `dbssitting25` to `28` are broken in all six copies (asset) | open: relabel proposed; groups unused |
