# 0003: Bunks and hammocks play the single pose

- **Status:** fixed on `fixes-v0.44`
- **Severity:** medium

## Symptom
In-engine audit of every SDP bed record:

| record | SDP | pack | played |
|---|---|---|---|
| `active_com_bunk_01/02`, `active_de_p_bed_03/09` | single | bunk (2 slots) | `sleept1` |
| `active_de_p_bed_28` | hammock | single | `sleept6` |
| `active_de_bed_29/30` (model-only, named "Hammock") | n/a | single | `sleept1` |

## Cause
`classify` checked the SDP record list first. The pack mislabels the three vanilla hammock meshes as single.

## Fix
- When the model has a pack profile, the pack's `bedType` wins. It is the same source as the slots being placed.
- `BED_TYPE_BY_MODEL` corrects `meshes/f/active_de_bed_28/29/30.nif` to hammock.
- The SDP list remains the source for beds with no pack profile.

## Follow-up
Correct those three rows in the solver pack upstream, then drop the overrides.
