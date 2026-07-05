import json
import re
import sys


from anakins_dtls._generated_hover_docs import HOVER_DOCS


documents: dict[str, str] = {}

ROOT_NODE_PROPERTIES = {
    'serial-number',
    'chassis-type',
}

DEVICE_NODE_ONLY_PROPERTIES = {
    'memory-region',
    'memory-region-names',
}

NEXUS_ONLY_PROPERTIES = {
    'interrupt-map',
    'interrupt-map-mask',
    'gpio-map',
    'gpio-map-mask',
    'gpio-map-pass-thru',
    '#gpio-cells',
}

INTERRUPT_NEXUS_PROPERTIES = {
    'interrupt-map',
    'interrupt-map-mask',
}

SPECIFIER_NEXUS_PROPERTIES = {
    'gpio-map',
    'gpio-map-mask',
    'gpio-map-pass-thru',
    '#gpio-cells',
}

STANDARD_NODE_NAMES = {
    'aliases',
    'chosen',
    'cpus',
    'memory',
    'reserved-memory',
}

STANDARD_CHILD_NODE_NAMES = {
    ('cpus', 'cpu'): '/cpus/cpu*',
}

COMPATIBLE_VALUE_DOCS = {
    'cache': '/cpus/cpu*/l?-cache',
    'ns16550': 'ns16550',
    'open-pic': 'open-pic',
    'simple-bus': 'simple-bus',
}

DTS_DIRECTIVE_DOCS = {
    '/dts-v1/': 'dts:version-directive',
    '/include/': 'dts:include-directive',
    '/memreserve/': 'dts:memory-reservation',
    '/delete-node/': 'dts:delete-node',
    '/delete-property/': 'dts:delete-property',
}

DTS_OPERATOR_DOCS = {
    '<<': 'dts:operator:left-shift',
    '>>': 'dts:operator:right-shift',
    '&&': 'dts:operator:logical-and',
    '||': 'dts:operator:logical-or',
    '<=': 'dts:operator:less-than-or-equal',
    '>=': 'dts:operator:greater-than-or-equal',
    '==': 'dts:operator:equal',
    '!=': 'dts:operator:not-equal',
    '+': 'dts:operator:add',
    '-': 'dts:operator:subtract',
    '*': 'dts:operator:multiply',
    '/': 'dts:operator:divide',
    '%': 'dts:operator:modulo',
    '&': 'dts:operator:bitwise-and',
    '|': 'dts:operator:bitwise-or',
    '^': 'dts:operator:exclusive-or',
    '~': 'dts:operator:bitwise-not',
    '!': 'dts:operator:logical-not',
    '<': 'dts:operator:less-than',
    '>': 'dts:operator:greater-than',
    '?': 'dts:operator:ternary-condition',
    ':': 'dts:operator:ternary-separator',
}

CHAPTER4_NODE_NAMES = {
    'network-device': 'network-class',
    'ethernet-device': 'ethernet',
}

NS16550_PROPERTIES = {
    'compatible',
    'clock-frequency',
    'current-speed',
    'interrupts',
    'reg',
    'reg-shift',
    'virtual-reg',
}

NETWORK_PROPERTIES = {
    'address-bits',
    'local-mac-address',
    'mac-address',
    'max-frame-size',
}

ETHERNET_PROPERTIES = {
    'max-speed',
    'phy-connection-type',
    'phy-handle',
}

OPEN_PIC_PROPERTIES = {
    'compatible',
    'reg',
    '#interrupt-cells',
    '#address-cells',
    'interrupt-controller',
}

SIMPLE_BUS_PROPERTIES = {
    'compatible',
    'ranges',
    'nonposted-mmio',
}

RESERVED_MEMORY_NODE_PROPERTIES = {
    '#address-cells',
    '#size-cells',
    'ranges',
}

RESERVED_MEMORY_CHILD_PROPERTIES = {
    'compatible',
    'reg',
}

CPUS_NODE_PROPERTIES = {
    '#address-cells',
    '#size-cells',
}

CPU_NODE_PROPERTIES = {
    'device_type',
    'reg',
}

CACHE_NODE_PROPERTIES = {
    'compatible',
}

def _send(msg: dict) -> None:
    data = json.dumps(msg, separators=(',', ':')).encode('utf-8')
    header = f'Content-Length: {len(data)}\r\n\r\n'.encode('ascii')
    sys.stdout.buffer.write(header + data)
    sys.stdout.buffer.flush()


def _read_message() -> dict | None:
    buf = b''
    while b'\r\n\r\n' not in buf:
        chunk = sys.stdin.buffer.read(1)
        if not chunk:
            return None
        buf += chunk

    header_part, body = buf.split(b'\r\n\r\n', 1)
    header_text = header_part.decode('ascii', errors='replace')
    content_length = None
    for line in header_text.split('\r\n'):
        if line.lower().startswith('content-length:'):
            content_length = int(line.split(':', 1)[1].strip())
            break

    if content_length is None:
        return None

    needed = content_length - len(body)
    while needed > 0:
        chunk = sys.stdin.buffer.read(needed)
        if not chunk:
            return None
        body += chunk
        needed -= len(chunk)

    return json.loads(body.decode('utf-8'))


def _property_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    if not line_text.strip():
        return None

    m = re.match(r'([\w,#-]+)\s*[=;]', line_text.strip())
    if not m:
        return None

    prop = m.group(1)
    idx = line_text.find(prop)
    if idx == -1:
        return None

    if idx <= character <= idx + len(prop):
        return prop
    return None


def _status_value_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    m = re.match(r'\s*status\s*=\s*"([^"]+)"', line_text)
    if not m:
        return None

    start, end = m.span(1)
    if start <= character <= end:
        return f'status:{m.group(1)}'
    return None


def _root_node_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    idx = line_text.find('/')
    if idx == -1:
        return None
    if re.match(r'\s*/\s*\{', line_text) and idx <= character <= idx + 1:
        return '__root__'
    return None


def _standard_node_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    m = re.match(r'\s*(?:(\w+):\s*)?([\w,-]+)(?:@[\w,-]+)?\s*\{', line_text)
    if not m:
        return None
    node_name = m.group(2)
    doc_key = None
    if node_name in STANDARD_NODE_NAMES and _node_depth_at(text, line) == 1:
        doc_key = f'/{node_name}'
    else:
        parent = _parent_node_name_at(text, line)
        doc_key = STANDARD_CHILD_NODE_NAMES.get((parent, node_name))
    if doc_key is None:
        return None

    start, end = m.span(2)
    if start <= character <= end:
        return doc_key
    return None


def _chapter4_node_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    m = re.match(r'\s*(?:(\w+):\s*)?([\w,-]+)(?:@[\w,-]+)?\s*\{', line_text)
    if not m:
        return None

    start, end = m.span(2)
    if not start <= character <= end:
        return None

    node_name = m.group(2)
    return CHAPTER4_NODE_NAMES.get(node_name)


def _node_depth_at(text: str, line: int) -> int:
    lines = text.split('\n')
    depth = 0
    for line_text in lines[:line]:
        depth += line_text.count('{')
        depth -= line_text.count('}')
    return depth


def _parent_node_name_at(text: str, line: int) -> str | None:
    stack = _ancestor_node_names_at(text, line)
    return stack[-1] if stack else None


def _current_node_name_at(text: str, line: int) -> str | None:
    return _parent_node_name_at(text, line)


def _ancestor_node_names_at(text: str, line: int) -> list[str]:
    stack: list[str] = []
    for line_text in text.split('\n')[:line]:
        m = re.match(r'\s*(?:(\w+):\s*)?([\w,-]+)(?:@[\w,-]+)?\s*\{', line_text)
        if m:
            stack.append(m.group(2))
        for _ in range(line_text.count('}')):
            if stack:
                stack.pop()
    return stack


def _node_has_property_at(text: str, line: int, prop: str) -> bool:
    stack: list[int] = []
    lines = text.split('\n')
    for index, line_text in enumerate(lines[:line]):
        m = re.match(r'\s*(?:(\w+):\s*)?([\w,-]+)(?:@[\w,-]+)?\s*\{', line_text)
        if m:
            stack.append(index)
        for _ in range(line_text.count('}')):
            if stack:
                stack.pop()

    if not stack:
        return False

    depth = 1
    for line_text in lines[stack[-1] + 1:]:
        if depth == 1:
            m = re.match(r'\s*([\w,#-]+)\s*[=;]', line_text)
            if m and m.group(1) == prop:
                return True
        depth += line_text.count('{')
        depth -= line_text.count('}')
        if depth == 0:
            return False
    return False


def _current_node_property_value_contains(text: str, line: int, prop: str, value: str) -> bool:
    stack: list[int] = []
    lines = text.split('\n')
    for index, line_text in enumerate(lines[:line]):
        m = re.match(r'\s*(?:(\w+):\s*)?([\w,-]+)(?:@[\w,-]+)?\s*\{', line_text)
        if m:
            stack.append(index)
        for _ in range(line_text.count('}')):
            if stack:
                stack.pop()

    if not stack:
        return False

    depth = 1
    pattern = re.compile(rf'\s*{re.escape(prop)}\s*=\s*(.*)')
    for line_text in lines[stack[-1] + 1:]:
        if depth == 1:
            m = pattern.match(line_text)
            if m and value in m.group(1):
                return True
        depth += line_text.count('{')
        depth -= line_text.count('}')
        if depth == 0:
            return False
    return False


def _compatible_value_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    if not re.match(r'\s*compatible\s*=', line_text):
        return None

    for m in re.finditer(r'"([^"]+)"', line_text):
        if m.start(1) <= character <= m.end(1):
            return COMPATIBLE_VALUE_DOCS.get(m.group(1))
    return None


def _dts_directive_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    for directive, doc_key in DTS_DIRECTIVE_DOCS.items():
        idx = line_text.find(directive)
        if idx != -1 and idx <= character <= idx + len(directive):
            return doc_key
    return None


def _dts_label_or_reference_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    for m in re.finditer(r'&\{[^}]+\}', line_text):
        if m.start() <= character <= m.end():
            return 'dts:path-reference'
    for m in re.finditer(r'&[A-Za-z_][\w]*', line_text):
        if m.start() <= character <= m.end():
            return 'dts:label-reference'
    for m in re.finditer(r'\b[A-Za-z_][\w]*:', line_text):
        if m.start() <= character <= m.end():
            return 'dts:label-definition'
    return None


def _dts_value_syntax_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    cell_start = line_text.find('<')
    cell_end = line_text.rfind('>')
    if cell_start != -1 and cell_end != -1 and cell_start <= character <= cell_end:
        return 'dts:cell-array'
    for pattern, doc_key in (
        (r'\[[^\]]*\]', 'dts:bytestring'),
        (r'"[^"]*"', 'dts:string-value'),
    ):
        for m in re.finditer(pattern, line_text):
            if m.start() <= character <= m.end():
                return doc_key
    return None


def _dts_cell_array_delimiter_at(text: str, line: int, character: int) -> bool:
    lines = text.split('\n')
    if line >= len(lines):
        return False
    line_text = lines[line]
    return character in {line_text.find('<'), line_text.rfind('>')}


def _dts_operator_at(text: str, line: int, character: int) -> str | None:
    lines = text.split('\n')
    if line >= len(lines):
        return None
    line_text = lines[line]
    for operator, doc_key in DTS_OPERATOR_DOCS.items():
        start = 0
        while True:
            idx = line_text.find(operator, start)
            if idx == -1:
                break
            if idx <= character < idx + len(operator):
                if operator in {'<', '>'} and _dts_cell_array_delimiter_at(text, line, character):
                    start = idx + len(operator)
                    continue
                return doc_key
            start = idx + len(operator)
    return None


def _is_nexus_node_at(text: str, line: int, prop: str) -> bool:
    if prop in INTERRUPT_NEXUS_PROPERTIES:
        return _node_has_property_at(text, line, '#interrupt-cells')
    if prop in SPECIFIER_NEXUS_PROPERTIES:
        return _node_has_property_at(text, line, '#gpio-cells')
    return False


def _hover_doc_key_for_property(text: str, line: int, prop: str) -> str:
    if prop in {'#address-cells', '#size-cells', 'compatible', 'model'} and _node_depth_at(text, line) == 1:
        return f'root:{prop}'
    node_name = _current_node_name_at(text, line)
    ancestors = _ancestor_node_names_at(text, line)
    if prop in RESERVED_MEMORY_NODE_PROPERTIES and node_name == 'reserved-memory':
        return f'reserved-memory:{prop}'
    if prop in RESERVED_MEMORY_CHILD_PROPERTIES and 'reserved-memory' in ancestors:
        return f'reserved-memory:{prop}'
    if prop in CPUS_NODE_PROPERTIES and node_name == 'cpus':
        return f'cpus:{prop}'
    if prop in CPU_NODE_PROPERTIES and ancestors[-2:] == ['cpus', 'cpu']:
        return f'cpu:{prop}'
    if prop in CACHE_NODE_PROPERTIES and _current_node_property_value_contains(text, line, 'compatible', 'cache'):
        return f'cache:{prop}'
    if prop in OPEN_PIC_PROPERTIES and _current_node_property_value_contains(text, line, 'compatible', 'open-pic'):
        return f'open-pic:{prop}'
    if prop in NS16550_PROPERTIES and _current_node_property_value_contains(text, line, 'compatible', 'ns16550'):
        return f'ns16550:{prop}'
    if prop in SIMPLE_BUS_PROPERTIES and _current_node_property_value_contains(text, line, 'compatible', 'simple-bus'):
        return f'simple-bus:{prop}'
    if prop in NETWORK_PROPERTIES and node_name == 'network-device':
        return f'network:{prop}'
    if prop in ETHERNET_PROPERTIES and node_name == 'ethernet-device':
        return f'ethernet:{prop}'
    if prop == 'clock-frequency' and node_name == 'serial':
        return 'serial:clock-frequency'
    if prop == 'current-speed' and node_name == 'serial':
        return 'serial:current-speed'
    if prop in {'reg-shift', 'label'}:
        return f'misc:{prop}'
    if prop == 'clock-frequency':
        if ancestors[-2:] != ['cpus', 'cpu']:
            return 'misc:clock-frequency'
    return prop


def _strip_heading_source(doc: str) -> str:
    heading, sep, rest = doc.partition('\n')
    heading = re.sub(r' - [^\n]+$', '', heading)
    return f'{heading}{sep}{rest}' if sep else heading


def handle_notification(method: str, params: dict | None) -> None:
    if method == 'textDocument/didOpen':
        uri = params['textDocument']['uri']
        text = params['textDocument']['text']
        documents[uri] = text
    elif method == 'textDocument/didChange':
        uri = params['textDocument']['uri']
        changes = params.get('contentChanges', [])
        if changes:
            documents[uri] = changes[-1].get('text', '')


def handle_request(method: str, params: dict | None) -> dict | None:
    if method == 'initialize':
        return {
            'capabilities': {
                'textDocumentSync': 1,
                'hoverProvider': True,
            },
        }
    elif method == 'textDocument/hover':
        uri = params['textDocument']['uri']
        line = params['position']['line']
        character = params['position']['character']
        text = documents.get(uri, '')
        if not text:
            return None

        prop = _root_node_at(text, line, character)
        if prop is None:
            prop = _standard_node_at(text, line, character)
        if prop is None:
            prop = _chapter4_node_at(text, line, character)
        if prop is None:
            prop = _status_value_at(text, line, character)
        if prop is None:
            prop = _compatible_value_at(text, line, character)
        if prop is None:
            prop = _dts_directive_at(text, line, character)
        if prop is None:
            prop = _dts_label_or_reference_at(text, line, character)
        if prop is None:
            prop = _dts_operator_at(text, line, character)
        if prop is None:
            prop = _dts_value_syntax_at(text, line, character)
        if prop is None:
            prop = _property_at(text, line, character)
        if prop is None:
            return None
        if prop in ROOT_NODE_PROPERTIES and _node_depth_at(text, line) != 1:
            return None
        if prop in DEVICE_NODE_ONLY_PROPERTIES:
            ancestors = _ancestor_node_names_at(text, line)
            if _node_depth_at(text, line) == 1 or 'reserved-memory' in ancestors:
                return None
        if prop in NEXUS_ONLY_PROPERTIES and not _is_nexus_node_at(text, line, prop):
            return None

        doc_key = _hover_doc_key_for_property(text, line, prop)
        doc = HOVER_DOCS.get(doc_key)
        if doc is None and ',' in prop:
            doc = HOVER_DOCS.get(prop.split(',', 1)[1])
        if doc is None and prop.startswith('power-isa-'):
            doc = HOVER_DOCS.get('power-isa-*')
        return {
            'contents': {
                'kind': 'markdown',
                'value': doc,
            },
        }
    return None


def dispatch(msg: dict) -> None:
    method = msg.get('method')
    params = msg.get('params')
    msg_id = msg.get('id')

    if msg_id is None:
        handle_notification(method, params)
        return

    result = handle_request(method, params)
    _send({'jsonrpc': '2.0', 'id': msg_id, 'result': result})


def run() -> None:
    while True:
        msg = _read_message()
        if msg is None:
            break
        try:
            dispatch(msg)
        except Exception as e:
            print(f'Error: {e}', file=sys.stderr)
