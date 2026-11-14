#!/usr/bin/env python3
"""Validate the solver pack's bed roots against the real game meshes.

The pack states a contract that is falsifiable against geometry:

    worldRoot = objectPosition + objectRotation * (slot.root * scale)
    support   = root with z - 0.5

so `slot.root` is a point in the mesh's own frame that should sit just above
the sleeping surface and inside the mesh's footprint. This reads each bed mesh
out of the Morrowind/Tribunal/Bloodmoon BSAs (plus any loose mesh directory
given), accumulates the scene graph transforms, and drops a vertical ray
through the mesh at each slot's (x, y) to find the surface the slot claims to
rest on.

Vertex proximity is NOT used: a mattress is a box whose only vertices are at
its corners, so "the highest vertex within N units" reports a bedpost. The ray
does point-in-triangle in the xy plane and interpolates z on the triangle,
which is what the engine's own raycast does.

Visible geometry and collision geometry are reported separately. Anything under
a RootCollisionNode is collision; the engine rests a physics capsule on that,
but a lying body is posed against the visible mattress.

Usage:
    TAS_ES3_LIB=/path/to/io_scene_mw/lib \
    check_bed_surfaces.py <solver-profiles.json> <bsa-dir> [--loose DIR]
                          [--verbose] [--csv OUT.csv]
"""
import argparse
import collections
import json
import os
import sys
import tempfile

import numpy as np

# es3 (the NIF reader from Greatness7's io_scene_mw, its lib/ folder) is not
# vendored. Point TAS_ES3_LIB at that lib/ folder; the old fixed location is
# kept as a fallback so existing setups keep working (docs/tickets/0007).
for _lib in (os.environ.get('TAS_ES3_LIB'), '/home/claude/in/mw/io_scene_mw-master/lib'):
    if _lib and os.path.isdir(_lib):
        sys.path.insert(0, _lib)
        break
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    from es3 import nif as _probe  # noqa: F401,E402
except ImportError:
    raise SystemExit('check_bed_surfaces: the es3 NIF library was not found. Clone '
                     'https://github.com/Greatness7/io_scene_mw and set TAS_ES3_LIB to its lib/ folder.')

from es3 import nif          # noqa: E402
from bsa_read import Bsa     # noqa: E402


def as_matrix(obj):
    m = np.identity(4)
    m[:3, :3] = np.asarray(obj.rotation, dtype=np.float64) * float(obj.scale)
    m[:3, 3] = np.asarray(obj.translation, dtype=np.float64)
    return m


def triangles_of(stream):
    """(visible, collision) arrays of shape (N, 3, 3) in the root's frame."""
    root = stream.root
    world = {root: as_matrix(root)}
    collision = {root: False}
    for parent, node in root.descendants_pairs(breadth_first=True):
        world[node] = world[parent] @ as_matrix(node)
        is_col = (collision.get(parent, False)
                  or type(node).__name__ == 'RootCollisionNode'
                  or 'bounding box' in (getattr(node, 'name', '') or '').lower())
        collision[node] = is_col

    vis, col = [], []
    for node, matrix in world.items():
        data = getattr(node, 'data', None)
        if data is None:
            continue
        verts = getattr(data, 'vertices', None)
        tris = getattr(data, 'triangles', None)
        if verts is None or tris is None or len(verts) == 0 or len(tris) == 0:
            continue
        v = np.asarray(verts, dtype=np.float64)
        if v.ndim != 2 or v.shape[1] != 3:
            continue
        h = np.hstack([v, np.ones((len(v), 1))])
        wv = (h @ matrix.T)[:, :3]
        idx = np.asarray(tris, dtype=np.int64)
        if idx.ndim != 2 or idx.shape[1] != 3:
            continue
        if idx.max() >= len(wv):
            continue
        (col if collision.get(node, False) else vis).append(wv[idx])

    def stack(parts):
        return np.vstack(parts) if parts else np.zeros((0, 3, 3))
    return stack(vis), stack(col)


def surface_z(tris, x, y, ceiling=None):
    """Highest z of any triangle covering (x, y), at or below `ceiling`.

    `ceiling` makes this a DOWNWARD ray from just above the sleeper rather than
    a search for the globally highest surface. Without it a bunk's lower berth
    reports the mattress of the berth above it, which reads as the slot sitting
    ~90 units below its own surface.
    """
    if len(tris) == 0:
        return None
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    # barycentric coordinates in the xy plane
    v0x, v0y = b[:, 0] - a[:, 0], b[:, 1] - a[:, 1]
    v1x, v1y = c[:, 0] - a[:, 0], c[:, 1] - a[:, 1]
    det = v0x * v1y - v1x * v0y
    ok = np.abs(det) > 1e-12
    if not ok.any():
        return None
    safe = np.where(ok, det, 1.0)
    px, py = x - a[:, 0], y - a[:, 1]
    u = (px * v1y - v1x * py) / safe
    v = (v0x * py - px * v0y) / safe
    inside = ok & (u >= -1e-9) & (v >= -1e-9) & (u + v <= 1 + 1e-9)
    if not inside.any():
        return None
    za, zb, zc = a[:, 2], b[:, 2], c[:, 2]
    z = za + u * (zb - za) + v * (zc - za)
    z = z[inside]
    if ceiling is not None:
        under = z[z <= ceiling]
        if len(under):
            return float(under.max())
        return None
    return float(z.max())


def load_mesh(model, archives, loose):
    if loose:
        path = os.path.join(loose, model.replace('/', os.sep))
        if os.path.exists(path):
            stream = nif.NiStream()
            stream.load(path)
            return stream
    for bsa in archives:
        if model in bsa:
            # es3's loader takes a path, so the archive entry is staged.
            raw = bsa.read(model)
            fd, tmp = tempfile.mkstemp(suffix='.nif')
            try:
                with os.fdopen(fd, 'wb') as fh:
                    fh.write(raw)
                stream = nif.NiStream()
                stream.load(tmp)
                return stream
            finally:
                os.unlink(tmp)
    return None


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('pack')
    ap.add_argument('bsa_dir')
    ap.add_argument('--loose', default=None)
    ap.add_argument('--verbose', action='store_true')
    ap.add_argument('--csv', default=None)
    args = ap.parse_args(argv)

    archives = []
    for name in ('Morrowind.bsa', 'Tribunal.bsa', 'Bloodmoon.bsa'):
        path = os.path.join(args.bsa_dir, name)
        if os.path.exists(path):
            archives.append(Bsa(path))
    print('archives: %d' % len(archives))

    pack = json.load(open(args.pack, encoding='utf-8'))
    beds = [p for p in pack['profiles'] if p.get('bedType')]
    print('bed profiles in pack: %d' % len(beds))

    found = missing = 0
    outside, nosurface = [], []
    vis_gaps, col_gaps = [], []
    per_type = collections.defaultdict(list)
    rows = []

    for profile in beds:
        model = (profile.get('model') or '').lower().replace('\\', '/')
        stream = load_mesh(model, archives, args.loose) if model else None
        if stream is None:
            missing += 1
            continue
        found += 1
        try:
            vis, col = triangles_of(stream)
        except Exception as exc:                      # noqa: BLE001
            nosurface.append((model, 'parse: %s' % exc))
            continue
        if len(vis) == 0:
            nosurface.append((model, 'no visible geometry'))
            continue
        allv = np.vstack([vis.reshape(-1, 3)])
        lo, hi = allv.min(axis=0), allv.max(axis=0)

        for slot in profile['slots']:
            r = slot['root']
            rx, ry, rz = float(r['x']), float(r['y']), float(r['z'])
            pad = 8.0
            if not (lo[0] - pad <= rx <= hi[0] + pad
                    and lo[1] - pad <= ry <= hi[1] + pad):
                outside.append((model, slot['slotId'], rx, ry,
                                lo[0], hi[0], lo[1], hi[1]))
                continue
            # Ray down from just above the authored root, so a bunk's lower
            # berth finds its own mattress and not the one over its head.
            ceiling = rz + 4.0
            zv = surface_z(vis, rx, ry, ceiling)
            zc = surface_z(col, rx, ry, ceiling)
            if zv is None:
                nosurface.append((model + '/' + slot['slotId'], 'ray missed'))
                continue
            gv = rz - zv
            vis_gaps.append(gv)
            per_type[profile['bedType']].append(gv)
            if zc is not None:
                col_gaps.append(rz - zc)
            rows.append((model, slot['slotId'], profile['bedType'], rz, zv,
                         gv, zc if zc is not None else ''))
            if args.verbose:
                print('  %-50s %-13s %-8s root %8.2f vis %8.2f gap %+7.2f'
                      % (model, slot['slotId'], profile['bedType'], rz, zv, gv))

    print('\nmeshes resolved: %d   not in these BSAs: %d   unusable: %d'
          % (found, missing, len(nosurface)))
    print('slots with a root outside the mesh footprint: %d' % len(outside))
    for row in outside[:10]:
        print('   %s/%s root (%.1f, %.1f) vs x[%.1f, %.1f] y[%.1f, %.1f]'
              % row)
    for row in nosurface[:8]:
        print('   unusable: %s -- %s' % row)

    if vis_gaps:
        g = np.array(vis_gaps)
        print('\nroot height above the VISIBLE surface under it (n=%d):' % len(g))
        print('   median %+.2f   mean %+.2f   p10 %+.2f   p90 %+.2f   '
              'min %+.2f   max %+.2f'
              % (np.median(g), g.mean(), np.percentile(g, 10),
                 np.percentile(g, 90), g.min(), g.max()))
        for tol in (2.0, 5.0):
            print('   within +-%.0f units of that surface: %d of %d (%.0f%%)'
                  % (tol, int((np.abs(g) <= tol).sum()), len(g),
                     100.0 * (np.abs(g) <= tol).mean()))
        print('\n   by bed type:')
        for bedType in sorted(per_type):
            a = np.array(per_type[bedType])
            print('     %-9s n=%-4d median %+7.2f   p10 %+7.2f  p90 %+7.2f'
                  % (bedType, len(a), np.median(a),
                     np.percentile(a, 10), np.percentile(a, 90)))
    if col_gaps:
        c = np.array(col_gaps)
        print('\nfor comparison, above the COLLISION surface (n=%d): '
              'median %+.2f   p10 %+.2f   p90 %+.2f'
              % (len(c), np.median(c), np.percentile(c, 10),
                 np.percentile(c, 90)))

    if args.csv and rows:
        with open(args.csv, 'w', encoding='utf-8') as fh:
            fh.write('model,slot,bedType,rootZ,visibleZ,gap,collisionZ\n')
            for row in rows:
                fh.write(','.join(str(x) for x in row) + '\n')
        print('\nwrote %s (%d rows)' % (args.csv, len(rows)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
