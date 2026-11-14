# 0007: `check_bed_surfaces.py` only runs on one machine

- **Status:** fixed on `fixes-v0.44`

## Problem
The script hard-coded `sys.path.insert(0, '/home/claude/in/mw/io_scene_mw-master/lib')` for the `es3` NIF reader, which is not vendored.

## Fix
It now reads `TAS_ES3_LIB`, keeps the old path as a fallback, and exits with a clear message naming the repo to clone. Output is unchanged: 41 meshes, 54 slots, median +1.44.
