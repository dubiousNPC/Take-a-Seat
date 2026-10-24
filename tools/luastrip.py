"""Blank Lua comments and string literals, in one left-to-right pass.

Why this is not two regexes. api_sweep, globalcheck and ctxcheck each had a
stripper that removed comments first and strings second:

    src = re.sub(r'--[^\\n]*', ' ', src)        # comments
    src = re.sub(r'"(?:\\\\.|[^"\\\\])*"', '""', src)  # strings

sitAnim_shared.lua contains this, which is ordinary Lua:

    error(("[take a seat] %s references unknown seat type '%s' -- " ..
           "add it to SEAT_TYPE or remove the row"):format(label, name))

The `--` inside that string literal starts a "comment" as far as the first
regex is concerned, so the rest of the line -- including the quote that closed
the string -- was deleted. Every double quote after that point then paired up
one position out, so large stretches of real code were blanked as "string
contents" and were never checked at all. That is the usual failure: not a
checker that reported a wrong answer, a checker that reported a clean answer
having looked at half the file.

Strings and comments cannot be separated by two independent passes, because
each can contain the other's opening marker. One pass, with state, can.

`strip` keeps the source's shape -- same length in lines, same offsets for
anything outside a comment or string -- so line numbers and `find` offsets
taken from the result still point at the right place in the original.
"""

# Replacement characters. Strings collapse to empty quotes so that a call like
# find(s, 'x') still parses as a call with an argument; comments become spaces.
def strip(src):
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]

        # long comment / long string: --[==[ ... ]==]
        if src.startswith('--', i):
            j = i + 2
            if j < n and src[j] == '[':
                k = j + 1
                while k < n and src[k] == '=':
                    k += 1
                if k < n and src[k] == '[':
                    level = src[j + 1:k]
                    close = ']' + level + ']'
                    end = src.find(close, k + 1)
                    end = n if end < 0 else end + len(close)
                    out.append(''.join('\n' if ch == '\n' else ' '
                                       for ch in src[i:end]))
                    i = end
                    continue
            end = src.find('\n', i)
            end = n if end < 0 else end
            out.append(' ' * (end - i))
            i = end
            continue

        # long string literal: [[ ... ]] or [==[ ... ]==]
        if c == '[':
            k = i + 1
            while k < n and src[k] == '=':
                k += 1
            if k < n and src[k] == '[':
                level = src[i + 1:k]
                close = ']' + level + ']'
                end = src.find(close, k + 1)
                end = n if end < 0 else end + len(close)
                out.append(''.join('\n' if ch == '\n' else ' '
                                   for ch in src[i:end]))
                i = end
                continue

        # quoted string: keep the quotes, blank the contents, respect escapes
        if c == '"' or c == "'":
            j = i + 1
            while j < n:
                if src[j] == '\\':
                    j += 2
                    continue
                if src[j] == c or src[j] == '\n':
                    break
                j += 1
            end = min(j + 1, n)
            out.append(c + ' ' * (end - i - 2) + (c if end - i >= 2 else ''))
            i = end
            continue

        out.append(c)
        i += 1
    return ''.join(out)


if __name__ == '__main__':
    import sys
    for p in sys.argv[1:]:
        sys.stdout.write(strip(open(p, encoding='utf-8').read()))
