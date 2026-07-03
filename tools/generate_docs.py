import os
import re
import textwrap

HEADING_CHARS = frozenset("=-~^\"")
LEVELS = {"=": 0, "-": 1, "~": 2, "^": 3, '"': 4}

SUBSTITUTIONS = {
    "|spec|": "DTSpec",
    "|spec-fullname|": "Devicetree Specification",
    "|epapr|": "ePAPR",
    "|epapr-fullname|": "Embedded Power Architecture\u2122 Platform Requirements",
    "|SpecVersion|": "0.1",
    "|dtspec-major|": "0",
    "|dtspec-minor|": "1",
}
_NUMREF_RE = re.compile(r"(^|\s):numref:`([^`]+)`")

CHAPTER_MAP: dict[str, str] = {
    "chapter-introduction": "1",
    "chapter-devicetree": "2",
    "chapter-device-node-requirements": "3",
    "chapter-device-bindings": "4",
    "chapter-fdt-structure": "5",
    "chapter-devicetree-source-format": "6",
}

_CHAPTER_NUMREF_RE = re.compile(r"^Chapter %s <([^>]+)>$")


def _resolve_numref(m: re.Match) -> str:
    prefix = m.group(1)
    ref = m.group(2)
    chapter = _CHAPTER_NUMREF_RE.match(ref)
    if chapter:
        number = CHAPTER_MAP.get(chapter.group(1))
        if number:
            return prefix + "Chapter " + number
    return prefix + "`" + ref + "`"


_ABBR_RE = re.compile(r":abbr:`([^`]+)`")
_INLINE_LITERAL_RE = re.compile(r"``([^`]+)``")
_SUBSTITUTION_RE = re.compile(r"\|([^|]+)\|")


def _expand_subst(m: re.Match) -> str:
    key = "|" + m.group(1) + "|"
    return SUBSTITUTIONS.get(key, m.group(0))


_UNICODE_PUNCT = str.maketrans({
    "\u2018": "'",
    "\u2019": "'",
    "\u201c": '"',
    "\u201d": '"',
    "\u2013": "-",
    "\u2014": "-",
})


def _convert_inline(text: str) -> str:
    text = text.translate(_UNICODE_PUNCT)
    text = _NUMREF_RE.sub(_resolve_numref, text)
    text = _ABBR_RE.sub(r"`\1`", text)
    text = _INLINE_LITERAL_RE.sub(r"`\1`", text)
    text = _SUBSTITUTION_RE.sub(_expand_subst, text)
    text = re.sub(r"  +", " ", text)
    return text


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


def _section_text(
    text: str, headings: list[tuple[int, int, str]], idx: int
) -> str:
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


def _source_dir() -> str:
    return os.path.join(
        os.path.dirname(__file__),
        "..",
        "devicetree-specification",
        "source",
    )


def _rst_files() -> list[str]:
    source_dir = _source_dir()
    return [
        os.path.join(source_dir, fname)
        for fname in sorted(os.listdir(source_dir))
        if fname.endswith(".rst")
    ]


def _is_label(line: str) -> bool:
    return line.lstrip().startswith(".. _")


def _is_code_block_start(line: str) -> bool:
    return line.lstrip().startswith(".. code-block::")


def _is_note_start(line: str) -> bool:
    return line.lstrip().startswith(".. note::")


def _is_table_start(line: str) -> bool:
    return line.lstrip().startswith(".. table::")


def _is_tabularcolumns(line: str) -> bool:
    return line.lstrip().startswith(".. tabularcolumns::")


def _is_literal_block_marker(line: str) -> bool:
    return line.rstrip().endswith("::") and not line.startswith("..")


def _consume_indented_block(
    lines: list[str], i: int
) -> tuple[list[str], int]:
    while i < len(lines) and not lines[i].strip():
        i += 1
    if i >= len(lines):
        return [], i
    indent = len(lines[i]) - len(lines[i].lstrip())
    if indent == 0:
        return [], i
    block: list[str] = []
    while i < len(lines):
        if not lines[i].strip():
            block.append("")
            i += 1
            continue
        if len(lines[i]) - len(lines[i].lstrip()) >= indent:
            block.append(lines[i][indent:])
            i += 1
            continue
        break
    return block, i


def _strip_literal_markup(text: str) -> str:
    return _convert_inline(text).replace("`", "")


def _column_starts(separator: str) -> list[int]:
    starts: list[int] = []
    in_column = False
    for idx, ch in enumerate(separator):
        if ch in "=-":
            if not in_column:
                starts.append(idx)
                in_column = True
        else:
            in_column = False
    return starts


def _split_table_line(line: str, col_start: list[int]) -> list[str]:
    cells: list[str] = []
    for idx, start in enumerate(col_start):
        end = col_start[idx + 1] - 1 if idx + 1 < len(col_start) else None
        cells.append(line[start:end].strip())
    return cells


def _parse_table_rows(lines: list[str]) -> list[list[str]]:
    if not lines or not _is_table_separator(lines[0]):
        return []

    col_start = _column_starts(lines[0])
    rows: list[list[str]] = []
    current: list[str] | None = None

    for line in lines[1:]:
        if _is_table_separator(line):
            if current is not None:
                rows.append(current)
                current = None
            continue
        if not line.strip():
            continue

        cells = _split_table_line(line, col_start)
        if cells[0]:
            if current is not None:
                rows.append(current)
            current = cells
            continue

        if current is not None:
            for idx, cell in enumerate(cells):
                if cell:
                    current[idx] = (current[idx] + " " + cell).strip()

    if current is not None:
        rows.append(current)
    return rows


def get_table_entry(table: str, row: str, column: str) -> str | None:
    for fpath in _rst_files():
        with open(fpath) as f:
            lines = f.read().split("\n")

        for idx, line in enumerate(lines):
            if line.lstrip() != f".. table:: {table}":
                continue

            block, _ = _consume_indented_block(lines, idx + 1)
            rows = _parse_table_rows(block)
            if not rows:
                continue

            header = [_strip_literal_markup(cell) for cell in rows[0]]
            try:
                row_idx = header.index("Property Name")
                col_idx = header.index(column)
            except ValueError:
                return None

            for cells in rows[1:]:
                if _strip_literal_markup(cells[row_idx]) == row:
                    return _strip_literal_markup(cells[col_idx])
    return None


def _handle_code_block(lines: list[str], i: int) -> tuple[str, int]:
    lang = lines[i].split("::", 1)[1].strip()
    block, i = _consume_indented_block(lines, i + 1)
    code = "\n".join(block) + "\n"
    return f"```{lang}\n{code}```\n", i


def _handle_note(lines: list[str], i: int) -> tuple[str, int]:
    inline = lines[i].lstrip().removeprefix(".. note::").strip()
    if inline:
        block, next_i = _consume_indented_block(lines, i + 1)
        if block:
            text = inline + " " + " ".join(block)
        else:
            text = inline
            next_i = i + 1
        return f"> **Note:** {_convert_inline(text)}\n", next_i
    block, i = _consume_indented_block(lines, i + 1)
    quoted = "\n".join(
        "> " + _convert_inline(line) if line else ">" for line in block
    ) + "\n"
    return f"> **Note:**\n{quoted}", i


def _handle_literal_block(lines: list[str], i: int) -> tuple[str, int]:
    block, i = _consume_indented_block(lines, i + 1)
    code = "\n".join(block) + "\n"
    return f"```\n{code}```\n", i


def _is_table_separator(line: str) -> bool:
    stripped = line.lstrip()
    if not stripped:
        return False
    parts = stripped.split()
    return all(p and all(c in "=-" for c in p) for p in parts)


def _simple_table_column_starts(separator: str) -> list[int]:
    parts = separator.split()
    widths = [len(p) for p in parts]
    col_start: list[int] = []
    pos = 0
    for w in widths:
        col_start.append(pos)
        pos += w + 1
    return col_start


def _simple_table_cells(body: str, col_start: list[int]) -> list[str]:
    cells: list[str] = []
    for idx, cs in enumerate(col_start):
        if idx + 1 < len(col_start):
            end = col_start[idx + 1] - 1
            cells.append(body[cs:end].strip())
        else:
            cells.append(body[cs:].strip())
    return cells


def _simple_table_first_cell(body: str, col_start: list[int]) -> str:
    if len(col_start) > 1:
        return body[col_start[0]:col_start[1] - 1].strip()
    return body[col_start[0]:].strip()


def _append_simple_table_continuation(
    current: list[str], body: str, col_start: list[int]
) -> None:
    last = len(current) - 1
    tail = body[col_start[last]:]
    if tail.strip():
        current[last] += " " + tail.strip()


def _parse_simple_table_rows(
    lines: list[str], i: int, indent: int, col_start: list[int]
) -> tuple[list[list[str]], int]:
    rows: list[list[str]] = []
    current: list[str] | None = None

    i += 1
    while i < len(lines):
        line = lines[i]

        if rows and current is None and line.strip():
            line_indent = len(line) - len(line.lstrip())
            if line_indent < indent:
                break

        if _is_table_separator(line):
            if current is not None:
                rows.append(current)
                current = None
            i += 1
            continue

        if not line[indent:].strip():
            i += 1
            continue

        body = line[indent:]

        if current is not None and _simple_table_first_cell(body, col_start):
            rows.append(current)
            current = None

        if current is None:
            current = _simple_table_cells(body, col_start)
        else:
            _append_simple_table_continuation(current, body, col_start)
        i += 1

    if current is not None:
        rows.append(current)
    return rows, i


def _wrap_simple_table_rows(rows: list[list[str]]) -> list[list[list[str]]]:
    max_cell_width = 60
    wrapped_rows: list[list[list[str]]] = []
    for row in rows:
        wrapped_cells: list[list[str]] = []
        for c in row:
            stripped = c.strip()
            if not stripped:
                wrapped_cells.append([""])
            elif len(stripped) <= max_cell_width:
                wrapped_cells.append([stripped])
            else:
                wrapped_cells.append(textwrap.wrap(stripped, width=max_cell_width))
        wrapped_rows.append(wrapped_cells)
    return wrapped_rows


def _simple_table_column_widths(wrapped_rows: list[list[list[str]]]) -> list[int]:
    col_widths = [0] * len(wrapped_rows[0])
    for row in wrapped_rows:
        for ci, cell in enumerate(row):
            for line in cell:
                converted = _convert_inline(line)
                col_widths[ci] = max(col_widths[ci], len(converted))
    return col_widths


def _format_simple_table_rows(
    wrapped_rows: list[list[list[str]]], col_widths: list[int]
) -> list[str]:
    md_rows: list[str] = []
    for row in wrapped_rows:
        max_lines = max(len(cell) for cell in row)
        for li in range(max_lines):
            md_cells: list[str] = []
            for ci, cell_lines in enumerate(row):
                if li < len(cell_lines):
                    content = _convert_inline(cell_lines[li])
                else:
                    content = ""
                md_cells.append(f" {content:<{col_widths[ci]}} ")
            md_rows.append("|" + "|".join(md_cells) + "|")
    return md_rows


def _parse_simple_table(lines: list[str], i: int) -> tuple[str, int]:
    indent = len(lines[i]) - len(lines[i].lstrip())
    col_start = _simple_table_column_starts(lines[i])
    rows, i = _parse_simple_table_rows(lines, i, indent, col_start)
    wrapped_rows = _wrap_simple_table_rows(rows)
    col_widths = _simple_table_column_widths(wrapped_rows)
    md_rows = _format_simple_table_rows(wrapped_rows, col_widths)

    header_line_count = max(len(cell) for cell in wrapped_rows[0])
    seps = ["-" * (w + 2) for w in col_widths]
    md_rows.insert(header_line_count, "|" + "|".join(seps) + "|")
    return "\n".join(md_rows) + "\n", i


def _handle_bullet_list(lines: list[str], i: int) -> tuple[str, int]:
    block: list[str] = []
    while i < len(lines) and lines[i].strip().startswith("*"):
        item = lines[i].strip()
        block.append(_convert_inline(item))
        i += 1
    return "\n".join(block) + "\n", i


_LABEL_RE = re.compile(
    r"^(Property name|Value type|Property value|Description|Example):"
)


def _format_section(raw: str) -> str:
    lines = raw.split("\n")
    out: list[str] = []
    i = 0
    para: list[str] = []

    def _flush_para() -> None:
        nonlocal para
        if not para:
            return
        non_empty = [l for l in para if l.strip()]
        if not non_empty:
            para = []
            return
        min_indent = min(len(l) - len(l.lstrip()) for l in non_empty)
        text = " ".join(l[min_indent:].strip() for l in para)
        converted = _convert_inline(text)
        if _LABEL_RE.match(converted.strip()):
            colon = converted.index(":")
            out.append("**" + converted[:colon] + ":**" + converted[colon + 1:] + "\n")
        elif converted.strip():
            out.append(converted.strip() + "\n")
        else:
            out.append("\n")
        para = []

    while i < len(lines):
        line = lines[i]

        if _is_underline(line):
            _flush_para()
            i += 1
            continue

        if _is_label(line) or _is_tabularcolumns(line):
            _flush_para()
            i += 1
            continue

        if _is_code_block_start(line):
            _flush_para()
            md, i = _handle_code_block(lines, i)
            out.append(md)
            continue

        if _is_note_start(line):
            _flush_para()
            md, i = _handle_note(lines, i)
            out.append(md)
            continue

        if _is_table_start(line):
            _flush_para()
            i += 1
            continue

        if _is_literal_block_marker(line):
            _flush_para()
            prefix = line.rstrip()[:-2]
            if prefix.strip():
                out.append(_convert_inline(prefix) + "\n")
            md, i = _handle_literal_block(lines, i)
            out.append(md)
            continue

        if _is_table_separator(line):
            _flush_para()
            md, i = _parse_simple_table(lines, i)
            out.append(md)
            continue

        if line.strip().startswith("* "):
            _flush_para()
            md, i = _handle_bullet_list(lines, i)
            out.append(md.replace("* ", "- "))
            continue

        if not line.strip():
            _flush_para()
            out.append("\n")
            i += 1
            continue

        if i == 0 and i + 1 < len(lines) and _is_underline(lines[i + 1]):
            level = _heading_level(lines[i + 1]) + 1
            out.append(f"{'#' * level} {_convert_inline(lines[i])}\n")
            i += 2
            continue
        if i == 1 and not lines[0].strip() and i + 1 < len(lines) and _is_underline(lines[i + 1]):
            level = _heading_level(lines[i + 1]) + 1
            out.append(f"{'#' * level} {_convert_inline(lines[i])}\n")
            i += 2
            continue

        para.append(line)
        i += 1

    _flush_para()
    return "".join(out).strip() + "\n"


PROPERTY_SECTIONS: dict[str, str] = {
    "compatible": "compatible",
    "model": "model",
    "phandle": "phandle",
    "status": "status",
    "#address-cells": "#address-cells and #size-cells",
    "#size-cells": "#address-cells and #size-cells",
    "reg": "reg",
    "virtual-reg": "virtual-reg",
    "ranges": "ranges",
    "dma-ranges": "dma-ranges",
    "dma-coherent": "dma-coherent",
    "dma-noncoherent": "dma-noncoherent",
    "name": "name (deprecated)",
    "device_type": "device_type (deprecated)",
}


def build_hover_docs() -> dict[str, str]:
    docs: dict[str, str] = {}
    for prop_name, section_name in PROPERTY_SECTIONS.items():
        raw = get_section(section_name)
        if raw:
            docs[prop_name] = _format_section(raw)
        else:
            docs[prop_name] = ""
    return docs


def write_hover_docs(output_path: str | None = None) -> None:
    import json
    if output_path is None:
        repo_root = os.path.dirname(os.path.dirname(__file__))
        output_path = os.path.join(repo_root, "anakins_dtls", "_hover_docs.py")
    docs = build_hover_docs()
    with open(output_path, "w") as f:
        f.write("HOVER_DOCS = ")
        json.dump(docs, f, indent=2)
        f.write("\n")
