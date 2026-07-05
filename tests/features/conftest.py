import os
import re
import sys
import pytest
from pytest_bdd import given, when, then, parsers
from tests.lsp_client import LSPClient

sys.path.insert(0, os.path.join(os.getcwd(), 'tools'))

from generate_docs import (
    _append_heading_source,
    _format_section,
    format_table_row_hover,
    format_value_table_row_hover,
    get_section,
    get_section_under,
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
    'size': (41, 13),
    'alignment': (42, 13),
    'alloc-ranges': (43, 13),
    'no-map': (44, 13),
    'reusable': (45, 13),
    'chosen node declaration': (51, 5),
    'bootargs': (52, 9),
    'bootsource': (53, 9),
    'stdout-path': (54, 9),
    'stdin-path': (55, 9),
    'cpus node declaration': (58, 5),
    'cpu node declaration under the cpus node': (62, 9),
    'clock-frequency': (65, 13),
    'timebase-frequency': (66, 13),
    'enable-method': (68, 13),
    'cpu-release-addr': (69, 13),
    'power-isa-version': (70, 13),
    'power-isa-e-hv': (71, 13),
    'cache-op-block-size': (72, 13),
    'reservation-granule-size': (73, 13),
    'mmu-type': (74, 13),
    'tlb-split': (75, 13),
    'tlb-size': (76, 13),
    'tlb-sets': (77, 13),
    'd-tlb-size': (78, 13),
    'd-tlb-sets': (79, 13),
    'i-tlb-size': (80, 13),
    'i-tlb-sets': (81, 13),
    'cache-unified': (82, 13),
    'cache-size': (83, 13),
    'cache-sets': (84, 13),
    'cache-block-size': (85, 13),
    'cache-line-size': (86, 13),
    'i-cache-size': (87, 13),
    'i-cache-sets': (88, 13),
    'i-cache-block-size': (89, 13),
    'i-cache-line-size': (90, 13),
    'd-cache-size': (91, 13),
    'd-cache-sets': (92, 13),
    'd-cache-block-size': (93, 13),
    'd-cache-line-size': (94, 13),
    'next-level-cache': (95, 13),
    'cache': (98, 32),
    'node declaration with a "cache" compatible property value': (97, 19),
    'cache-level': (99, 17),
    'memory-region': (108, 9),
    'memory-region-names': (109, 9),
    'interrupts': (115, 9),
    'interrupt-parent': (116, 9),
    'interrupts-extended': (117, 9),
    'interrupt-controller': (118, 9),
    '#interrupt-cells': (119, 9),
    'ns16550': (177, 24),
    'UART node declaration with an "ns16550" compatible property value': (176, 6),
    'ns16550 UART node declaration': (176, 6),
    'network class device node declaration': (186, 5),
    'Ethernet device node declaration': (193, 5),
    'open-pic': (200, 24),
    'interrupt controller node declaration with an "open-pic" compatible property value': (199, 5),
    'Open PIC interrupt controller node declaration': (199, 5),
    'simple-bus': (208, 24),
    'node declaration with a "simple-bus" compatible property value': (207, 5),
    'simple-bus node declaration': (207, 5),
    'DTS version directive': (1, 2),
    'include directive': (214, 2),
    'memory reservation directive': (216, 2),
    'delete-node directive': (227, 6),
    'delete-property directive': (228, 6),
    'label definition': (219, 7),
    'label reference': (223, 24),
    'full path reference': (224, 28),
    'cell array': (220, 23),
    'bytestring': (221, 19),
    'string property value': (222, 20),
    '+': (220, 26),
    '-': (220, 34),
    '*': (220, 42),
    '/': (220, 50),
    '%': (220, 58),
    '&': (220, 66),
    '|': (220, 74),
    '^': (220, 82),
    '~': (220, 88),
    '<<': (220, 95),
    '>>': (220, 104),
    '&&': (220, 113),
    '||': (220, 122),
    '!': (220, 129),
    '<': (220, 136),
    '>': (220, 144),
    '<=': (220, 152),
    '>=': (220, 161),
    '==': (220, 170),
    '!=': (220, 179),
    '?': (220, 188),
    ':': (220, 192),
}

NEXUS_TARGET = {
    ('interrupt-map', 'pci nexus node'): (138, 9),
    ('interrupt-map-mask', 'pci nexus node'): (139, 9),
    ('gpio-map', 'connector nexus node'): (144, 9),
    ('gpio-map-mask', 'connector nexus node'): (145, 9),
    ('gpio-map-pass-thru', 'connector nexus node'): (146, 9),
    ('#gpio-cells', 'connector nexus node'): (143, 9),
}

CPU_NODE_TARGET = {
    'device_type': (63, 13),
    'reg': (64, 13),
    'clock-frequency': (65, 13),
    'timebase-frequency': (66, 13),
    'enable-method': (68, 13),
    'cpu-release-addr': (69, 13),
}

RESERVED_MEMORY_NODE_TARGET = {
    '#address-cells': (34, 9),
    '#size-cells': (35, 9),
    'ranges': (36, 9),
}

RESERVED_MEMORY_CHILD_TARGET = {
    'reg': (39, 13),
    'compatible': (40, 13),
}

CPUS_NODE_TARGET = {
    '#address-cells': (59, 9),
    '#size-cells': (60, 9),
}

CACHE_NODE_TARGET = {
    'compatible': (98, 17),
}

MISCELLANEOUS_TARGET = {
    'compatible': (158, 9),
    'model': (159, 9),
    '#address-cells': (160, 9),
    '#size-cells': (161, 9),
    'clock-frequency': (162, 9),
    'reg-shift': (163, 9),
    'label': (164, 9),
}

SERIAL_TARGET = {
    'clock-frequency': (172, 9),
    'current-speed': (173, 9),
}

NODE_NAMED_SERIAL_DEVICE_TARGET = {
    'clock-frequency': (168, 9),
}

NS16550_TARGET = {
    'ns16550 UART node declaration': (176, 6),
    'compatible': (177, 9),
    'reg': (178, 9),
    'interrupts': (179, 9),
    'clock-frequency': (180, 9),
    'current-speed': (181, 9),
    'reg-shift': (182, 9),
    'virtual-reg': (183, 9),
}

NETWORK_TARGET = {
    'network class device node declaration': (186, 6),
    'address-bits': (187, 9),
    'local-mac-address': (188, 9),
    'mac-address': (189, 9),
    'max-frame-size': (190, 9),
}

ETHERNET_TARGET = {
    'Ethernet device node declaration': (193, 6),
    'max-speed': (194, 9),
    'phy-connection-type': (195, 9),
    'phy-handle': (196, 9),
}

OPEN_PIC_TARGET = {
    'Open PIC interrupt controller node declaration': (199, 6),
    'compatible': (200, 9),
    'reg': (201, 9),
    'interrupt-controller': (202, 9),
    '#interrupt-cells': (203, 9),
    '#address-cells': (204, 9),
}

SIMPLE_BUS_TARGET = {
    'simple-bus node declaration': (207, 6),
    'compatible': (208, 9),
    'ranges': (209, 9),
    'nonposted-mmio': (210, 9),
}

STATUS_VALUE_TARGET = {
    'okay': (110, 19),
    'disabled': (111, 19),
    'reserved': (112, 19),
    'fail': (113, 19),
    'fail-sss': (114, 19),
}

NON_ROOT_TARGET = {
    'serial-number': (105, 9),
    'chassis-type': (106, 9),
    'aliases node declaration': (121, 13),
    'memory node declaration': (124, 13),
}

INVALID_PLACEMENT_TARGET = {
    ('memory-region', 'root node'): (22, 5),
    ('memory-region-names', 'root node'): (23, 5),
    ('memory-region', 'reserved-memory node'): (46, 13),
    ('memory-region-names', 'reserved-memory node'): (47, 13),
    ('interrupt-map', 'non-nexus device node'): (129, 9),
    ('interrupt-map-mask', 'non-nexus device node'): (130, 9),
    ('gpio-map', 'non-nexus device node'): (131, 9),
    ('gpio-map-mask', 'non-nexus device node'): (132, 9),
    ('gpio-map-pass-thru', 'non-nexus device node'): (133, 9),
    ('interrupt-map', 'node named nexus without nexus properties'): (150, 9),
    ('interrupt-map-mask', 'node named nexus without nexus properties'): (151, 9),
    ('gpio-map', 'node named nexus without nexus properties'): (152, 9),
    ('gpio-map-mask', 'node named nexus without nexus properties'): (153, 9),
    ('gpio-map-pass-thru', 'node named nexus without nexus properties'): (154, 9),
}

def _normalize_hover_target(hover_target):
    hover_target = hover_target.strip()
    m = re.fullmatch(r'"(.+?)" (?:arithmetic|bitwise|logical|relational|ternary) operator', hover_target)
    if m:
        return m.group(1)
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
    fixture = os.path.join(os.getcwd(), 'tests', 'fixtures', 'hover.dts')
    return lsp.open(fixture)


@given('a DTS source language file is open', target_fixture='uri')
def dts_source_language_file_open(lsp):
    fixture = os.path.join(os.getcwd(), 'tests', 'fixtures', 'hover.dts')
    return lsp.open(fixture)


@when(parsers.re(r'hovering over (?:an? |the )(?P<hover_target>(?!.* in a ).+?)(?: on the root node)?$'), target_fixture='response')
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


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) in the reserved-memory node$'), target_fixture='response')
def hover_over_reserved_memory_node_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, RESERVED_MEMORY_NODE_TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on a reserved-memory child node$'), target_fixture='response')
def hover_over_reserved_memory_child_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, RESERVED_MEMORY_CHILD_TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on the cpus node$'), target_fixture='response')
def hover_over_cpus_node_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, CPUS_NODE_TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) in a cache node$'), target_fixture='response')
def hover_over_cache_node_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, CACHE_NODE_TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on a miscellaneous device node$'), target_fixture='response')
def hover_over_miscellaneous_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, MISCELLANEOUS_TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on a serial node$'), target_fixture='response')
def hover_over_serial_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, SERIAL_TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on a node named serial-device$'), target_fixture='response')
def hover_over_node_named_serial_device_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, NODE_NAMED_SERIAL_DEVICE_TARGET, hover_target)


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on an ns16550 UART node$'), target_fixture='response')
def hover_over_ns16550_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, NS16550_TARGET, hover_target)


@when('hovering over a UART node declaration with an "ns16550" compatible property value', target_fixture='response')
def hover_over_ns16550_node(lsp, uri):
    return _hover_at(lsp, uri, NS16550_TARGET, 'ns16550 UART node declaration')


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on a network device node$'), target_fixture='response')
def hover_over_network_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, NETWORK_TARGET, hover_target)


@when('hovering over a network class device node declaration', target_fixture='response')
def hover_over_network_node(lsp, uri):
    return _hover_at(lsp, uri, NETWORK_TARGET, 'network class device node declaration')


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on an Ethernet device node$'), target_fixture='response')
def hover_over_ethernet_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, ETHERNET_TARGET, hover_target)


@when(parsers.parse('hovering over an Ethernet device node declaration'), target_fixture='response')
def hover_over_ethernet_node(lsp, uri):
    return _hover_at(lsp, uri, ETHERNET_TARGET, 'Ethernet device node declaration')


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on an Open PIC interrupt controller node$'), target_fixture='response')
def hover_over_open_pic_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, OPEN_PIC_TARGET, hover_target)


@when(parsers.parse('hovering over an interrupt controller node declaration with an "open-pic" compatible property value'), target_fixture='response')
def hover_over_open_pic_node(lsp, uri):
    return _hover_at(lsp, uri, OPEN_PIC_TARGET, 'Open PIC interrupt controller node declaration')


@when(parsers.re(r'hovering over an? (?P<hover_target>.+?) on a simple-bus node$'), target_fixture='response')
def hover_over_simple_bus_property(lsp, uri, hover_target):
    return _hover_at(lsp, uri, SIMPLE_BUS_TARGET, hover_target)


@when(parsers.parse('hovering over a node declaration with a "simple-bus" compatible property value'), target_fixture='response')
def hover_over_simple_bus_node(lsp, uri):
    return _hover_at(lsp, uri, SIMPLE_BUS_TARGET, 'simple-bus node declaration')


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


def _strip_hover_title_source(text):
    heading, sep, rest = text.partition('\n')
    heading = re.sub(r' - [^\n]+$', '', heading)
    return f'{heading}{sep}{rest}' if sep else heading


def _get_spec_section(section):
    raw = get_section(section)
    if raw is not None:
        return raw
    if section.startswith('/'):
        path, _, suffix = section.partition(' ')
        return get_section(f'``{path}`` {suffix}')
    return None


def _get_spec_section_under(parent, section):
    raw = get_section_under(parent, section)
    if raw is None:
        pytest.fail(f'Unknown section: {parent}.{section}')
    formatted = _format_section(raw)
    return formatted


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


@then(parsers.re(r'hovering over an? (?P<hover_target>.+? compatible property value) returns nothing'))
def check_no_hover(lsp, uri, hover_target):
    hover_target = _normalize_hover_target(hover_target)
    response = _hover_at(lsp, uri, TARGET, hover_target)
    result = response.get('result')
    if result is not None:
        contents = result.get('contents', '')
        if isinstance(contents, dict):
            text = contents.get('value', '')
        else:
            text = contents or ''
        pytest.fail(
            f'Expected no hover for target: {hover_target}\n'
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


@then('no hover is returned')
def check_response_has_no_hover(response):
    result = response.get('result')
    if result is not None:
        contents = result.get('contents', '')
        if isinstance(contents, dict):
            text = contents.get('value', '')
        else:
            text = contents or ''
        pytest.fail(f'Expected no hover\n  Got: {text[:500]}...')


@then(parsers.parse('the hover returns the contents of the "{section}" section from the devicetree specification'))
def check_hover(response, section):
    section = section.replace('\\#', '#')
    text = _strip_hover_title_source(_hover_text(response))
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


@then(parsers.parse('the hover returns the contents of the "{section}" section under the "{parent}" section from the devicetree specification'))
def check_hover_section_under_parent(response, section, parent):
    text = _strip_hover_title_source(_hover_text(response))
    expected = _get_spec_section_under(parent, section)
    if text != expected:
        pytest.fail(
            f'Hover response did not match spec section\n'
            f'  Parent section: {parent}\n'
            f'  Section: {section}\n'
            f'  Expected: {expected[:500]}...\n'
            f'  Got: {text[:500]}...'
        )


@then(parsers.parse('the hover title includes "{source}"'))
def check_hover_title_includes(response, source):
    text = _hover_text(response)
    first_line = text.split('\n', 1)[0]
    if f' - {source}' not in first_line:
        pytest.fail(
            f'Hover title did not include source\n'
            f'  Source: {source}\n'
            f'  Title: {first_line}'
        )


@then(parsers.re(r'the hover text is exactly:\n(?P<expected>.*)', flags=re.DOTALL))
def check_hover_text_exact(response, expected):
    text = _hover_text(response).strip()
    expected = expected.strip()
    if text != expected:
        pytest.fail(
            f'Hover response did not match expected text\n'
            f'  Expected: {expected[:500]}...\n'
            f'  Got: {text[:500]}...'
        )


@then(parsers.parse('the hover returns usage, value type, and definition for "{property}" from the "{table}" table from the devicetree specification'))
def check_hover_table_row(response, property, table):
    text = _strip_hover_title_source(_hover_text(response))
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
    text = _hover_text(response)
    unexpected = _get_spec_section_under(parent, section)
    if text == unexpected:
        pytest.fail(
            f'Hover response unexpectedly matched spec section\n'
            f'  Parent section: {parent}\n'
            f'  Section: {section}\n'
            f'  Got: {text[:500]}...'
        )


@then(parsers.parse('the hover returns value and description for {value} from the "{table}" table from the devicetree specification'))
def check_hover_value_table_row(response, value, table):
    text = _strip_hover_title_source(_hover_text(response))
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
