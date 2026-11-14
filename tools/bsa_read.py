#!/usr/bin/env python3
"""Minimal reader for Morrowind .bsa archives (version 0x100).

Layout, all little-endian:
    uint32 version (0x100)
    uint32 hashOffset        -- from just after this header to the hash table
    uint32 fileCount
    fileCount x (uint32 size, uint32 offsetInData)
    fileCount x uint32 nameOffset   -- into the name block
    name block (NUL-terminated names, nameOffset is relative to its start)
    fileCount x 8 byte hash
    data

The data section begins at 12 + hashOffset + 8 * fileCount.

Usage:
    bsa_read.py list <archive.bsa> [substring]
    bsa_read.py extract <archive.bsa> <out-dir> [substring]
"""
import os
import struct
import sys


class Bsa:
    def __init__(self, path):
        self.path = path
        with open(path, 'rb') as fh:
            version, hash_offset, count = struct.unpack('<III', fh.read(12))
            if version != 0x100:
                raise ValueError('%s: not a Morrowind bsa (version 0x%x)'
                                 % (path, version))
            sizes_offsets = struct.unpack('<%dI' % (count * 2),
                                          fh.read(count * 8))
            name_offsets = struct.unpack('<%dI' % count, fh.read(count * 4))
            # The name block runs from here to the hash table.
            names_len = hash_offset - (count * 12)
            names = fh.read(names_len)

        self.data_start = 12 + hash_offset + count * 8
        self.entries = {}
        for i in range(count):
            size = sizes_offsets[i * 2]
            offset = sizes_offsets[i * 2 + 1]
            start = name_offsets[i]
            end = names.index(b'\x00', start)
            name = names[start:end].decode('cp1252').replace('\\', '/').lower()
            self.entries[name] = (size, offset)

    def __contains__(self, name):
        return name.replace('\\', '/').lower() in self.entries

    def read(self, name):
        size, offset = self.entries[name.replace('\\', '/').lower()]
        with open(self.path, 'rb') as fh:
            fh.seek(self.data_start + offset)
            return fh.read(size)

    def names(self, substring=None):
        if substring is None:
            return sorted(self.entries)
        s = substring.lower()
        return sorted(n for n in self.entries if s in n)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    mode, archive = argv[0], argv[1]
    bsa = Bsa(archive)
    if mode == 'list':
        sub = argv[2] if len(argv) > 2 else None
        for n in bsa.names(sub):
            print(n)
        return 0
    if mode == 'extract':
        out = argv[2]
        sub = argv[3] if len(argv) > 3 else None
        n = 0
        for name in bsa.names(sub):
            dest = os.path.join(out, name)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, 'wb') as fh:
                fh.write(bsa.read(name))
            n += 1
        print('%d file(s) -> %s' % (n, out))
        return 0
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
