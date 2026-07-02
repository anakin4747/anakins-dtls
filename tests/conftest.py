import os
import pytest

from lsp_client import LSPClient


@pytest.fixture(scope='function')
def lsp():
    cmd = os.path.join(os.getcwd(), 'anakins-dtls')
    client = LSPClient(cmd=cmd, root=os.getcwd())
    client.start()
    client.initialize()
    yield client
    client.stop()


@pytest.fixture(scope='function')
def uri(lsp):
    fixture = os.path.join(os.getcwd(), 'tests', 'fixtures', 'hover_standard_properties.dts')
    return lsp.open(fixture)
