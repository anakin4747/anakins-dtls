import os
import sys
import pytest
from pytest_bdd import given, when, then, parsers
from tests.lsp_client import LSPClient

sys.path.insert(0, os.path.join(os.getcwd(), 'tools'))

from generate_docs import _format_section, format_table_row_hover, get_section

TARGET = {
    'Root node declaration': (3, 1),
    'aliases node declaration': (23, 9),
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
    'linux,phandle': (19, 5),
    'serial-number': (20, 5),
    'chassis-type': (21, 5),
}

NON_ROOT_TARGET = {
    'serial-number': (28, 9),
    'chassis-type': (29, 9),
    'aliases node declaration': (31, 13),
}


def _normalize_hover_target(hover_target):
    hover_target = hover_target.strip()
    if hover_target.startswith('"') and '"' in hover_target[1:]:
        hover_target = hover_target[1:hover_target.index('"', 1)]
    return hover_target


def _hover_at(lsp, uri, targets, hover_target):
    hover_target = _normalize_hover_target(hover_target)
    pos = targets.get(hover_target)
    if pos is None:
        pytest.fail(f'Unknown hover target: {hover_target}')
    line, col = pos
    return lsp.hover(uri, line - 1, col - 1)

@given('the language server is running', target_fixture='lsp')
def server_running(request):
    lsp = LSPClient(cmd=['python3', '-m', 'anakins_dtls'], root=os.getcwd())
    lsp.start()
    request.addfinalizer(lsp.stop)
    lsp.initialize()
    return lsp


@given('a devicetree source file is open', target_fixture='uri')
def file_open(lsp):
    fixture = os.path.join(os.getcwd(), 'tests', 'fixtures', 'hover_standard_properties.dts')
    return lsp.open(fixture)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?)(?: on the root node)?$'), target_fixture='response')
def hover_over(lsp, uri, hover_target):
    return _hover_at(lsp, uri, TARGET, hover_target)


def _hover_text(response):
    result = response.get('result')
    if result is None:
        pytest.fail('Hover returned null result (no documentation for property)')
    contents = result.get('contents', '')
    if isinstance(contents, dict):
        text = contents.get('value', '')
    else:
        text = contents or ''
    if not text:
        pytest.fail('Hover contents is empty')
    return text


def _get_spec_section(section):
    raw = get_section(section)
    if raw is not None:
        return raw
    if section.startswith('/'):
        path, _, suffix = section.partition(' ')
        return get_section(f'``{path}`` {suffix}')
    return None


@then(parsers.re(r'hovering over an? (?P<hover_target>.+?) outside the root node returns nothing'))
def check_no_hover_outside_root_node(lsp, uri, hover_target):
    hover_target = _normalize_hover_target(hover_target)
    response = _hover_at(lsp, uri, NON_ROOT_TARGET, hover_target)
    result = response.get('result')
    if result is not None:
        contents = result.get('contents', '')
        if isinstance(contents, dict):
            text = contents.get('value', '')
        else:
            text = contents or ''
        pytest.fail(
            f'Expected no hover outside root node for target: {hover_target}\n'
            f'  Got: {text[:500]}...'
        )


@then(parsers.parse('the hover returns the contents of the "{section}" section from the devicetree specification'))
def check_hover(response, section):
    section = section.replace('\\#', '#')
    text = _hover_text(response)
    raw = _get_spec_section(section)
    if raw is None:
        pytest.fail(f'Unknown section: {section}')
    expected = _format_section(raw)
    if text != expected:
        pytest.fail(
            f'Hover response did not match spec section\n'
            f'  Section: {section}\n'
            f'  Expected: {expected[:500]}...\n'
            f'  Got: {text[:500]}...'
        )


@then(parsers.parse('the hover returns usage, value type, and definition for "{property}" from the "{table}" table from the devicetree specification'))
def check_hover_table_row(response, property, table):
    text = _hover_text(response)
    expected = format_table_row_hover(table, property)
    if expected is None:
        pytest.fail(f'Unknown table row: {table}.{property}')
    if text != expected:
        pytest.fail(
            f'Hover response did not match table row\n'
            f'  Table: {table}\n'
            f'  Property: {property}\n'
            f'  Expected: {expected[:500]}...\n'
            f'  Got: {text[:500]}...'
        )
