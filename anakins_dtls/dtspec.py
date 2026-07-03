import os

HEADING_CHARS = frozenset('=-~^"')
LEVELS = {'=': 0, '-': 1, '~': 2, '^': 3, '"': 4}


def _is_underline(line: str) -> bool:
    if len(line) < 3:
        return False
    ch = line[0]
    if ch not in HEADING_CHARS:
        return False
    return all(c == ch for c in line)


def _heading_level(underline: str) -> int:
    return LEVELS[underline[0]]


def _parse_headings(text: str) -> list[tuple[int, int, str]]:
    headings = []
    lines = text.split("\n")
    pos = 0
    for i, line in enumerate(lines):
        if i >= len(lines) - 1:
            break
        nxt = lines[i + 1]
        if line and _is_underline(nxt):
            headings.append((pos, _heading_level(nxt), line))
        pos += len(line) + 1
    return headings


def _section_text(text: str, headings: list[tuple[int, int, str]], idx: int) -> str:
    start = headings[idx][0]
    level = headings[idx][1]
    for i in range(idx + 1, len(headings)):
        if headings[i][1] <= level:
            return text[start : headings[i][0]]
    return text[start:]


def get_section(name: str) -> str | None:
    source_dir = os.path.join(
        os.path.dirname(__file__),
        "..",
        "devicetree-specification",
        "source",
    )
    for fname in sorted(os.listdir(source_dir)):
        if not fname.endswith(".rst"):
            continue
        fpath = os.path.join(source_dir, fname)
        with open(fpath) as f:
            text = f.read()
        headings = _parse_headings(text)
        for i, (_offset, _level, title) in enumerate(headings):
            if title == name:
                return _section_text(text, headings, i)
    return None
