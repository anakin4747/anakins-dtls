import os
import re

from anakins_dtls.kernel_bindings import find_kernel_source_root
from anakins_dtls.lsp_locations import location


def _find_compatible_string_in_file(driver_path: str, compatible: str) -> tuple[int, int, int] | None:
    """Locate the compatible string literal within a driver source file.

    Returns ``(line, start_character, end_character)`` of the compatible
    string (excluding the surrounding quotes), or ``None`` if the file does
    not reference it.
    """
    pattern = re.compile(rf'"({re.escape(compatible)})"')
    with open(driver_path) as f:
        for line_no, line_text in enumerate(f):
            m = pattern.search(line_text)
            if m:
                return line_no, m.start(1), m.end(1)
    return None


def _find_driver_implementation(kernel_source_root: str, compatible: str) -> tuple[str, int, int, int] | None:
    drivers_root = os.path.join(kernel_source_root, 'drivers')
    if not os.path.isdir(drivers_root):
        return None

    for dirpath, _dirnames, filenames in os.walk(drivers_root):
        for filename in filenames:
            if not filename.endswith('.c'):
                continue
            driver_path = os.path.join(dirpath, filename)
            found = _find_compatible_string_in_file(driver_path, compatible)
            if found is not None:
                line, start_character, end_character = found
                return driver_path, line, start_character, end_character
    return None


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

    found = _find_driver_implementation(kernel_source_root, compatible)
    if found is None:
        return None

    driver_path, line, start_character, end_character = found
    return location(driver_path, line, start_character, end_character)
