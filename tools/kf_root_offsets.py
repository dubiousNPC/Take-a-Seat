#!/usr/bin/env python3
"""kf_root_offsets.py -- measure the root-bone offset of each animation group.

Why this exists. Every authored root in the solver pack is solved for ONE
reference pose, `pcdbssit5` (= `dbssit5`). Take a Seat plays a different seated
clip per seat type (`dbssit4` on benches, `dbssitting24` on stools, `dbssit6` on
barstools, `dbssit8` on thrones, `dbssit2` in baths, `rasit6` on cushions), and
each clip puts the body somewhere slightly different relative to the actor's
root. Placing the root from the pack and then playing a clip the pack never
solved for moves the body by that difference.

That difference is measurable rather than arguable: it is the Bip01 translation
at the clip's first keyframe, and it is sitting in the shipped `.kf` files.

    world(body) = root + R * bip(clip)

so to put clip B's body where the reference clip's body would have been:

    POSE_DELTA[B] = bip(reference) - bip(B)          (actor space)

which is what this prints, ready to paste into sitAnim_shared's POSE_DELTA.

Morrowind `.kf` (NIF 4.0.0.2) layout used here: blocks are a length-prefixed
type name followed by that type's fields. Block boundaries are found by
scanning for the length-prefixed type names, which avoids having to parse every
block type correctly to reach the one that matters. The first
NiKeyframeController in a Morrowind keyframe file targets the first bone named
in the extra-data chain, which in every skeleton this mod ships is Bip01 -- the
tool checks that and says so.

Measured result for this mod (see VERSION.md v0.39): across every seated clip
it plays -- dbssit2/4/5/6/8 in xdbssitting.kf, dbssitting24 in xSitting2.kf and
rasit6 in xdbsRAsitting1.kf -- the root and the pelvis have the SAME
translation and the SAME rotation. Morrowind animates bone rotations, not bone
translations, and these poses only start to differ at the spine. So the hips
land in the same place whichever seated clip plays, the pack's pcdbssit5-solved
roots are valid for all of them, and POSE_DELTA is empty because it was
measured to be zero, not because nobody looked.

Usage:
    kf_root_offsets.py <file.kf> [more.kf ...] [--ref GROUP] [--groups a,b,c]
                       [--bone NAME] [--ref-file file.kf]

The bone defaults to Bip01 (the root). `Bip01 Pelvis` is the other one worth
asking about, because that is what touches the seat. --ref-file compares
against a group in another file, which is how a clip in xSitting2.kf gets
compared with one in xdbssitting.kf; both are in the same skeleton's space, so
the comparison is meaningful.
"""
import math
import os
import re
import struct
import sys

BLOCK_NAME = re.compile(rb'[A-Za-z][A-Za-z0-9_]{4,39}')
TEXTKEY = re.compile(r'^([A-Za-z][\w ]*?)\s*:\s*(start|stop|loop start|loop stop)\b',
                     re.IGNORECASE)


def blocks(data):
    """[(type, start, end)] for every NIF block, found by its type name."""
    out = []
    i = 0
    while i < len(data) - 4:
        n = struct.unpack_from('<I', data, i)[0]
        if 5 <= n <= 40 and i + 4 + n <= len(data):
            raw = data[i + 4:i + 4 + n]
            if BLOCK_NAME.fullmatch(raw) and raw.startswith(b'Ni'):
                out.append([raw.decode('ascii'), i + 4 + n, None])
                i += 4 + n
                continue
        i += 1
    for k in range(len(out)):
        # A block's data runs to the start of the next block's name.
        out[k][2] = (out[k + 1][1] - len(out[k + 1][0]) - 4
                     if k + 1 < len(out) else len(data))
    return [tuple(b) for b in out]


def text_keys(data, span):
    """[(time, text)] from a NiTextKeyExtraData block."""
    start, end = span
    # NiExtraData: next extra ref (int), bytes remaining (uint32), then
    # numTextKeys (uint32) and the keys themselves.
    off = start + 8
    count = struct.unpack_from('<I', data, off)[0]
    off += 4
    keys = []
    for _ in range(count):
        if off + 8 > end:
            break
        t = struct.unpack_from('<f', data, off)[0]
        n = struct.unpack_from('<I', data, off + 4)[0]
        off += 8
        if n > end - off:
            break
        keys.append((t, data[off:off + n].decode('ascii', 'replace')))
        off += n
    return keys


def translations(data, span):
    """[(time, (x, y, z))] from a NiKeyframeData block."""
    off, end = span
    nrot = struct.unpack_from('<I', data, off)[0]
    off += 4
    if nrot:
        rtype = struct.unpack_from('<I', data, off)[0]
        off += 4
        if rtype == 4:                      # XYZ rotation: three float key groups
            for _ in range(3):
                n = struct.unpack_from('<I', data, off)[0]
                off += 4
                ktype = struct.unpack_from('<I', data, off)[0] if n else 1
                off += 4 if n else 0
                per = {1: 8, 2: 16, 3: 20}[ktype]
                off += n * per
        else:
            per = {1: 20, 2: 20, 3: 32}[rtype]   # time + quat (+ TBC)
            off += nrot * per
    ntrans = struct.unpack_from('<I', data, off)[0]
    off += 4
    keys = []
    if ntrans:
        ttype = struct.unpack_from('<I', data, off)[0]
        off += 4
        per = {1: 16, 2: 40, 3: 28}[ttype]   # time + vec3 (+ tangents / TBC)
        for i in range(ntrans):
            base = off + i * per
            if base + 16 > end:
                break
            t, x, y, z = struct.unpack_from('<4f', data, base)
            keys.append((t, (x, y, z)))
    return keys


def sample(keys, t):
    """Linear sample of a translation track, which is what the engine does
    between keys of a LINEAR track and is accurate enough at a clip's start
    (groups begin on a key, not between two)."""
    if not keys:
        return None
    if t <= keys[0][0]:
        return keys[0][1]
    if t >= keys[-1][0]:
        return keys[-1][1]
    for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
        if t0 <= t <= t1:
            f = 0.0 if t1 == t0 else (t - t0) / (t1 - t0)
            return tuple(a + (b - a) * f for a, b in zip(v0, v1))
    return keys[-1][1]


def rotation_keys(data, span):
    """[(time, (w, x, y, z))] from a NiKeyframeData block."""
    off, end = span
    n = struct.unpack_from('<I', data, off)[0]
    off += 4
    if not n:
        return []
    rtype = struct.unpack_from('<I', data, off)[0]
    off += 4
    if rtype == 4:
        return []                       # XYZ tracks: not compared here
    per = {1: 20, 2: 20, 3: 32}[rtype]
    out = []
    for i in range(n):
        if off + i * per + 20 > end:
            break
        t, w, x, y, z = struct.unpack_from('<5f', data, off + i * per)
        out.append((t, (w, x, y, z)))
    return out


def quat_sample(keys, t):
    v = sample([(tt, q) for tt, q in keys], t)
    if v is None:
        return None
    n = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / n for c in v)


def quat_angle(a, b):
    """Angle between two orientations, in degrees."""
    dot = abs(sum(x * y for x, y in zip(a, b)))
    return math.degrees(2 * math.acos(min(1.0, dot)))


def read(path):
    """(bones, starts) -- per-bone tracks and each group's start time.

    The bone names come from the extra-data chain and the tracks from the
    NiKeyframeData blocks, paired by document order. The counts have to match
    for that pairing to mean anything, so it is checked.
    """
    data = open(path, 'rb').read()
    bl = blocks(data)
    tk = next((b for b in bl if b[0] == 'NiTextKeyExtraData'), None)
    if not tk:
        raise SystemExit('%s: no text keys' % path)

    names = []
    for name, s, e in bl:
        if name == 'NiStringExtraData':
            n = struct.unpack_from('<I', data, s + 8)[0]
            names.append(data[s + 12:s + 12 + n].decode('ascii', 'replace'))
    spans = [(s, e) for name, s, e in bl if name == 'NiKeyframeData']
    if len(names) != len(spans):
        raise SystemExit('%s: %d bone name(s) but %d keyframe block(s) -- the '
                         'document-order pairing does not hold, do not trust '
                         'per-bone numbers from this file'
                         % (path, len(names), len(spans)))

    bones = {}
    for name, span in zip(names, spans):
        bones[name] = (translations(data, span), rotation_keys(data, span))

    starts = {}
    for t, text in text_keys(data, (tk[1], tk[2])):
        for line in text.splitlines():
            m = TEXTKEY.match(line.strip())
            if m and m.group(2).lower() == 'start':
                starts.setdefault(m.group(1).strip().lower(), t)
    return bones, starts


def main(argv):
    ref, ref_file, bone, want = 'dbssit5', None, 'Bip01', None
    args = []
    i = 0
    while i < len(argv):
        if argv[i] == '--ref' and i + 1 < len(argv):
            ref = argv[i + 1].lower(); i += 2
        elif argv[i] == '--ref-file' and i + 1 < len(argv):
            ref_file = argv[i + 1]; i += 2
        elif argv[i] == '--bone' and i + 1 < len(argv):
            bone = argv[i + 1]; i += 2
        elif argv[i] == '--groups' and i + 1 < len(argv):
            want = [x.strip().lower() for x in argv[i + 1].split(',') if x.strip()]
            i += 2
        else:
            args.append(argv[i]); i += 1
    if not args:
        raise SystemExit(__doc__)

    base_t = base_q = None
    if ref_file:
        rbones, rstarts = read(ref_file)
        if ref not in rstarts:
            raise SystemExit('%s does not declare %r' % (ref_file, ref))
        tr, rk = rbones[bone]
        base_t, base_q = sample(tr, rstarts[ref]), quat_sample(rk, rstarts[ref])
        print('reference: %s %s in %s\n' % (ref, bone, os.path.basename(ref_file)))

    rc = 0
    for path in args:
        bones, starts = read(path)
        if bone not in bones:
            print('=== %s\n    no track for %s' % (os.path.basename(path), bone))
            rc = 1
            continue
        trans, rots = bones[bone]
        print('=== %s   bone %s, %d translation key(s), %d rotation key(s)'
              % (os.path.basename(path), bone, len(trans), len(rots)))
        t0, q0 = base_t, base_q
        if t0 is None and ref in starts:
            t0 = sample(trans, starts[ref])
            q0 = quat_sample(rots, starts[ref])
        if t0 is None:
            print('    reference group %r is not here and no --ref-file given; '
                  'printing raw values' % ref)
        for g in (want or sorted(starts)):
            if g not in starts:
                print('    %-16s not in this file' % g)
                rc = 1
                continue
            v = sample(trans, starts[g])
            q = quat_sample(rots, starts[g])
            if v is None:
                print('    %-16s no translation track' % g)
                continue
            if t0 is None:
                print('    %-16s t=%6.3f  pos=(%8.3f, %8.3f, %8.3f)'
                      % (g, starts[g], *v))
                continue
            d = tuple(b - a for a, b in zip(v, t0))
            turn = quat_angle(q, q0) if (q and q0) else float('nan')
            print('    %-16s t=%6.3f  pos=(%8.3f, %8.3f, %8.3f)  '
                  'vs %s: move { x = %.3f, y = %.3f, z = %.3f }  turn %.2f deg'
                  % (g, starts[g], *v, ref, *d, turn))
        print()
    return rc


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
