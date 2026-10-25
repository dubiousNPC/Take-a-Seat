#!/usr/bin/env python3
"""
ctxcheck.py -- verify ---@omw-context annotations against Cod3x 0.4.

Cod3x 0.4 restructured the context plugin ("CLEANUP: Centralize Cod3x module
registrations and policy tables"), so the old parser -- which read inline
`{ global = true, ... }` literals out of AVAILABILITY -- now reads zero
modules and silently passes everything. This parses the 0.4 shape: symbolic
context sets (EVERY_CONTEXT, ACTOR_CONTEXT, ...) resolved from contextSet(...)
declarations.

0.4 also added two things the old checker had no concept of:

  * MEMBER availability. openmw.core, openmw.storage and openmw.interfaces are
    checked member by member, not just module by module. `storage.playerSection`
    is player/menu even though openmw.storage itself is available everywhere.
  * INTERFACE availability. I.Camera is player-only, I.AI is local-only,
    I.Activation and I.ItemUsage are global-only.

Both catch real mistakes the module-level check cannot see.

The single behavioural change in 0.4 that breaks existing code:
    openmw.types  EVERY_CONTEXT -> OBJECT_CONTEXT
i.e. it lost `menu` and `load`. Any MENU script requiring openmw.types was
always wrong and is now reported.

Usage:  ctxcheck.py <cod3x-dir> <target> [target...]
"""
import os
import re
import sys
import glob
# The script's own directory, so `-I` (isolated mode, which drops it from
# sys.path) cannot turn this import into a different bug.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import luastrip


EXPAND = {
    'runtime': {'global', 'local', 'player', 'menu'},
    'all': {'global', 'local', 'player', 'menu', 'load'},
}


def load_policy(cod3x_dir):
    """Parse AVAILABILITY, MEMBER_AVAILABILITY and VALID_CONTEXTS from 0.4."""
    src = open(os.path.join(cod3x_dir, 'omw_context_plugin.lua'),
               encoding='utf-8').read()

    # local NAME_CONTEXT = contextSet('a', 'b', ...)
    sets = {}
    for m in re.finditer(r"local (\w+) = contextSet\(([^)]*)\)", src):
        sets[m.group(1)] = set(re.findall(r"'(\w+)'", m.group(2)))

    def table(name):
        m = re.search(r'local ' + name + r' = \{(.*?)\n\}', src, re.S)
        if not m:
            return {}
        out = {}
        for mm in re.finditer(r"\[?'?\"?([\w.]+)'?\"?\]?\s*=\s*(\w+),", m.group(1)):
            key, setname = mm.group(1), mm.group(2)
            if setname in sets:
                out[key] = sets[setname]
        return out

    availability = table('AVAILABILITY')
    members = {
        'openmw.core': table('CORE_MEMBER_AVAILABILITY'),
        'openmw.storage': table('STORAGE_MEMBER_AVAILABILITY'),
        'openmw.interfaces': table('INTERFACE_MEMBER_AVAILABILITY'),
    }
    valid = set(re.findall(r"^\s+\[?'?(\w+)'?\]?\s*=\s*true,",
                           re.search(r'local VALID_CONTEXTS = \{(.*?)\n\}', src, re.S).group(1),
                           re.M))

    # Second source: each stub file's own `---@omw-context` line. The plugin's
    # AVAILABILITY table does not cover every module -- openmw.debug is one it
    # misses -- and a module with no policy was silently allowed in any
    # context. `openmw/debug.lua` says `---@omw-context player`, so a global
    # script requiring it was a fault this checker passed. Stub annotations fill
    # the gaps; the plugin table still wins where both exist.
    stub_dir = os.path.join(cod3x_dir, 'openmw')
    for path in sorted(glob.glob(os.path.join(stub_dir, '*.lua'))):
        mod = 'openmw.' + os.path.splitext(os.path.basename(path))[0]
        if mod in availability:
            continue
        head = open(path, encoding='utf-8', errors='replace').read(400)
        m = re.search(r'---@omw-context (\S+)', head)
        if not m:
            continue
        ctxs = set()
        for t in m.group(1).split('|'):
            ctxs |= EXPAND.get(t, {t})
        ctxs &= valid
        if ctxs:
            availability[mod] = ctxs

    return availability, members, valid, sets


def strip_lua(src):
    """Comments and string literals out, in one pass -- see tools/luastrip.py
    for why this is not a pair of regexes.

    Use this for scanning CODE. Not for finding requires: a module name is a
    string literal, so this blanks the very thing the alias scan reads. Doing
    that left this checker with zero aliases and therefore zero module and
    member checks, reporting "0 issues" having looked at nothing -- the same
    trap api_sweep documents. `strip_comments_only` is for that scan.
    """
    return luastrip.strip(src)


def strip_comments_only(src):
    """Comments out, string literals INTACT, for the require scan."""
    src = re.sub(r'--\[(=*)\[.*?\]\1\]', ' ', src, flags=re.S)
    return re.sub(r'--[^\n]*', '', src)


# Every file's alias count, so main can refuse to report clean after finding
# no requires anywhere -- which is what a broken alias scan looks like.
assert_aliases = []


def check_file(path, availability, members, valid):
    src = open(path, encoding='utf-8', errors='ignore').read()
    code = strip_lua(src)
    issues = []

    m = re.match(r'---@omw-context (\S+)', src)
    if not m:
        return [('NO-ANNOTATION', 'add one; `none` if API-agnostic')]
    raw = m.group(1)
    tokens = raw.split('|')
    bad = [t for t in tokens if t not in valid]
    if bad:
        return [('INVALID-TOKEN', f'{raw} (unknown: {", ".join(bad)})')]

    concrete = set()
    for t in tokens:
        concrete |= EXPAND.get(t, {t})

    # From the source with strings intact: the module name IS a string.
    aliases = dict(re.findall(
        r"""local (\w+)\s*=\s*require\s*\(?\s*['\"]([\w.]+)['\"]\s*\)?""",
        strip_comments_only(src)))
    requires = set(aliases.values())
    assert_aliases.append((path, len(aliases)))

    if raw == 'none':
        omw = sorted(r for r in requires if r.startswith('openmw'))
        if omw:
            issues.append(('NONE-BUT-REQUIRES', ', '.join(omw)))
        return issues

    for mod in sorted(requires):
        allowed = availability.get(mod)
        if allowed is None:
            # Not "fine": unchecked. A module with no policy from either source
            # used to pass in any context, which is how a player-only module
            # required from a global script could come back clean.
            if mod.startswith('openmw') or mod.startswith('openmw_aux'):
                issues.append(('NO-POLICY',
                               f'{mod} has no context policy in Cod3x; '
                               f'checked nothing for it'))
            continue
        if not concrete <= allowed:
            issues.append(('MODULE', f'{mod} is {sorted(allowed)}, file is {raw}'))

    # member-level: openmw.core / openmw.storage / openmw.interfaces
    for alias, mod in aliases.items():
        table = members.get(mod)
        if not table:
            continue
        for mm in re.finditer(re.escape(alias) + r'\.(\w+)', code):
            member = mm.group(1)
            allowed = table.get(member)
            if allowed and not concrete <= allowed:
                line = code[:mm.start()].count('\n') + 1
                issues.append(('MEMBER',
                               f'{mod}.{member} is {sorted(allowed)}, file is {raw} (line {line})'))
    return issues


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cod3x, targets = argv[0], argv[1:]
    availability, members, valid, sets = load_policy(cod3x)
    print(f"policy: {len(availability)} modules, "
          f"{sum(len(v) for v in members.values())} scoped members, "
          f"{len(valid)} valid tokens\n")

    files = []
    for t in targets:
        files += (glob.glob(os.path.join(t, '**', '*.lua'), recursive=True)
                  if os.path.isdir(t) else [t])
    files = [f for f in sorted(files)
             if 'tools' not in f.replace(os.sep, '/').split('/')]

    total = 0
    for f in files:
        issues = check_file(f, availability, members, valid)
        if issues:
            print(f)
            for kind, detail in issues:
                print(f"    {kind:<18} {detail}")
            total += len(issues)
    seen = sum(n for _, n in assert_aliases)
    if files and seen == 0:
        print("ctxcheck: no openmw requires found in any file -- the alias scan "
              "is broken, not the code; refusing to report clean")
        return 2
    print(f"\n{len(files)} file(s) checked, {seen} require(s) resolved, "
          f"{total} issue(s)")
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
