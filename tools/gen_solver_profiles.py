#!/usr/bin/env python3
"""Generate scripts/take_a_seat/solver_profiles.lua from the solver pack.

The pack (`solver-profiles.json`, contractVersion 3) is the authored geometry
provider: 478 model-keyed profiles, of which 189 are sitting. Its roots are
SOLVED ACTOR ROOTS for the reference pose, not seat-surface measurements, so
nothing in this file may be mixed with the legacy TSV offsets
(FinalZOffset / FinalForwardOffset / HeightOffset) -- those have different
semantics and the pack says so in terms.

Both halves can be emitted. `--sleep` adds the 289 bed profiles, which the
bed path has used since v0.43; without it only the 189 sitting ones are written.

Everything the pack states about itself is asserted here rather than trusted at
runtime: contract version, profile counts, and that each slot carries the
fields the runtime contract needs. A pack that does not match stops the build.

Usage:
    gen_solver_profiles.py <solver-profiles.json> [out.lua] [--sleep]
"""
import json
import os
import sys

EXPECTED_CONTRACT = 3
EXPECTED_TOTAL = 478
EXPECTED_SIT = 189
EXPECTED_SLEEP = 289

# Seat types Take a Seat can classify. A pack seatType outside this set would
# silently classify furniture as nil at runtime, which is how the THRONE and
# BATH faults reached players before.
KNOWN_SEAT_TYPES = {
    'backed_chair', 'bench', 'stool', 'barstool',
    'single_seat_bench', 'cushion', 'throne', 'bath',
}
KNOWN_POLICIES = {'fixed', 'two_sided', 'free'}

# Bed types sitAnim_shared's BED_TYPE defines, each mapped to a sleep clip in
# BED_ANIM. A pack bedType outside this set reaches idleAnimFor as nil and
# plays no clip at all, which is the same silent-nil failure the seat-type
# assert above exists to stop.
KNOWN_BED_TYPES = {'single', 'double', 'bunk', 'bedroll', 'hammock'}


def num(v):
    """Lua literal for a coordinate. Rounded: the pack carries solver noise
    down to 1e-16, which is meaningless at Morrowind's unit scale and makes
    the generated file needlessly unreadable."""
    f = round(float(v), 4)
    if f == int(f):
        return str(int(f))
    return repr(f)


def lua_str(s):
    return "'" + str(s).replace('\\', '\\\\').replace("'", "\\'") + "'"


def main(argv):
    args = [a for a in argv if not a.startswith('--')]
    want_sleep = '--sleep' in argv
    src = args[0] if args else 'solver-profiles.json'
    out_path = args[1] if len(args) > 1 else 'scripts/take_a_seat/solver_profiles.lua'

    pack = json.load(open(src, encoding='utf-8'))
    contract = pack.get('contractVersion')
    assert contract == EXPECTED_CONTRACT, (
        'pack contractVersion is %r, this generator writes for %d. The runtime '
        'contract (worldRoot = P + R * (root * scale), yaw relative to the '
        'object) is version-specific -- do not bypass this.'
        % (contract, EXPECTED_CONTRACT))

    profiles = pack['profiles']
    assert len(profiles) == EXPECTED_TOTAL, (
        'pack has %d profiles, expected %d' % (len(profiles), EXPECTED_TOTAL))

    sit = [p for p in profiles if p.get('interactionType') == 'sit']
    sleep = [p for p in profiles if p.get('interactionType') == 'sleep']
    assert len(sit) == EXPECTED_SIT, 'sit profiles: %d, expected %d' % (len(sit), EXPECTED_SIT)
    assert len(sleep) == EXPECTED_SLEEP, (
        'sleep profiles: %d, expected %d' % (len(sleep), EXPECTED_SLEEP))

    wanted = sit + (sleep if want_sleep else [])

    # Validate before emitting: a missing root or yaw would place an actor at
    # the furniture origin with no indication why.
    unknown_types, unknown_policies, slot_count = set(), set(), 0
    unknown_beds, unfixed_beds = set(), []
    for p in wanted:
        st = (p.get('seatType') or '').lower()
        if p['interactionType'] == 'sit':
            if st not in KNOWN_SEAT_TYPES:
                unknown_types.add(st)
            pol = (p.get('facingPolicy') or '').lower()
            if pol not in KNOWN_POLICIES:
                unknown_policies.add(pol)
        else:
            bt = (p.get('bedType') or '').lower()
            if bt not in KNOWN_BED_TYPES:
                unknown_beds.add(bt)
            # Every bed in the pack is fixed-facing. A two_sided or free bed
            # would need anchor/poseDelta on its slots to re-derive a root for
            # a chosen facing, and the bed path never calls the facing chooser,
            # so one appearing here is a contract change, not a data detail.
            if (p.get('facingPolicy') or '').lower() != 'fixed':
                unfixed_beds.append('%s=%s' % (p.get('model'), p.get('facingPolicy')))
        for s in p['slots']:
            slot_count += 1
            assert 'root' in s and 'yaw' in s, (
                '%s slot %s has no root/yaw' % (p['model'], s.get('slotId')))
            for axis in ('x', 'y', 'z'):
                assert axis in s['root'], '%s root missing %s' % (p['model'], axis)
            # anchor and poseDelta travel together: the facing re-derivation
            # needs both or neither.
            assert ('anchor' in s) == ('poseDelta' in s), (
                '%s slot %s has one of anchor/poseDelta but not both'
                % (p['model'], s.get('slotId')))

    assert not unknown_types, (
        'pack names seat types Take a Seat does not define: %s'
        % ', '.join(sorted(unknown_types)))
    assert not unknown_policies, (
        'pack names facing policies this generator does not handle: %s'
        % ', '.join(sorted(unknown_policies)))
    assert not unknown_beds, (
        'pack names bed types Take a Seat does not map to a clip: %s'
        % ', '.join(sorted(unknown_beds)))
    assert not unfixed_beds, (
        'pack has beds that are not fixed-facing, which the bed path cannot '
        'place: %s' % ', '.join(unfixed_beds[:5]))

    ref_anims = sorted({p.get('referenceAnimation') for p in wanted if p['interactionType'] == 'sit'})
    sleep_refs = sorted({p.get('referenceAnimation') for p in wanted
                         if p['interactionType'] == 'sleep'})

    w = []
    w.append('---@omw-context none')
    w.append('--[[')
    w.append('    solver_profiles.lua -- GENERATED, do not edit by hand.')
    w.append('')
    w.append('    Authored seating geometry from the ProceduralChatter solver')
    w.append('    profile pack, contract version %d. Regenerate with' % contract)
    w.append('    tools/gen_solver_profiles.py.')
    w.append('')
    w.append('    KEYED BY MODEL, not by record id. A record uses a profile when its')
    w.append('    own record.model resolves to that path, which is why this covers')
    w.append('    furniture from mods this one has never heard of.')
    w.append('')
    w.append('    `root` is the SOLVED ACTOR ROOT for the reference pose (%s),'
             % ', '.join(str(a) for a in ref_anims))
    w.append('    in object-local game units. It is not a seat surface and not a')
    w.append('    cushion centre: there is no legacy -36 / -7 offset to apply on top.')
    w.append('')
    w.append('        worldRoot = objectPosition + objectRotation * (root * scale)')
    w.append('        worldYaw  = objectYaw + rad(yaw)')
    w.append('')
    w.append('    `yaw` is DEGREES relative to the object, 0 meaning object-local +Y.')
    w.append('    It already encodes which way a seated actor faces -- do not negate')
    w.append('    it and do not add 180 again.')
    w.append('')
    w.append('    `anchor`/`poseDelta` are present on slots whose facing is not fixed')
    w.append('    (two_sided, free). anchor is the seat point with the pose offset')
    w.append('    removed, so a root for a chosen facing is rebuilt from it.')
    if sleep_refs:
        w.append('')
        w.append('    BEDS (kind = \'sleep\') use the SAME contract, with `bedType`')
        w.append('    in place of `seatType` and named slots: sleep_main, or')
        w.append('    sleep_left/sleep_right for a double and sleep_bottom/sleep_top')
        w.append('    for a bunk. Every bed profile is fixed-facing, so the facing')
        w.append('    chooser is never consulted for one.')
        w.append('')
        w.append('    Their roots are solved for the reference pose (%s),'
                 % ', '.join(str(a) for a in sleep_refs))
        w.append('    which this mod does not ship -- it plays sleept1/2/5/6. That')
        w.append('    costs nothing, and the reason is measured rather than assumed:')
        w.append('    tools/kf_root_offsets.py on animations/xbase_anim/xSleepT.kf')
        w.append('    reports Bip01 (6.264, 0.782, 2.328) and Bip01 Pelvis')
        w.append('    (2.904, 0, 0) for every sleept*/sleepte* group, the same')
        w.append('    translations the seated reference carries. Morrowind animates')
        w.append('    bone rotations, not bone translations, so POSE_DELTA is empty')
        w.append('    for beds exactly as it is for seats.')
        w.append('')
        w.append('    Do NOT fold in the %s row from' % ', '.join(str(a) for a in sleep_refs))
        w.append('    sdp/animationNormalizationOffsets.txt (W=15, D=25, H=15): that')
        w.append('    file is pose normalization for SDP\'s calibration UI and says')
        w.append('    in its own header not to use it for bed placement.')
    w.append(']]')
    w.append('')
    w.append('local M = {}')
    w.append('')
    w.append('M.contractVersion = %d' % contract)
    w.append('')
    w.append('-- model -> profile')
    w.append('M.PROFILES = {')
    for p in sorted(wanted, key=lambda x: x['model'].lower()):
        model = p['model'].lower().replace('\\', '/')
        w.append('    [%s] = {' % lua_str(model))
        w.append('        kind = %s,' % lua_str(p['interactionType']))
        if p.get('seatType'):
            w.append('        seatType = %s,' % lua_str(p['seatType'].lower()))
        if p.get('bedType'):
            w.append('        bedType = %s,' % lua_str(p['bedType'].lower()))
        if p.get('facingPolicy'):
            w.append('        facing = %s,' % lua_str(p['facingPolicy'].lower()))
        w.append('        slots = {')
        for s in p['slots']:
            parts = ['id = %s' % lua_str(s.get('slotId') or 'default')]
            r = s['root']
            parts.append('root = { %s, %s, %s }' % (num(r['x']), num(r['y']), num(r['z'])))
            parts.append('yaw = %s' % num(s['yaw']))
            if 'anchor' in s:
                a, d = s['anchor'], s['poseDelta']
                parts.append('anchor = { %s, %s, %s }' % (num(a['x']), num(a['y']), num(a['z'])))
                parts.append('poseDelta = { %s, %s, %s }' % (num(d['x']), num(d['y']), num(d['z'])))
            w.append('            { %s },' % ', '.join(parts))
        w.append('        },')
        w.append('    },')
    w.append('}')
    w.append('')
    w.append('return M')

    os.makedirs(os.path.dirname(out_path) or '.', exist_ok=True)
    open(out_path, 'w', encoding='utf-8').write('\n'.join(w) + '\n')

    print('%s: contract %d, %d profile(s), %d slot(s)%s'
          % (out_path, contract, len(wanted), slot_count,
             '' if want_sleep else ' (sit only; --sleep to include beds)'))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
