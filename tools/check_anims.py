#!/usr/bin/env python3
"""check_anims.py -- every animation group a script plays must exist in a .kf.

`animation.playBlended` on a group the actor's skeleton does not define is a
SILENT no-op (RESEARCH 3.2): no error, no clip, and the actor keeps whatever
pose it had. A group missing from one skeleton folder and present in the others
is worse still, because it works for you and not for half your players.

This reads text keys out of every .kf under animations/ -- OpenMW takes the
group name from the part before the colon in a text key, so `dbssit4: start`
declares group `dbssit4` -- and cross-references them against the group-name
string literals in the Lua.

It also reports FOLDER coverage, because the usual failure is not a typo but a
skeleton variant nobody made files for: OpenMW resolves additional animation
sources per skeleton, so a female actor looks in animations/xbase_anim_female/
and does not fall back to animations/xbase_anim/.

The group list comes from the mod's OWN tables, dumped by
tools/dump_anim_groups.lua through the Lua runtime -- not from a name list
passed on the command line and not from a regex over the source. A plain run
used to print "0 group(s) unplayable" because `declared` was empty unless
--groups was given: a checker that reports clean because it did not look.

Fallbacks count. The runtime resolves a group the actor's skeleton lacks
through sitAnim_shared's GROUP_FALLBACKS (that is how the beast skeleton, which
declares only the tassit* transitions, plays the RA-set ones), so a group
absent from a folder is only a fault when none of its fallbacks is there
either.

Usage:
    check_anims.py <mod-dir> [--groups NAME,NAME] [--skeletons a,b,c]
"""
import os
import re
import struct
import subprocess
import sys
import glob

# Every skeleton variant this mod ships animations for. OpenMW resolves
# additional animation sources per skeleton with no fallback between them, so a
# folder left out of this list is a folder nobody checked -- and the mod ships
# first-person variants for female and beast actors too, which an earlier
# four-folder list quietly skipped.
DEFAULT_SKELETONS = ['xbase_anim', 'xbase_anim.1st',
                     'xbase_anim_female', 'xbase_anim_female.1st',
                     'xbase_animkna', 'xbase_animkna.1st']

TEXTKEY = re.compile(r'^([A-Za-z][\w ]*?)\s*:\s*(start|stop|loop start|loop stop)\b',
                     re.IGNORECASE)


def kf_strings(path):
    data = open(path, 'rb').read()
    out, i = [], 0
    while i < len(data) - 4:
        n = struct.unpack_from('<I', data, i)[0]
        if 2 <= n <= 256 and i + 4 + n <= len(data):
            s = data[i + 4:i + 4 + n]
            if all(32 <= c < 127 or c in (10, 13) for c in s):
                out.append(s.decode('ascii', 'replace'))
                i += 4 + n
                continue
        i += 1
    return out


def kf_groups(path):
    """Group names declared by text keys in this .kf."""
    groups = set()
    for s in kf_strings(path):
        for line in s.splitlines():
            m = TEXTKEY.match(line.strip())
            if m:
                groups.add(m.group(1).strip().lower())
    return groups


def lua_group_candidates(root, known):
    """Where each known group name is referenced in the Lua."""
    hits = {}
    for p in glob.glob(os.path.join(root, 'scripts', '**', '*.lua'), recursive=True):
        for lineno, line in enumerate(open(p, encoding='utf-8'), 1):
            if line.lstrip().startswith('--'):
                continue
            for m in re.finditer(r'''["']([\w]+)["']''', line):
                name = m.group(1).lower()
                if name in known:
                    hits.setdefault(name, []).append(
                        (os.path.relpath(p, root), lineno))
    return hits


def dump_groups(root):
    """{group: (fallbacks, uses)} from the mod's own animation tables."""
    out = subprocess.run(
        [sys.executable, os.path.join('tools', 'luarun.py'),
         os.path.join('tools', 'dump_anim_groups.lua')],
        cwd=root, capture_output=True, text=True)
    if out.returncode != 0 or not out.stdout.strip():
        raise SystemExit('could not read the animation tables: %s%s'
                         % (out.stdout, out.stderr))
    groups = {}
    for line in out.stdout.splitlines():
        if not line.strip():
            continue
        parts = line.split('\t')
        name = parts[0].strip().lower()
        alts = [a.strip().lower() for a in (parts[1] if len(parts) > 1 else '').split(',')
                if a.strip()]
        uses = parts[2].strip() if len(parts) > 2 else ''
        groups[name] = (alts, uses)
    return groups


def main(argv):
    declared, skeletons = set(), list(DEFAULT_SKELETONS)
    args, i = [], 0
    while i < len(argv):
        if argv[i] == '--groups' and i + 1 < len(argv):
            declared |= {x.strip().lower() for x in argv[i + 1].split(',') if x.strip()}
            i += 2
        elif argv[i] == '--skeletons' and i + 1 < len(argv):
            skeletons = [x.strip() for x in argv[i + 1].split(',') if x.strip()]
            i += 2
        else:
            args.append(argv[i])
            i += 1
    root = args[0] if args else '.'

    # Derived unless overridden. An empty list is not an excuse to pass.
    fallbacks, uses = {}, {}
    if declared:
        print('group list: %d name(s) from --groups' % len(declared))
    else:
        table = dump_groups(root)
        declared = set(table)
        fallbacks = {g: v[0] for g, v in table.items()}
        uses = {g: v[1] for g, v in table.items()}
        print('group list: %d name(s) from the mod\'s own animation tables'
              % len(declared))
    if not declared:
        raise SystemExit('no groups to check -- refusing to report clean')

    anim_root = os.path.join(root, 'animations')
    present = {d: {} for d in skeletons}
    extra_dirs = []
    if os.path.isdir(anim_root):
        for d in sorted(os.listdir(anim_root)):
            full = os.path.join(anim_root, d)
            if not os.path.isdir(full):
                continue
            files = {os.path.basename(f): kf_groups(f)
                     for f in sorted(glob.glob(os.path.join(full, '*.kf')))}
            if d in present:
                present[d] = files
            else:
                extra_dirs.append(d)

    print('animation folders expected: %s' % ', '.join(skeletons))
    for d in skeletons:
        files = present[d]
        if not os.path.isdir(os.path.join(anim_root, d)):
            print('  ABSENT    %-20s no such folder' % d)
        else:
            allg = set().union(*files.values()) if files else set()
            print('  %-9s %-20s %d file(s), %d group(s)'
                  % ('ok', d, len(files), len(allg)))
    if extra_dirs:
        print('  (also present, not checked: %s)' % ', '.join(extra_dirs))

    # A group is only usable on a skeleton whose folder declares it.
    per_skel = {d: (set().union(*present[d].values()) if present[d] else set())
                for d in skeletons}
    everywhere = set().union(*per_skel.values()) if per_skel else set()

    print('\ngroups declared by the shipped .kf files: %d' % len(everywhere))
    for g in sorted(everywhere):
        missing_in = [d for d in skeletons if g not in per_skel[d]]
        flag = 'ALL' if not missing_in else 'missing in ' + ', '.join(missing_in)
        print('  %-24s %s' % (g, flag))

    problems, covered = 0, 0
    print('\ngroups the scripts play:')
    for g in sorted(declared):
        alts = fallbacks.get(g, [])
        use = uses.get(g) or 'from --groups'
        missing_in = [d for d in skeletons if g not in per_skel[d]]
        if not missing_in:
            print('  ok        %-24s %s' % (g, use))
            continue
        # Absent here -- is a fallback playable on each of those skeletons?
        uncovered, via = [], set()
        for d in missing_in:
            alt = next((a for a in alts if a in per_skel[d]), None)
            if alt:
                via.add(alt)
            else:
                uncovered.append(d)
        if not uncovered:
            covered += 1
            print('  fallback  %-24s absent from %s, plays %s there  (%s)'
                  % (g, ', '.join(missing_in), ', '.join(sorted(via)), use))
        else:
            problems += 1
            print('  MISSING   %-24s absent from: %s%s  (%s)'
                  % (g, ', '.join(uncovered),
                     '' if not alts else ' -- fallbacks %s are not there either'
                     % ', '.join(alts), use))

    print('\n%d group(s) checked, %d covered by a fallback, '
          '%d unplayable on at least one skeleton'
          % (len(declared), covered, problems))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
