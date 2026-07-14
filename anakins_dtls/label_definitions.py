import os
import re

from anakins_dtls.kernel_bindings import find_kernel_source_root


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


def _include_directive_paths(text: str) -> list[str]:
    return [m.group(1) for m in INCLUDE_RE.finditer(text)]


def _resolve_include_path(include_path: str, base_dir: str, file_path: str) -> str | None:
    """Resolve an ``/include/``d path, trying the file's directory first.

    Falls back to resolving the path relative to the kernel source root
    (in-tree or out-of-tree) when it is not found relative to ``base_dir``.
    """
    relative_path = os.path.normpath(os.path.join(base_dir, include_path))
    if os.path.isfile(relative_path):
        return relative_path

    kernel_source_root = find_kernel_source_root(file_path)
    if kernel_source_root is not None:
        kernel_relative_path = os.path.normpath(os.path.join(kernel_source_root, include_path))
        if os.path.isfile(kernel_relative_path):
            return kernel_relative_path

    return None


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
    they are included. Each include path is resolved relative to the open
    file's directory, falling back to the kernel source root (in-tree or
    out-of-tree) when it is not found there. Returns an LSP ``Location``, or
    ``None`` if the label is not defined anywhere.
    """
    found = _find_label_definition(text, label)
    if found is not None:
        line, start_character, end_character = found
        return _location(file_path, line, start_character, end_character)

    base_dir = os.path.dirname(os.path.abspath(file_path))
    for include_path in _include_directive_paths(text):
        resolved_path = _resolve_include_path(include_path, base_dir, file_path)
        if resolved_path is None:
            continue
        with open(resolved_path) as f:
            include_text = f.read()
        found = _find_label_definition(include_text, label)
        if found is not None:
            line, start_character, end_character = found
            return _location(resolved_path, line, start_character, end_character)

    return None
