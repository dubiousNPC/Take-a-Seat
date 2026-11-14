# 0012: `xSitting2.kf` groups `dbssitting25` to `28` are broken in all six copies (asset)

- **Status:** open. The proposed key fix is below. Take a Seat plays none of these groups, so nothing in game is affected today.
- **Correction (2026-11-13):** this was first logged as kna only. All six copies carry the same keys: `xbase_anim`, `xbase_anim_female`, `xbase_animkna`, and their `.1st` folders.

## The keys as shipped
```
12.300 dbssitting25: start        12.333 loop start   13.333 loop stop   13.367 dbssitting25: stop
                                  13.667 dbssitting26: loop start   14.667 dbssitting26: loop stop
14.700 dbssitting25: start   <-   14.967 dbssitting25: stop
                                  15.000 dbssitting27: loop start   16.000 dbssitting27: loop stop
16.033 dbssitting25: start   <-   16.300 dbssitting25: stop
                                  16.333 dbssitting28: loop start   17.333 dbssitting28: loop stop
17.367 dbssitting25: start   <-
```
Groups 21 to 25 all follow `start`, then `loop start` +0.033, `loop stop` +1.0, `stop` +0.033. The six "dbssitting25" keys after 13.367 fall exactly where 26, 27 and 28 need their `stop` and `start` keys. They look like copy-paste labels, so:
- `dbssitting25` reads 17.37 to 16.30 (its last start is after its last stop);
- 26, 27 and 28 have no `start` or `stop` at all.

## Proposed relabel (needs the author's confirmation)
| time | shipped | proposed |
|---|---|---|
| 13.633 | *(none)* | `dbssitting26: start` (missing; 26 is the only group without one) |
| 14.700 | `dbssitting25: start` | `dbssitting26: stop` |
| 14.967 | `dbssitting25: stop` | `dbssitting27: start` |
| 16.033 | `dbssitting25: start` | `dbssitting27: stop` |
| 16.300 | `dbssitting25: stop` | `dbssitting28: start` |
| 17.367 | `dbssitting25: start` | `dbssitting28: stop` |

Without the inserted 13.633 key, `dbssitting26` could also start at its `loop start` (13.667). The `getup1`/`getup2` key rewrite used in v0.43 (string length prefix plus time float, with no block size table in NIF 4.0.0.2) handles relabelling. Inserting a key also needs the `NiTextKeyExtraData` key count bumped.
