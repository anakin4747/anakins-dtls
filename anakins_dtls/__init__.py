import json
import re
import sys


from anakins_dtls._hover_docs import HOVER_DOCS


documents: dict[str, str] = {}

ROOT_NODE_PROPERTIES = {
    'serial-number',
    'chassis-type',
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


def _node_depth_at(text: str, line: int) -> int:
    lines = text.split('\n')
    depth = 0
    for line_text in lines[:line]:
        depth += line_text.count('{')
        depth -= line_text.count('}')
    return depth


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
            prop = _property_at(text, line, character)
        if prop is None:
            return None
        if prop in ROOT_NODE_PROPERTIES and _node_depth_at(text, line) != 1:
            return None

        doc = HOVER_DOCS.get(prop)
        if doc is None and ',' in prop:
            doc = HOVER_DOCS.get(prop.split(',', 1)[1])

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
