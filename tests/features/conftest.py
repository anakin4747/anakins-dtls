import os
import pytest
from pytest_bdd import given, when, then, parsers
from tests.lsp_client import LSPClient

TARGET = {
    'compatible': (4, 5),
    'model': (5, 5),
    '#address-cells': (6, 5),
    '#size-cells': (7, 5),
    'phandle': (9, 5),
    'status': (10, 5),
    'reg': (11, 5),
    'virtual-reg': (12, 5),
    'ranges': (13, 5),
    'dma-ranges': (14, 5),
    'dma-coherent': (15, 5),
    'dma-noncoherent': (16, 5),
    'name': (17, 5),
    'device_type': (18, 5),
}

EXPECTED = {
    'compatible': 'define the specific programming model for the device',
    'model': "specifies the manufacturer's model number",
    'phandle': 'specifies a numerical identifier for a node',
    'status': 'indicates the operational status of a device',
    'address-cells and size-cells': 'how child device nodes should be addressed',
    'reg': "describes the address of the device's resources",
    'virtual-reg': 'specifies an effective address',
    'ranges': 'provides a means of defining a mapping or translation',
    'dma-ranges': 'describes the direct memory access',
    'dma-coherent': 'capable of coherent DMA operations',
    'dma-noncoherent': 'not capable of coherent DMA operations',
    'name': 'is a string specifying the name of the node',
    'device_type': 'was used in IEEE 1275',
}

@pytest.fixture
def ctx():
    return {}


@given('the language server is running')
def server_running(ctx, request):
    lsp = LSPClient(cmd=['python3', '-m', 'anakins_dtls'], root=os.getcwd())
    lsp.start()
    request.addfinalizer(lsp.stop)
    lsp.initialize()
    ctx['lsp'] = lsp


@given('a devicetree source file is open')
def file_open(ctx):
    lsp = ctx['lsp']
    fixture = os.path.join(os.getcwd(), 'tests', 'fixtures', 'hover_standard_properties.dts')
    uri = lsp.open(fixture)
    ctx['uri'] = uri


@given(parsers.re(r'a (?:node|bus node|cpu node) with.*'))
def node_with():
    pass


@when(parsers.parse('hovering over "{property}"'))
def hover_over(ctx, property):
    lsp = ctx['lsp']
    uri = ctx['uri']
    pos = TARGET.get(property)
    if pos is None:
        pytest.fail(f'Unknown property: {property}')
    line, col = pos
    ctx['response'] = lsp.hover(uri, line - 1, col - 1)
    ctx['property'] = property


@then(parsers.parse('the hover returns the contents of the "{subsection}" subsection from the devicetree specification'))
def check_hover(ctx, subsection):
    resp = ctx.get('response')
    if resp is None:
        pytest.fail('No hover response stored')
    result = resp.get('result')
    if result is None:
        pytest.fail('Hover returned null result (no documentation for property)')
    contents = result.get('contents', '')
    if isinstance(contents, dict):
        text = contents.get('value', '')
    else:
        text = contents or ''
    if not text:
        pytest.fail('Hover contents is empty')
    expected = EXPECTED.get(subsection)
    if expected is None:
        pytest.fail(f'Unknown subsection: {subsection}')
    if expected not in text:
        pytest.fail(
            f'Expected text not found in hover response\n'
            f'  Expected substring: {expected}\n'
            f'  Got: {text[:200]}...'
        )
