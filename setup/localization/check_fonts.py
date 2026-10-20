"""Check that the bundled Asian fonts map every translated character to a glyph."""
from pathlib import Path
import bisect
import json
import struct

ROOT = Path(__file__).resolve().parents[2]


def font_lookup(path):
    data = path.read_bytes()
    u16 = lambda offset: struct.unpack_from('>H', data, offset)[0]
    u32 = lambda offset: struct.unpack_from('>I', data, offset)[0]
    cmap = next(u32(12 + 16 * i + 8) for i in range(u16(4)) if data[12 + 16 * i:16 + 16 * i] == b'cmap')
    tables = []
    for i in range(u16(cmap + 2)):
        entry = cmap + 4 + i * 8
        platform = u16(entry)
        encoding = u16(entry + 2)
        if platform != 0 and not (platform == 3 and encoding in (1, 10)):
            continue
        sub = cmap + u32(entry + 4)
        fmt = u16(sub)
        if fmt == 12:
            groups = [struct.unpack_from('>III', data, sub + 16 + j * 12) for j in range(u32(sub + 12))]
            tables.append((12, groups, [group[0] for group in groups]))
        elif fmt == 4:
            count = u16(sub + 6) // 2
            ends_pos = sub + 14
            starts_pos = ends_pos + count * 2 + 2
            delta_pos = starts_pos + count * 2
            offset_pos = delta_pos + count * 2
            ends = [u16(ends_pos + j * 2) for j in range(count)]
            starts = [u16(starts_pos + j * 2) for j in range(count)]
            tables.append((4, ends, starts, delta_pos, offset_pos))

    def has_glyph(code):
        for table in tables:
            if table[0] == 12:
                _, groups, starts = table
                index = bisect.bisect_right(starts, code) - 1
                if index >= 0:
                    start, end, glyph = groups[index]
                    if code <= end and glyph + code - start != 0:
                        return True
            elif code <= 0xFFFF:
                _, ends, starts, delta_pos, offset_pos = table
                index = bisect.bisect_left(ends, code)
                if index >= len(ends) or starts[index] > code:
                    continue
                delta = u16(delta_pos + index * 2)
                offset = u16(offset_pos + index * 2)
                if offset == 0:
                    glyph = (code + delta) & 0xFFFF
                else:
                    glyph = u16(offset_pos + index * 2 + offset + 2 * (code - starts[index]))
                    if glyph:
                        glyph = (glyph + delta) & 0xFFFF
                if glyph:
                    return True
        return False
    return has_glyph


def strings(data):
    if isinstance(data, str):
        yield data
    elif isinstance(data, dict):
        for key, value in data.items():
            if not key.startswith('$'):
                yield from strings(value)


def main():
    failed = False
    for code, suffix in [('ja-JP', 'JP'), ('zh-CN', 'SC'), ('zh-TW', 'TC'), ('ko-KR', 'KR')]:
        has_glyph = font_lookup(ROOT / f'assets/fonts/NotoSans{suffix}-Medium.ttf')
        chars = set()
        for path in (ROOT / 'assets/shared/languages' / code).rglob('*.json'):
            chars.update(''.join(strings(json.loads(path.read_text('utf-8')))))
        missing = sorted(f'U+{ord(char):04X}' for char in chars if ord(char) >= 32 and not has_glyph(ord(char)))
        print(f'{code}: {len(chars)} characters, missing glyphs: {missing}')
        failed |= bool(missing)
    return int(failed)


if __name__ == '__main__':
    raise SystemExit(main())
