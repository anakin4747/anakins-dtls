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
    'memory node declaration': (26, 9),
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
    'initial-mapped-area': (27, 9),
    'hotpluggable': (28, 9),
    'reserved-memory node declaration': (31, 5),
    'size': (33, 13),
    'alignment': (34, 13),
    'alloc-ranges': (35, 13),
    'no-map': (36, 13),
    'reusable': (37, 13),
    'chosen node declaration': (41, 5),
    'bootargs': (42, 9),
    'bootsource': (43, 9),
    'stdout-path': (44, 9),
    'stdin-path': (45, 9),
    'cpus node declaration': (48, 5),
    'cpu node declaration under the cpus node': (52, 9),
    'clock-frequency': (55, 13),
    'timebase-frequency': (56, 13),
    'enable-method': (58, 13),
    'cpu-release-addr': (59, 13),
    'power-isa-version': (60, 13),
    'power-isa-e-hv': (61, 13),
    'cache-op-block-size': (62, 13),
    'reservation-granule-size': (63, 13),
    'mmu-type': (64, 13),
    'tlb-split': (65, 13),
    'tlb-size': (66, 13),
    'tlb-sets': (67, 13),
    'd-tlb-size': (68, 13),
    'd-tlb-sets': (69, 13),
    'i-tlb-size': (70, 13),
    'i-tlb-sets': (71, 13),
    'cache-unified': (72, 13),
    'cache-size': (73, 13),
    'cache-sets': (74, 13),
    'cache-block-size': (75, 13),
    'cache-line-size': (76, 13),
    'i-cache-size': (77, 13),
    'i-cache-sets': (78, 13),
    'i-cache-block-size': (79, 13),
    'i-cache-line-size': (80, 13),
    'd-cache-size': (81, 13),
    'd-cache-sets': (82, 13),
    'd-cache-block-size': (83, 13),
    'd-cache-line-size': (84, 13),
    'next-level-cache': (85, 13),
    'cache node declaration': (87, 19),
    'cache-level': (89, 17),
    'memory-region': (98, 9),
    'memory-region-names': (99, 9),
}

NON_ROOT_TARGET = {
    'serial-number': (95, 9),
    'chassis-type': (96, 9),
    'aliases node declaration': (101, 13),
    'memory node declaration': (104, 13),
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
        pytest.fail('Hover returned null result (no documentation for target)')
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
