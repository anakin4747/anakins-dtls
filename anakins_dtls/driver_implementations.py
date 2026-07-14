import os
import re

from anakins_dtls.kernel_bindings import find_kernel_source_root


COMPATIBLE_STRING_RE_TEMPLATE = r'"{compatible}"'


def _find_driver_file(kernel_source_root: str, compatible: str) -> str | None:
    drivers_root = os.path.join(kernel_source_root, 'drivers')
    if not os.path.isdir(drivers_root):
        return None

    pattern = re.compile(COMPATIBLE_STRING_RE_TEMPLATE.format(compatible=re.escape(compatible)))
    for dirpath, _dirnames, filenames in os.walk(drivers_root):
        for filename in filenames:
            if not filename.endswith('.c'):
                continue
            driver_path = os.path.join(dirpath, filename)
            with open(driver_path) as f:
                content = f.read()
            if pattern.search(content):
                return driver_path
    return None


def _find_compatible_string_location(driver_path: str, compatible: str) -> tuple[int, int, int] | None:
    """Locate the compatible string literal within a driver source file.

    Returns ``(line, start_character, end_character)`` of the compatible
    string (excluding the surrounding quotes), or ``None`` if it is not
    found.
    """
    pattern = re.compile(rf'"({re.escape(compatible)})"')
    with open(driver_path) as f:
        for line_no, line_text in enumerate(f):
            m = pattern.search(line_text)
            if m:
                return line_no, m.start(1), m.end(1)
    return None


def _location(file_path: str, line: int, start_character: int, end_character: int) -> dict:
    return {
        'uri': 'file://' + os.path.abspath(file_path),
        'range': {
            'start': {'line': line, 'character': start_character},
            'end': {'line': line, 'character': end_character},
        },
    }


def find_driver_implementation_location(file_path: str, compatible: str) -> dict | None:
    """Find a Linux kernel driver bound to a compatible string, if any.

    Searches the kernel source root's ``drivers/`` tree for a ``.c`` file
    referencing ``compatible`` and returns an LSP ``Location`` pointing at
    that reference. Returns ``None`` when there is no relevant kernel
    source context or no driver file references the compatible string.
    """
    kernel_source_root = find_kernel_source_root(file_path)
    if kernel_source_root is None:
        return None

    driver_path = _find_driver_file(kernel_source_root, compatible)
    if driver_path is None:
        return None

    found = _find_compatible_string_location(driver_path, compatible)
    if found is None:
        return None

    line, start_character, end_character = found
    return _location(driver_path, line, start_character, end_character)
