import subprocess
import json
import select
import os
import time


class LSPClient:
    def __init__(self, cmd='anakins-dtls', root='.', timeout=10):
        self.cmd = cmd
        self.root = root
        self.timeout = timeout
        self._id = 0
        self._proc = None

    def _next_id(self):
        self._id += 1
        return self._id

    def _send(self, msg):
        data = json.dumps(msg, separators=(',', ':')).encode('utf-8')
        header = f'Content-Length: {len(data)}\r\n\r\n'.encode('ascii')
        self._proc.stdin.write(header + data)
        self._proc.stdin.flush()

    def start(self):
        self._proc = subprocess.Popen(
            self.cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def stop(self):
        if not self._proc:
            return
        try:
            self.notify('exit', None)
        except Exception:
            pass
        self._proc.terminate()
        self._proc.wait(timeout=5)
        self._proc = None

    def _read_message(self):
        buf = b''
        deadline = time.monotonic() + self.timeout

        while b'\r\n\r\n' not in buf:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('LSPClient: timeout waiting for header')
            r, _, _ = select.select([self._proc.stdout], [], [], remaining)
            if not r:
                raise TimeoutError('LSPClient: timeout waiting for header')
            chunk = os.read(self._proc.stdout.fileno(), 8192)
            if not chunk:
                raise EOFError('LSPClient: unexpected EOF from server')
            buf += chunk

        header_part, body = buf.split(b'\r\n\r\n', 1)
        header_text = header_part.decode('ascii')
        content_length = None
        for line in header_text.split('\r\n'):
            if line.lower().startswith('content-length:'):
                content_length = int(line.split(':', 1)[1].strip())
                break
        if content_length is None:
            raise ValueError('LSPClient: missing Content-Length header')

        needed = content_length - len(body)
        while needed > 0:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('LSPClient: timeout waiting for body')
            r, _, _ = select.select([self._proc.stdout], [], [], remaining)
            if not r:
                raise TimeoutError('LSPClient: timeout waiting for body')
            chunk = os.read(self._proc.stdout.fileno(), needed)
            if not chunk:
                raise EOFError('LSPClient: unexpected EOF from server')
            body += chunk
            needed -= len(chunk)

        return json.loads(body.decode('utf-8'))

    def _skip_notifications(self):
        while True:
            r, _, _ = select.select([self._proc.stdout], [], [], 0.1)
            if not r:
                break
            buf = b''
            while b'\r\n\r\n' not in buf:
                r2, _, _ = select.select([self._proc.stdout], [], [], 1)
                if not r2:
                    return
                chunk = os.read(self._proc.stdout.fileno(), 8192)
                if not chunk:
                    return
                buf += chunk
            header_part, body = buf.split(b'\r\n\r\n', 1)
            header_text = header_part.decode('ascii')
            content_length = None
            for line in header_text.split('\r\n'):
                if line.lower().startswith('content-length:'):
                    content_length = int(line.split(':', 1)[1].strip())
                    break
            if content_length is None:
                return
            needed = content_length - len(body)
            while needed > 0:
                r3, _, _ = select.select([self._proc.stdout], [], [], 1)
                if not r3:
                    return
                chunk = os.read(self._proc.stdout.fileno(), needed)
                if not chunk:
                    return
                body += chunk
                needed -= len(chunk)

    def request(self, method, params):
        msg_id = self._next_id()
        self._send({
            'jsonrpc': '2.0',
            'id': msg_id,
            'method': method,
            'params': params,
        })
        while True:
            msg = self._read_message()
            if 'id' in msg:
                return msg

    def notify(self, method, params):
        self._send({
            'jsonrpc': '2.0',
            'method': method,
            'params': params,
        })

    def initialize(self):
        root_uri = 'file://' + os.path.abspath(self.root)
        resp = self.request('initialize', {
            'processId': None,
            'rootUri': root_uri,
            'rootPath': self.root,
            'capabilities': {
                'window': {'workDoneProgress': False},
            },
        })
        self.notify('initialized', {})
        return resp

    def open(self, path):
        full_path = os.path.abspath(path)
        uri = 'file://' + full_path
        with open(full_path) as f:
            text = f.read()
        self.notify('textDocument/didOpen', {
            'textDocument': {
                'uri': uri,
                'languageId': 'dts',
                'version': 1,
                'text': text,
            },
        })
        self._skip_notifications()
        return uri

    def hover(self, uri, line, character):
        resp = self.request('textDocument/hover', {
            'textDocument': {'uri': uri},
            'position': {'line': line, 'character': character},
        })
        return resp
