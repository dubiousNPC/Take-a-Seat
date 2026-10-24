# ProceduralChatter solver furniture profile pack

Status: generated geometry handoff, 2026-10-23

## What this pack is

`solver-profiles.json` is the complete authored geometry provider for the
current audited furniture corpus. It contains 478 model-keyed profiles:

- 189 sitting profiles
- 289 sleeping profiles
- 40 bunk sleeping profiles (included in the sleeping count)

The model key is a normalized VFS path such as
`meshes/f/furn_com_bunk_01.nif`. The pack is not keyed by a Morrowind record
ID. A record can use the profile when its placed object's model resolves to
that path.

The pack was built from the BSA, PTR, and OAAB mesh roots. The discovery fix
added `bunk` as a sleeping-surface token and added all ten previously omitted
bunk meshes. The two reported examples are present as:

- `meshes/f/furn_com_bunk_01.nif`
- `meshes/sky/f/sky_act_com_bunk_01.nif`

## Files

- `solver-profiles.json` — complete runtime projection. This is the file that
  belongs at `scripts/ProceduralChatter/Data/Furniture/Generated/`.
- `furniture_solver_profiles.audit.json` — solver/export audit data for the
  missing-only source projection. It contains diagnostics and provenance; it
  is not a runtime loader input.
- `README.md` — this document.
- `PACK-MANIFEST.json` — file hashes and generation counts.

The complete runtime JSON uses `contractVersion: 3`. The loader rejects a
different contract version rather than silently interpreting incompatible
coordinates.

## Coordinate contract: origins and roots

The solver imports each NIF in canonical mesh coordinates and preserves the
mesh object's origin. Every `slot.root` is an object-local GU offset from that
origin. It is already the solved NPC root position for the reference pose; it
is not a cushion-center measurement that still needs the normal legacy seat
offsets applied.

For an object with world position `P`, object rotation `R`, and placement scale
`S`, the authored runtime resolves a root as:

```text
worldRoot = P + R * (slot.root * S)
```

`S` is the object's scale clamped by the shared placement policy to `0.25`
through `4.0`. Do not apply a second mesh-origin translation or a second
world-space rotation to a root.

`slot.yaw` is relative to the furniture object's rotation. `0` means the
object-local `+Y` facing direction. The runtime converts it to the world
facing vector using the object's yaw plus the slot yaw. The generated sleeping
projection already converts the Blender preview yaw convention to the
OpenMW actor yaw convention; do not negate or add 180 degrees again.

### Sitting slots

For `interactionType: "sit"`, `slot.root` is the actor root used by the
reference `pcdbssit5` pose. Fixed seats use `facingPolicy: "fixed"`; free and
two-sided furniture carries `anchor` and `poseDelta` data for facing/approach
selection. The root remains the authoritative placement point in all cases.

### Sleeping slots

For `interactionType: "sleep"`, `slot.root` is the sleeper root for the
reference `slee8` pose. `slot.support` is the solved mattress/support-plane
position used to describe the surface; it is not a replacement root. Bunks
have two explicit slots, normally `sleep_bottom` and `sleep_top`, each with
its own root, support point, and yaw.

Example: `meshes/f/furn_com_bunk_01.nif` has two `bedType: "bunk"` slots. The
bottom root is approximately `{ x=13.756893, y=-0.102647, z=-28.838165 }` and
the top root is approximately `{ x=13.758574, y=-0.102012, z=70.028763 }`.

## Animation offsets and the important integration trap

The generated profiles are authored roots, so the authored catalog sets:

```text
finalRightOffset  = 0
finalForwardOffset = 0
finalZOffset       = 0
yawOffset          = 0
```

`referenceAnimation` (`pcdbssit5` for sitting and `slee8` for sleeping) is
metadata describing the pose used during the solve. It is not an instruction
to apply another animation correction to the root.

Do **not** run authored roots through the legacy `SeatPose.applySeatedPoseOffsets`
recipe. That legacy path starts from a surface hit and applies defaults around
`-36 GU` vertical and `-7 GU` forward, followed by legacy animation
normalization. In particular, the old `pcdbssit5` normalization row contributes
`+30 GU`; applying it to an authored root is the reason an earlier deployment
put NPCs roughly 30 GU above their furniture.

Do not copy these roots directly into legacy `FinalForwardOffset`,
`FinalZOffset`, or `HeightOffset` TSV fields. Legacy rows are surface-hit
offsets and have different semantics. If a consumer cannot use the authored
provider, it needs an explicit adapter and a separate visual validation pass.

## Runtime integration

The production authored loader reads:

```text
scripts/ProceduralChatter/Data/Furniture/Generated/solver-profiles.json
```

`FurnitureGeometryConfig.lua` must use `contractVersion = 3` and the authored
provider mode (`authored_primary` or the deliberately selected fallback mode).
The authored provider is model-keyed and takes precedence for models it
contains; existing legacy/scoped TSV rows remain a separate profile surface.
Do not append duplicate generated rows to `furnitureProfiles/` just to make
these models visible.

Integration checklist:

1. Copy only `solver-profiles.json` to the exact generated-data VFS path.
2. Keep the JSON contract version at `3`.
3. Confirm the loader reports 478 accepted rows, with 189 sit and 289 sleep
   rows, and that the two reported bunk model paths resolve.
4. Use an actual cell containing a bunk and inspect both bottom and top slots.
5. Verify a materially different bed and a non-bunk seat as a regression; do
   not infer general correctness from one bunk.
6. If an NPC is vertically or longitudinally displaced, first log the resolved
   authored root, object scale, object yaw, provider, and animation correction.
   Do not add a per-record offset before checking whether a legacy provider or
   animation correction was applied twice.

## Provenance and verification boundary

The 478-profile Blender batch completed `478/478` with zero import/solve
exceptions. The generated source projection validated `416` missing-only
profiles and the complete projection was checked as `468` unchanged profiles
plus exactly `10` new bunk profiles.

This handoff does not claim a fresh in-game visual placement pass for the
expanded pack. Runtime integration must independently verify the authored
provider in a furnished bunk cell and a materially different furniture case.
