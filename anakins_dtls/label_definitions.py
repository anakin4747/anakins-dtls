import os
import re


INCLUDE_RE = re.compile(r'/include/\s*"([^"]+)"')
LABEL_DEFINITION_RE = re.compile(r'\b([A-Za-z_]\w*):')


def _find_label_definition(text: str, label: str) -> tuple[int, int, int] | None:
    """Locate a label definition within ``text``.

    Returns ``(line, start_character, end_character)`` of the label name, or
    ``None`` if the label is not defined in this text.
    """
    for line_no, line_text in enumerate(text.split('\n')):
        for m in LABEL_DEFINITION_RE.finditer(line_text):
            if m.group(1) == label:
                return line_no, m.start(1), m.end(1)
    return None


def _included_file_paths(text: str, base_dir: str) -> list[str]:
    paths = []
    for m in INCLUDE_RE.finditer(text):
        paths.append(os.path.normpath(os.path.join(base_dir, m.group(1))))
    return paths


def _location(file_path: str, line: int, start_character: int, end_character: int) -> dict:
    return {
        'uri': 'file://' + os.path.abspath(file_path),
        'range': {
            'start': {'line': line, 'character': start_character},
            'end': {'line': line, 'character': end_character},
        },
    }


def find_label_definition_location(file_path: str, text: str, label: str) -> dict | None:
    """Find where a label is defined, searching the open file then its includes.

    Labels are looked up first in ``text`` (the currently open document), and
    then, if not found there, in each ``/include/``d dtsi file in the order
    they are included. Returns an LSP ``Location``, or ``None`` if the label
    is not defined anywhere.
    """
    found = _find_label_definition(text, label)
    if found is not None:
        line, start_character, end_character = found
        return _location(file_path, line, start_character, end_character)

    base_dir = os.path.dirname(os.path.abspath(file_path))
    for include_path in _included_file_paths(text, base_dir):
        if not os.path.isfile(include_path):
            continue
        with open(include_path) as f:
            include_text = f.read()
        found = _find_label_definition(include_text, label)
        if found is not None:
            line, start_character, end_character = found
            return _location(include_path, line, start_character, end_character)

    return None
