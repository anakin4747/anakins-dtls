import json
import re
import sys


HOVER_DOCS = {
    'compatible': (
        '**Property name:** `compatible`\n\n'
        '**Value type:** `<stringlist>`\n\n'
        '**Description:**\n\n'
        'The *compatible* property value consists of one or more strings that '
        'define the specific programming model for the device. This list of '
        'strings should be used by a client program for device driver selection.'
    ),
    'model': (
        '**Property name:** `model`\n\n'
        '**Value type:** `<string>`\n\n'
        '**Description:**\n\n'
        'The model property value is a `<string>` that specifies the '
        "manufacturer's model number of the device."
    ),
    'phandle': (
        '**Property name:** `phandle`\n\n'
        '**Value type:** `<u32>`\n\n'
        '**Description:**\n\n'
        'The *phandle* property specifies a numerical identifier for a node '
        'that is unique within the devicetree.'
    ),
    'status': (
        '**Property name:** `status`\n\n'
        '**Value type:** `<string>`\n\n'
        '**Description:**\n\n'
        'The `status` property indicates the operational status of a device.'
    ),
    '#address-cells': (
        '**Property name:** `#address-cells`, `#size-cells`\n\n'
        '**Value type:** `<u32>`\n\n'
        '**Description:**\n\n'
        'The *#address-cells* and *#size-cells* properties may be used in any '
        'device node that has children in the devicetree hierarchy and describes '
        'how child device nodes should be addressed.'
    ),
    '#size-cells': (
        '**Property name:** `#address-cells`, `#size-cells`\n\n'
        '**Value type:** `<u32>`\n\n'
        '**Description:**\n\n'
        'The *#address-cells* and *#size-cells* properties may be used in any '
        'device node that has children in the devicetree hierarchy and describes '
        'how child device nodes should be addressed.'
    ),
    'reg': (
        '**Property name:** `reg`\n\n'
        '**Property value:** `<prop-encoded-array>` encoded as an arbitrary '
        'number of (*address*, *length*) pairs.\n\n'
        '**Description:**\n\n'
        'The *reg* property describes the address of the device\'s resources '
        'within the address space defined by its parent bus.'
    ),
    'virtual-reg': (
        '**Property name:** `virtual-reg`\n\n'
        '**Value type:** `<u32>`\n\n'
        '**Description:**\n\n'
        'The *virtual-reg* property specifies an effective address that maps '
        'to the first physical address specified in the *reg* property of the '
        'device node.'
    ),
    'ranges': (
        '**Property name:** `ranges`\n\n'
        '**Value type:** `<empty>` or `<prop-encoded-array>` encoded as an '
        'arbitrary number of (*child-bus-address*, *parent-bus-address*, '
        '*length*) triplets.\n\n'
        '**Description:**\n\n'
        'The *ranges* property provides a means of defining a mapping or '
        'translation between the address space of the bus (the child address '
        'space) and the address space of the bus node\'s parent (the parent '
        'address space).'
    ),
    'dma-ranges': (
        '**Property name:** `dma-ranges`\n\n'
        '**Value type:** `<empty>` or `<prop-encoded-array>` encoded as an '
        'arbitrary number of (*child-bus-address*, *parent-bus-address*, '
        '*length*) triplets.\n\n'
        '**Description:**\n\n'
        'The *dma-ranges* property is used to describes the direct memory '
        'access (DMA) structure of a memory-mapped bus whose devicetree '
        'parent can be accessed from DMA operations originating from the bus.'
    ),
    'dma-coherent': (
        '**Property name:** `dma-coherent`\n\n'
        '**Value type:** `<empty>`\n\n'
        '**Description:**\n\n'
        'For architectures which are by default non-coherent for I/O, the '
        '*dma-coherent* property is used to indicate a device is capable of '
        'coherent DMA operations.'
    ),
    'dma-noncoherent': (
        '**Property name:** `dma-noncoherent`\n\n'
        '**Value type:** `<empty>`\n\n'
        '**Description:**\n\n'
        'For architectures which are by default coherent for I/O, the '
        '*dma-noncoherent* property is used to indicate a device is not '
        'capable of coherent DMA operations.'
    ),
    'name': (
        '**Property name:** `name`\n\n'
        '**Value type:** `<string>`\n\n'
        '**Description:**\n\n'
        'The *name* property is a string specifying the name of the node. '
        'This property is deprecated, and its use is not recommended.'
    ),
    'device_type': (
        '**Property name:** `device_type`\n\n'
        '**Value type:** `<string>`\n\n'
        '**Description:**\n\n'
        'The *device_type* property was used in IEEE 1275 to describe the '
        "device's FCode programming model."
    ),
}


documents: dict[str, str] = {}


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

    m = re.match(r'([\w#-]+)\s*[=;]', line_text.strip())
    if not m:
        return None

    prop = m.group(1)
    idx = line_text.find(prop)
    if idx == -1:
        return None

    if idx <= character <= idx + len(prop):
        return prop
    return None


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

        prop = _property_at(text, line, character)
        if prop is None:
            return None

        doc = HOVER_DOCS.get(prop)
        if doc is None:
            return None

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
