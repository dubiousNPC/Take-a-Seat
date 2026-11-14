# 0006: The bed's Rest menu opens on top of the lie-down

- **Status:** fixed on `fixes-v0.44`
- **Severity:** medium (UX)

## Symptom
On beds whose vanilla `Bed_Standard` script fires (reliably `active_de_p_bed_09`, Ald-ruhn Fighters Guild), the same press lay down **and** opened Rest. `chargen_bed` raises its message box.

## Fix
- A global `I.Activation.addHandlerForType(types.Activator, ...)` returns `false` for a bed (record or pack model) activated by the player, but only for the press that lies down.
- New setting **"Activate on a bed lies down"** (default on). On: Activate lies down and Sneak + Activate is the vanilla bed (Rest). Off: the reverse.
- The player script reports the current mode to the global script (`TakeASeat_BedActivateMode`) on a 0.05 s timer, on a settings change, and on every Activate press.
- Unit tests are in `test_standup.lua`. The in-engine check is `tas_bed_rest.lua`.

## Note
With plain Activate set to lie down, a bed the safety gate refuses ("no room to get up") no longer falls through to Rest. Use Sneak + Activate there.
