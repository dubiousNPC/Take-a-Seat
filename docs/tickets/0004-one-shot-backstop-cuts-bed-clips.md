# 0004: The fixed 1.5 s one-shot backstop cuts the bed clips short

- **Status:** fixed on `fixes-v0.44`
- **Severity:** medium

## Symptom
- `sleepte1` (1.97 s) gave way to the idle after 1.50 to 1.59 s, every time.
- On getting up, the player left the bed 1.59 to 1.94 s in, while `getup1` (2.0 s) was still playing. That defeats the "get up in place, then step off" order.

## Fix
The backstop is now the clip's own length (`animation.getTextKeyTime` on `<group>: start` and `<group>: stop`) plus `ONE_SHOT_MARGIN = 0.25`. The fixed `ONE_SHOT_TIMEOUT` is used only when the keys can't be read. `test_oneshot.lua` covers `sleepte1`, `getup1` and the no-keys fallback.
