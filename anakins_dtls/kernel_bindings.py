import os
import re


BINDING_EXTENSIONS = ('.yaml', '.yml', '.txt')


def find_kernel_source_root(file_path: str) -> str | None:
    """Locate the Linux kernel source root relevant to an open file.

    Crawls upward from the file's directory. A directory containing
    ``Documentation/devicetree/bindings`` is treated as an in-tree kernel
    source tree. Failing that, a ``.anakins-dtls`` config file naming an
    out-of-tree kernel source directory (via ``S=<path>``) is honored.
    """
    directory = os.path.dirname(os.path.abspath(file_path))
    while True:
        if os.path.isdir(os.path.join(directory, 'Documentation', 'devicetree', 'bindings')):
            return directory

        config_path = os.path.join(directory, '.anakins-dtls')
        if os.path.isfile(config_path):
            configured_root = _resolve_configured_kernel_source(config_path)
            if configured_root is not None:
                return configured_root

        parent = os.path.dirname(directory)
        if parent == directory:
            return None
        directory = parent


def _unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
        return value[1:-1]
    return value


def _resolve_configured_kernel_source(config_path: str) -> str | None:
    with open(config_path) as f:
        for line in f:
            line = line.strip()
            if not line.startswith('S='):
                continue
            value = line[len('S='):].strip()
            value = _unquote(value)
            if not value:
                return None
            if not os.path.isabs(value):
                value = os.path.join(os.path.dirname(config_path), value)
            return os.path.normpath(value)
    return None


def find_binding_file(kernel_source_root: str, compatible: str) -> str | None:
    bindings_root = os.path.join(kernel_source_root, 'Documentation', 'devicetree', 'bindings')
    if not os.path.isdir(bindings_root):
        return None
    for dirpath, _dirnames, filenames in os.walk(bindings_root):
        for filename in filenames:
            stem, ext = os.path.splitext(filename)
            if stem == compatible and ext in BINDING_EXTENSIONS:
                return os.path.join(dirpath, filename)
    return None


def _extract_yaml_block_scalar(content: str, key: str) -> str | None:
    m = re.search(rf'^{key}:\s*\|\s*\n((?:[ \t]+.*\n?)+)', content, re.MULTILINE)
    if not m:
        return None
    lines = m.group(1).splitlines()
    indents = [len(line) - len(line.lstrip(' ')) for line in lines if line.strip()]
    if not indents:
        return None
    indent = min(indents)
    dedented = [line[indent:] if len(line) >= indent else line for line in lines]
    return ' '.join(line.strip() for line in dedented if line.strip())


def parse_yaml_binding(binding_path: str) -> tuple[str, str] | None:
    with open(binding_path) as f:
        content = f.read()

    title_match = re.search(r'^title:\s*(.+)$', content, re.MULTILINE)
    if not title_match:
        return None
    title = title_match.group(1).strip()

    description = _extract_yaml_block_scalar(content, 'description')
    if description is None:
        description_match = re.search(r'^description:\s*(.+)$', content, re.MULTILINE)
        description = description_match.group(1).strip() if description_match else None
    if description is None:
        return None

    return title, description


def parse_legacy_binding(binding_path: str) -> tuple[str, str] | None:
    with open(binding_path) as f:
        lines = f.read().splitlines()

    index = 0
    while index < len(lines) and not lines[index].strip():
        index += 1
    if index >= len(lines):
        return None
    title = lines[index].strip()
    index += 1

    if index < len(lines) and re.fullmatch(r'=+', lines[index].strip()):
        index += 1
    while index < len(lines) and not lines[index].strip():
        index += 1

    description_lines = []
    while index < len(lines) and lines[index].strip():
        description_lines.append(lines[index].strip())
        index += 1
    if not description_lines:
        return None

    return title, ' '.join(description_lines)


def parse_binding(binding_path: str) -> tuple[str, str] | None:
    ext = os.path.splitext(binding_path)[1]
    if ext in ('.yaml', '.yml'):
        return parse_yaml_binding(binding_path)
    return parse_legacy_binding(binding_path)


def format_binding_hover(kernel_source_root: str, binding_path: str, title: str, description: str) -> str:
    relpath = os.path.relpath(binding_path, kernel_source_root).replace(os.sep, '/')
    return f'## {title} - {relpath}\n\n{description}'


def hover_for_compatible(file_path: str, compatible: str) -> str | None:
    """Return kernel binding hover markdown for a compatible string, if any.

    Returns ``None`` when there is no relevant kernel source context, no
    matching binding file, or the binding file could not be parsed.
    """
    kernel_source_root = find_kernel_source_root(file_path)
    if kernel_source_root is None:
        return None

    binding_path = find_binding_file(kernel_source_root, compatible)
    if binding_path is None:
        return None

    parsed = parse_binding(binding_path)
    if parsed is None:
        return None

    title, description = parsed
    return format_binding_hover(kernel_source_root, binding_path, title, description)
