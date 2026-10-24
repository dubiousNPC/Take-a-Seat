"""Syntax-check Lua files by calling luaL_loadbufferx in the system liblua5.4.

No interpreter or headers are installed here, but the shared object is, so
ctypes is enough to get real parser errors rather than eyeballing the code.
"""
import ctypes, sys

lua = ctypes.CDLL('/usr/lib/x86_64-linux-gnu/liblua5.4.so.0')
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t,
                                 ctypes.c_char_p, ctypes.c_char_p]
lua.luaL_loadbufferx.restype = ctypes.c_int
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]

# A directory argument means "every .lua under here". Passing one used to
# raise IsADirectoryError, so the habit was to pass a find(1) expansion -- and
# an expansion that matched nothing printed "0 file(s) checked, 0 failed" and
# exited 0. A checker must not report clean without having looked.
import os

paths = []
for arg in sys.argv[1:]:
    if os.path.isdir(arg):
        for base, _, files in os.walk(arg):
            paths += [os.path.join(base, f) for f in sorted(files) if f.endswith('.lua')]
    else:
        paths.append(arg)
if not paths:
    sys.exit('luacheck: no .lua files in %s -- refusing to report clean'
             % (' '.join(sys.argv[1:]) or '(no arguments)'))

fail = 0
for path in paths:
    src = open(path, 'rb').read()
    L = lua.luaL_newstate()
    rc = lua.luaL_loadbufferx(L, src, len(src), path.encode(), b't')
    if rc != 0:
        msg = lua.lua_tolstring(L, -1, None)
        print('FAIL %s\n     %s' % (path, msg.decode('utf-8', 'replace')))
        fail += 1
    else:
        print('ok   %s' % path)
    lua.lua_close(L)

print('\n%d file(s) checked, %d failed' % (len(paths), fail))
sys.exit(1 if fail else 0)
