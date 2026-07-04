import os
import sys
import pytest
from pytest_bdd import given, when, then, parsers
from tests.lsp_client import LSPClient

sys.path.insert(0, os.path.join(os.getcwd(), 'tools'))

from generate_docs import (
    _format_section,
    format_table_row_hover,
    format_value_table_row_hover,
    get_section,
)

TARGET = {
    'Root node declaration': (3, 1),
    'aliases node declaration': (25, 9),
    'memory node declaration': (28, 9),
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
    'initial-mapped-area': (29, 9),
    'hotpluggable': (30, 9),
    'reserved-memory node declaration': (33, 5),
    'size': (35, 13),
    'alignment': (36, 13),
    'alloc-ranges': (37, 13),
    'no-map': (38, 13),
    'reusable': (39, 13),
    'chosen node declaration': (45, 5),
    'bootargs': (46, 9),
    'bootsource': (47, 9),
    'stdout-path': (48, 9),
    'stdin-path': (49, 9),
    'cpus node declaration': (52, 5),
    'cpu node declaration under the cpus node': (56, 9),
    'clock-frequency': (59, 13),
    'timebase-frequency': (60, 13),
    'enable-method': (62, 13),
    'cpu-release-addr': (63, 13),
    'power-isa-version': (64, 13),
    'power-isa-e-hv': (65, 13),
    'cache-op-block-size': (66, 13),
    'reservation-granule-size': (67, 13),
    'mmu-type': (68, 13),
    'tlb-split': (69, 13),
    'tlb-size': (70, 13),
    'tlb-sets': (71, 13),
    'd-tlb-size': (72, 13),
    'd-tlb-sets': (73, 13),
    'i-tlb-size': (74, 13),
    'i-tlb-sets': (75, 13),
    'cache-unified': (76, 13),
    'cache-size': (77, 13),
    'cache-sets': (78, 13),
    'cache-block-size': (79, 13),
    'cache-line-size': (80, 13),
    'i-cache-size': (81, 13),
    'i-cache-sets': (82, 13),
    'i-cache-block-size': (83, 13),
    'i-cache-line-size': (84, 13),
    'd-cache-size': (85, 13),
    'd-cache-sets': (86, 13),
    'd-cache-block-size': (87, 13),
    'd-cache-line-size': (88, 13),
    'next-level-cache': (89, 13),
    'cache node declaration': (91, 19),
    'cache-level': (93, 17),
    'memory-region': (102, 9),
    'memory-region-names': (103, 9),
    'interrupts': (109, 9),
    'interrupt-parent': (110, 9),
    'interrupts-extended': (111, 9),
    'interrupt-controller': (112, 9),
    '#interrupt-cells': (113, 9),
}

NEXUS_TARGET = {
    ('interrupt-map', 'pci nexus node'): (132, 9),
    ('interrupt-map-mask', 'pci nexus node'): (133, 9),
    ('gpio-map', 'connector nexus node'): (138, 9),
    ('gpio-map-mask', 'connector nexus node'): (139, 9),
    ('gpio-map-pass-thru', 'connector nexus node'): (140, 9),
    ('#gpio-cells', 'connector nexus node'): (137, 9),
}

CPU_NODE_TARGET = {
    'clock-frequency': (59, 13),
    'timebase-frequency': (60, 13),
    'enable-method': (62, 13),
    'cpu-release-addr': (63, 13),
}

STATUS_VALUE_TARGET = {
    'okay': (104, 19),
    'disabled': (105, 19),
    'reserved': (106, 19),
    'fail': (107, 19),
    'fail-sss': (108, 19),
}

NON_ROOT_TARGET = {
    'serial-number': (99, 9),
    'chassis-type': (100, 9),
    'aliases node declaration': (121, 13),
    'memory node declaration': (124, 13),
}

INVALID_PLACEMENT_TARGET = {
    ('memory-region', 'root node'): (22, 5),
    ('memory-region-names', 'root node'): (23, 5),
    ('memory-region', 'reserved-memory node'): (40, 13),
    ('memory-region-names', 'reserved-memory node'): (41, 13),
    ('interrupt-map', 'non-nexus device node'): (123, 9),
    ('interrupt-map-mask', 'non-nexus device node'): (124, 9),
    ('gpio-map', 'non-nexus device node'): (125, 9),
    ('gpio-map-mask', 'non-nexus device node'): (126, 9),
    ('gpio-map-pass-thru', 'non-nexus device node'): (127, 9),
    ('interrupt-map', 'node named nexus without nexus properties'): (144, 9),
    ('interrupt-map-mask', 'node named nexus without nexus properties'): (145, 9),
    ('gpio-map', 'node named nexus without nexus properties'): (146, 9),
    ('gpio-map-mask', 'node named nexus without nexus properties'): (147, 9),
    ('gpio-map-pass-thru', 'node named nexus without nexus properties'): (148, 9),
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


@when(parsers.re(r'hovering over an? (?P<hover_target>(?!.* in a ).+?)(?: on the root node)?$'), target_fixture='response')
def hover_over(lsp, uri, hover_target):
    return _hover_at(lsp, uri, TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) in a (?P<placement>pci nexus node|connector nexus node)$'), target_fixture='response')
def hover_over_nexus_property(lsp, uri, hover_target, placement):
    hover_target = _normalize_hover_target(hover_target)
    pos = NEXUS_TARGET.get((hover_target, placement))
    if pos is None:
        pytest.fail(f'Unknown nexus hover target: {hover_target} in {placement}')
    line, col = pos
    return lsp.hover(uri, line - 1, col - 1)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on a cpu node$'), target_fixture='response')
def hover_over_cpu_node_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, CPU_NODE_TARGET, hover_target)


@when(parsers.parse('the "status" property value is hovered for {value}'), target_fixture='response')
def hover_over_status_value(lsp, uri, value):
    return _hover_at(lsp, uri, STATUS_VALUE_TARGET, value)


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


@then(parsers.re(r'hovering over an? (?P<hover_target>.+?) (?:on|in) (?:a|the) (?P<placement>root node|reserved-memory node|non-nexus device node|node named nexus without nexus properties) returns nothing'))
def check_no_hover_in_invalid_placement(lsp, uri, hover_target, placement):
    hover_target = _normalize_hover_target(hover_target)
    pos = INVALID_PLACEMENT_TARGET.get((hover_target, placement))
    if pos is None:
        pytest.fail(f'Unknown invalid hover target: {hover_target} in {placement}')
    line, col = pos
    response = lsp.hover(uri, line - 1, col - 1)
    result = response.get('result')
    if result is not None:
        contents = result.get('contents', '')
        if isinstance(contents, dict):
            text = contents.get('value', '')
        else:
            text = contents or ''
        pytest.fail(
            f'Expected no hover for target: {hover_target} in {placement}\n'
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


@then(parsers.parse('the hover does not return usage, value type, and definition for "{property}" from the "{table}" table from the devicetree specification'))
def check_hover_excludes_table_row(response, property, table):
    text = _hover_text(response)
    unexpected = format_table_row_hover(table, property)
    if unexpected is None:
        pytest.fail(f'Unknown table row: {table}.{property}')
    if text == unexpected:
        pytest.fail(
            f'Hover response unexpectedly matched table row\n'
            f'  Table: {table}\n'
            f'  Property: {property}\n'
            f'  Got: {text[:500]}...'
        )


@then(parsers.parse('the hover does not return the contents of the "{section}" section under the "{parent}" section from the devicetree specification'))
def check_hover_excludes_section_under_parent(response, section, parent):
    from generate_docs import get_section_under

    text = _hover_text(response)
    raw = get_section_under(parent, section)
    if raw is None:
        pytest.fail(f'Unknown section: {parent}.{section}')
    unexpected = _format_section(raw)
    if text == unexpected:
        pytest.fail(
            f'Hover response unexpectedly matched spec section\n'
            f'  Parent section: {parent}\n'
            f'  Section: {section}\n'
            f'  Got: {text[:500]}...'
        )


@then(parsers.parse('the hover returns value and description for {value} from the "{table}" table from the devicetree specification'))
def check_hover_value_table_row(response, value, table):
    text = _hover_text(response)
    expected = format_value_table_row_hover(table, value)
    if expected is None:
        pytest.fail(f'Unknown table row: {table}.{value}')
    if text != expected:
        pytest.fail(
            f'Hover response did not match table row\n'
            f'  Table: {table}\n'
            f'  Value: {value}\n'
            f'  Expected: {expected[:500]}...\n'
            f'  Got: {text[:500]}...'
        )
