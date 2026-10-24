#!/usr/bin/env python3
"""Run every checker and every test, and say plainly what did not run.

    python3 tools/run_check_all.py [path/to/Cod3x_0.4]

Two of the checkers compare the scripts against the Cod3x API stubs and need
that tree; without it they are reported SKIPPED rather than passed. A skipped
check is not a clean check, and the exit status is non-zero if anything failed.
"""
import os
import subprocess
import sys

PY = sys.executable
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def tool(*args):
    return [PY, os.path.join('tools', args[0])] + list(args[1:])


def main(argv):
    cod3x = argv[0] if argv else None
    if cod3x and not os.path.isdir(cod3x):
        raise SystemExit('no such directory: %s' % cod3x)

    jobs = [
        ('luacheck      syntax', tool('luacheck.py', 'scripts')),
        ('check_load    every script loads', tool('check_load.py')),
        ('globalcheck   undeclared globals', tool('globalcheck.py', 'scripts')),
        ('check_handlers engine handler names', tool('check_handlers.py')),
        ('check_manifest script registration', tool('check_manifest.py', '.')),
        ('check_anims   animation groups exist', tool('check_anims.py', '.')),
    ]
    if cod3x:
        jobs += [
            ('ctxcheck      API used in the right context',
             tool('ctxcheck.py', cod3x, 'scripts')),
            ('api_sweep     API names exist', tool('api_sweep.py', 'scripts', cod3x)),
        ]
    for name in sorted(os.listdir(os.path.join(ROOT, 'tools'))):
        if name.startswith('test_') and name.endswith('.lua'):
            jobs.append(('test          %s' % name,
                         tool('luarun.py', os.path.join('tools', name))))

    failures, skipped = [], []
    if not cod3x:
        skipped = ['ctxcheck', 'api_sweep']

    for label, cmd in jobs:
        out = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
        text = (out.stdout or '') + (out.stderr or '')
        tail = [ln for ln in text.strip().splitlines() if ln.strip()]
        summary = tail[-1] if tail else '(no output)'
        # api_sweep's "to check by hand" items are questions, not failures.
        ok = out.returncode == 0
        print('%-4s %-46s %s' % ('ok' if ok else 'FAIL', label, summary[:90]))
        if not ok:
            failures.append((label, text))

    print()
    for label, text in failures:
        print('--- %s' % label)
        print(text.strip()[-2000:])
        print()
    if skipped:
        print('SKIPPED (no Cod3x tree given): %s -- rerun with the path to '
              'Cod3x_0.4 to include them' % ', '.join(skipped))
    print('%d job(s), %d failed, %d skipped'
          % (len(jobs), len(failures), len(skipped)))
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
