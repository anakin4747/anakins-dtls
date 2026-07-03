import os
import sys
import re

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))

from generate_docs import (
    _convert_inline,
    _expand_subst,
    _format_section,
    _handle_bullet_list,
    _handle_code_block,
    _handle_literal_block,
    _handle_note,
    _is_code_block_start,
    _is_label,
    _is_literal_block_marker,
    _is_note_start,
    _is_table_separator,
    _is_table_start,
    _is_tabularcolumns,
    _is_underline,
    _parse_simple_table,
    _resolve_numref,
    build_hover_docs,
    get_section,
    get_table_entry,
    SUBSTITUTIONS,
)

SPEC_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "devicetree-specification",
    "source",
    "chapter2-devicetree-basics.rst",
)


# _convert_inline {{{

def test_convert_inline_unicode_punctuation():
    assert _convert_inline("\u2018foo\u2019") == "'foo'"
    assert _convert_inline("\u201cbar\u201d") == '"bar"'
    assert _convert_inline("\u2013 \u2014") == "- -"

def test_convert_inline_strips_numref():
    result = _convert_inline("see :numref:`some-ref` for details")
    assert result == "see `some-ref` for details"

def test_convert_inline_resolves_chapter_numref():
    result = _convert_inline(
        "see :numref:`Chapter %s <chapter-introduction>` for details"
    )
    assert result == "see Chapter 1 for details"

def test_resolve_numref_with_chapter():
    m = re.match(r"(^|\s):numref:`([^`]+)`", " :numref:`Chapter %s <chapter-devicetree>`")
    assert m
    result = _resolve_numref(m)
    assert result == " Chapter 2"

def test_resolve_numref_with_unknown_label():
    m = re.match(r"(^|\s):numref:`([^`]+)`", " :numref:`unknown-label>`")
    assert m
    result = _resolve_numref(m)
    assert result == " `unknown-label>`"

def test_resolve_numref_preserves_start_of_line():
    m = re.match(r"(^|\s):numref:`([^`]+)`", ":numref:`some-ref`")
    assert m
    result = _resolve_numref(m)
    assert result == "`some-ref`"

def test_convert_inline_resolves_all_chapters():
    for number, label in [
        ("1", "chapter-introduction"),
        ("2", "chapter-devicetree"),
        ("3", "chapter-device-node-requirements"),
        ("4", "chapter-device-bindings"),
        ("5", "chapter-fdt-structure"),
        ("6", "chapter-devicetree-source-format"),
    ]:
        result = _convert_inline(
            f"see :numref:`Chapter %s <{label}>` for details"
        )
        assert result == f"see Chapter {number} for details"

def test_convert_inline_unwraps_abbr():
    result = _convert_inline("the :abbr:`DTS (Devicetree)` spec")
    assert result == "the `DTS (Devicetree)` spec"

def test_convert_inline_inline_literals():
    result = _convert_inline("a ``<string>`` value")
    assert result == "a `<string>` value"

def test_convert_inline_substitutions():
    result = _convert_inline("see |spec| for details")
    assert result == "see DTSpec for details"

    result = _convert_inline("|epapr-fullname|")
    assert result == "Embedded Power Architecture\u2122 Platform Requirements"

def test_convert_inline_collapses_double_spaces():
    result = _convert_inline("a  b   c")
    assert result == "a b c"

def test_convert_inline_combined():
    result = _convert_inline(
        "\u201cthe :numref:`x` ``<string>`` value\u201d"
    )
    assert result == '"the `x` `<string>` value"'

# }}}

# _expand_subst {{{

def test_expand_subst_known():
    m = re.match(r"\|([^|]+)\|", "|spec|")
    assert _expand_subst(m) == SUBSTITUTIONS["|spec|"]

def test_expand_subst_unknown_preserved():
    m = re.match(r"\|([^|]+)\|", "|foo|")
    assert _expand_subst(m) == "|foo|"

# }}}

# _is_underline {{{

def test_is_underline_true():
    assert _is_underline("=====")
    assert _is_underline("~~~~~")
    assert _is_underline("-----")
    assert _is_underline("^^^^^")
    assert _is_underline('""""""')

def test_is_underline_false_too_short():
    assert not _is_underline("==")
    assert not _is_underline("--")

def test_is_underline_false_bad_char():
    assert not _is_underline("====X==")

def test_is_underline_false_empty():
    assert not _is_underline("")

# Block-level detection helpers {{{

def test_is_label():
    assert _is_label(".. _foo:")
    assert not _is_label("foo")

def test_is_label_indented():
    assert _is_label("   .. _foo:")
    assert _is_label("\t.. _bar:")

def test_is_code_block_start():
    assert _is_code_block_start(".. code-block:: dts")
    assert not _is_code_block_start(".. note::")

def test_is_code_block_start_indented():
    assert _is_code_block_start("   .. code-block:: dts")
    assert _is_code_block_start("\t.. code-block:: python")

def test_is_note_start():
    assert _is_note_start(".. note::")
    assert not _is_note_start(".. code-block::")

def test_is_note_start_indented():
    assert _is_note_start("   .. note::")
    assert _is_note_start("  .. note:: This is a note.")

def test_is_table_start():
    assert _is_table_start(".. table::")
    assert not _is_table_start(".. note::")

def test_is_table_start_indented():
    assert _is_table_start("   .. table::")
    assert _is_table_start("\t.. table::")

def test_is_tabularcolumns():
    assert _is_tabularcolumns(".. tabularcolumns::")
    assert _is_tabularcolumns(".. tabularcolumns:: |p|")
    assert not _is_tabularcolumns(".. code-block::")

def test_is_tabularcolumns_indented():
    assert _is_tabularcolumns("   .. tabularcolumns::")
    assert _is_tabularcolumns("\t.. tabularcolumns:: |p|")

def test_is_literal_block_marker():
    assert _is_literal_block_marker("Some text::")
    assert _is_literal_block_marker("::")
    assert not _is_literal_block_marker(".. code-block::")

def test_is_table_separator():
    assert _is_table_separator("=====  =======")
    assert _is_table_separator("-----  -------")
    assert not _is_table_separator("foo  bar")

# }}}

# Block handlers {{{

class TestHandleCodeBlock:
    def test_with_language(self):
        lines = [
            ".. code-block:: python",
            "",
            "   def foo():",
            "       pass",
            "",
            "other",
        ]
        md, i = _handle_code_block(lines, 0)
        assert md == "```python\ndef foo():\n    pass\n\n```\n"
        assert i == 5

    def test_no_blank_line_before(self):
        lines = [
            ".. code-block:: dts",
            "   /dts-v1/;",
        ]
        md, i = _handle_code_block(lines, 0)
        assert "```dts" in md
        assert "/dts-v1/" in md
        assert i == 2

    def test_indented_directive(self):
        lines = [
            "   .. code-block:: dts",
            "",
            "      pic@10000000 {",
            "         phandle = <1>;",
            "      };",
            "",
            "other",
        ]
        md, i = _handle_code_block(lines, 0)
        assert md == "```dts\npic@10000000 {\n   phandle = <1>;\n};\n\n```\n"
        assert i == 6

    def test_indented_directive_no_blank_line(self):
        lines = [
            "   .. code-block:: dts",
            "      /dts-v1/;",
        ]
        md, i = _handle_code_block(lines, 0)
        assert "```dts" in md
        assert "/dts-v1/" in md
        assert i == 2


class TestHandleNote:
    def test_inline_note(self):
        lines = [".. note:: This is a note."]
        md, i = _handle_note(lines, 0)
        assert md == "> **Note:** This is a note.\n"
        assert i == 1

    def test_block_note(self):
        lines = [
            ".. note::",
            "",
            "   First paragraph.",
            "",
            "   Second paragraph.",
        ]
        md, i = _handle_note(lines, 0)
        assert "> **Note:**" in md
        assert "> First paragraph." in md
        assert "> Second paragraph." in md
        assert i == 5

    def test_indented_inline_note(self):
        lines = ["   .. note:: This is a note."]
        md, i = _handle_note(lines, 0)
        assert md == "> **Note:** This is a note.\n"
        assert i == 1

    def test_indented_block_note(self):
        lines = [
            "   .. note::",
            "",
            "      First paragraph.",
            "",
            "      Second paragraph.",
        ]
        md, i = _handle_note(lines, 0)
        assert "> **Note:**" in md
        assert "> First paragraph." in md
        assert "> Second paragraph." in md
        assert i == 5

    def test_inline_note_converts_numref(self):
        lines = [".. note:: see :numref:`Chapter %s <ch>` for details"]
        md, i = _handle_note(lines, 0)
        assert "see `Chapter %s <ch>`" in md
        assert ":numref:" not in md
        assert i == 1

    def test_inline_note_with_continuation(self):
        lines = [
            ".. note:: Most devicetrees in :abbr:`DTS (Device Tree Syntax)` (see",
            "   :numref:`Chapter %s <chapter-devicetree-source-format>`) will not"
            " contain",
            "   explicit phandle properties.",
        ]
        md, i = _handle_note(lines, 0)
        assert "`DTS (Device Tree Syntax)`" in md
        assert "Chapter 6" in md
        assert ":abbr:" not in md
        assert ":numref:" not in md
        assert i == 3

    def test_block_note_converts_inline_markup(self):
        lines = [
            ".. note::",
            "",
            "   Most devicetrees in :abbr:`DTS (Device Tree Syntax)` (see",
            "   :numref:`Chapter %s <chapter-devicetree-source-format>`) will not"
            " contain",
            "   explicit phandle properties.",
        ]
        md, i = _handle_note(lines, 0)
        assert "`DTS (Device Tree Syntax)`" in md
        assert "Chapter 6" in md
        assert ":abbr:" not in md
        assert ":numref:" not in md
        assert i == 5


class TestHandleLiteralBlock:
    def test_basic(self):
        lines = [
            "::",
            "",
            "   literal line 1",
            "   literal line 2",
        ]
        md, i = _handle_literal_block(lines, 0)
        assert md == "```\nliteral line 1\nliteral line 2\n```\n"
        assert i == 4


class TestHandleBulletList:
    def test_simple(self):
        lines = [
            "* first item",
            "* second item",
            "",
            "trailing",
        ]
        md, i = _handle_bullet_list(lines, 0)
        assert md == "* first item\n* second item\n"
        assert i == 2

    def test_inline_conversion_applied(self):
        lines = [
            "* ``<string>`` value",
        ]
        md, _ = _handle_bullet_list(lines, 0)
        assert "`<string>`" in md


class TestParseSimpleTable:
    def test_two_cells(self):
        lines = [
            "  =====  =======",
            "  Prop   Value",
            "  =====  =======",
            "  foo    1",
            "  bar    2",
            "  =====  =======",
        ]
        md, i = _parse_simple_table(lines, 0)
        rows = md.strip().split("\n")
        assert rows[0] == "| Prop | Value |"
        assert rows[1] == "|------|-------|"
        assert rows[2] == "| foo  | 1     |"
        assert rows[3] == "| bar  | 2     |"
        assert i == 6

    def test_wraps_long_cell_text(self):
        lines = [
            "  =====  ========================",
            "  Prop   Description",
            "  =====  ========================",
            "  val    The quick brown fox jumps"
            " over the lazy dog near the riverbank.",
            "  =====  ========================",
        ]
        md, i = _parse_simple_table(lines, 0)
        rows = md.strip().split("\n")
        assert rows[0] == "| Prop | Description                                          |"
        assert rows[1] == "|------|------------------------------------------------------|"
        assert rows[2] == "| val  | The quick brown fox jumps over the lazy dog near the |"
        assert rows[3] == "|      | riverbank.                                           |"
        assert i == 5

# }}}

# _format_section {{{

def test_format_section_labels_are_bolded():
    raw = (
        "model\n"
        "=====\n"
        "\n"
        "Property name: ``model``\n"
        "\n"
        "Value type: ``<string>``\n"
    )
    result = _format_section(raw)
    assert "**Property name:**" in result
    assert "**Value type:**" in result
    assert "`model`" in result

def test_format_section_includes_heading_title():
    raw = (
        "model\n"
        "=====\n"
        "\n"
        "Property name: ``model``\n"
    )
    result = _format_section(raw)
    assert result.startswith("# model")
    assert "**Property name:**" in result

def test_format_section_joins_wrapped_paragraph():
    raw = (
        "model\n"
        "=====\n"
        "\n"
        "Description:\n"
        "  The model property value is a ``<string>`` that specifies\n"
        "  the manufacturer\u2019s model number of the device.\n"
    )
    result = _format_section(raw)
    assert "manufacturer's model number" in result
    assert "`<string>`" in result

def test_format_section_code_block():
    raw = (
        "Example:\n"
        "\n"
        ".. code-block:: dts\n"
        "\n"
        "   model = \"acme\"\n"
    )
    result = _format_section(raw)
    assert "```dts" in result
    assert 'model = "acme"' in result

def test_format_section_code_block_indented():
    raw = (
        "Example:\n"
        "\n"
        "   .. code-block:: dts\n"
        "\n"
        "      /dts-v1/;\n"
        "      / {\n"
        '          model = "acme";\n'
        "      };\n"
    )
    result = _format_section(raw)
    assert "```dts" in result
    assert "/dts-v1/" in result
    assert 'model = "acme"' in result
    assert "```" in result
    assert ".. code-block::" not in result

def test_format_section_note():
    raw = (
        "Description:\n"
        "\n"
        ".. note::\n"
        "\n"
        "   This property is deprecated.\n"
    )
    result = _format_section(raw)
    assert "**Note:**" in result
    assert "deprecated" in result

def test_format_section_bullet_list():
    raw = (
        "Description:\n"
        "\n"
        "* first\n"
        "* second\n"
    )
    result = _format_section(raw)
    assert "- first" in result
    assert "- second" in result

def test_format_section_skips_labels_and_tabularcolumns():
    raw = (
        ".. _dma-ranges:\n"
        "\n"
        ".. tabularcolumns:: |p|\n"
        "\n"
        "Property name: ``dma-ranges``\n"
    )
    result = _format_section(raw)
    assert "**Property name:**" in result
    assert ".. _" not in result
    assert "tabularcolumns" not in result

def test_format_section_preserves_blank_lines_between_labels():
    raw = (
        "foo\n"
        "===\n"
        "\n"
        "Property name: ``foo``\n"
        "\n"
        "Value type: ``<u32>``\n"
        "\n"
        "Description: some text\n"
    )
    result = _format_section(raw)
    lines = result.strip().split("\n")
    assert lines[0] == "# foo"
    assert lines[1] == ""
    assert lines[2] == "**Property name:** `foo`"
    assert lines[3] == ""
    assert lines[4] == "**Value type:** `<u32>`"
    assert lines[3] == ""
    assert "`some text`" not in result  # no backtick conversion

def test_format_section_empty_returns_empty_line():
    result = _format_section("")
    assert result == "\n"

def test_format_section_just_a_heading():
    raw = "Foo\n===\n"
    result = _format_section(raw)
    assert result == "# Foo\n"

# }}}

# build_hover_docs {{{

def test_build_hover_docs_all_keys_present():
    docs = build_hover_docs()
    expected = {
        "compatible", "model", "phandle", "status",
        "#address-cells", "#size-cells", "reg", "virtual-reg",
        "ranges", "dma-ranges", "dma-coherent", "dma-noncoherent",
        "name", "device_type", "__root__", "serial-number", "chassis-type",
    }
    assert set(docs.keys()) == expected

def test_build_hover_docs_all_non_empty():
    docs = build_hover_docs()
    for key, value in docs.items():
        assert value, f"{key} produced empty documentation"

def test_build_hover_docs_address_and_size_cells_identical():
    docs = build_hover_docs()
    assert docs["#address-cells"] == docs["#size-cells"]

def test_build_hover_docs_root_node_properties_from_table():
    docs = build_hover_docs()

    assert docs["serial-number"] == get_table_entry(
        "Root Node Properties",
        "serial-number",
        "Definition",
    )
    assert docs["chassis-type"] == get_table_entry(
        "Root Node Properties",
        "chassis-type",
        "Definition",
    )

def test_build_hover_docs_each_begins_with_heading():
    docs = build_hover_docs()
    for key, value in docs.items():
        if key in {"serial-number", "chassis-type"}:
            continue
        assert value.startswith("#"), f"{key} does not start with a heading"
        if key == "__root__":
            continue
        assert "**Property name:**" in value, f"{key} missing Property name"

def test_build_hover_docs_no_raw_rst_directives():
    docs = build_hover_docs()
    for key, value in docs.items():
        assert ".. code-block::" not in value, (
            f"{key} contains unconverted RST code-block directive"
        )

def test_build_hover_docs_dma_ranges_bullets_keep_wrapped_text_together():
    docs = build_hover_docs()
    doc = docs["dma-ranges"]

    assert "*child-bus-address-" not in doc
    assert "*parent-bus-address-" not in doc
    assert "*length-" not in doc
    assert "dma-rang\nes" not in doc
    assert "#size-cel\nls" not in doc
    assert (
        "- The *child-bus-address* is a physical address within the child bus' "
        "address space."
    ) in doc
    assert (
        "- The *parent-bus-address* is a physical address within the parent "
        "bus' address space."
    ) in doc
    assert (
        "- The *length* specifies the size of the range in the child's address "
        "space."
    ) in doc

# }}}

# get_section tests {{{

def test_get_section_compatible():
    with open(SPEC_PATH) as f:
        content = f.read()
    idx = content.index("compatible\n~~~~~~~~~~")
    end = content.index("model\n~~~~~")
    expected = content[idx:end]

    section = get_section("compatible")

    assert section == expected

def test_get_section_properties_includes_sub_sections():
    with open(SPEC_PATH) as f:
        content = f.read()
    idx = content.index("Properties\n~~~~~~~~~~")
    end = content.index("Standard Properties\n-------------------")
    expected = content[idx:end]

    section = get_section("Properties")

    assert section == expected
    assert "Property Names\n^^^^^^^^^^^^^^" in section
    assert "Property Values\n^^^^^^^^^^^^^^^" in section

# }}}

# get_table_entry tests {{{

def test_get_table_entry_root_node_serial_number_definition():
    entry = get_table_entry(
        "Root Node Properties",
        "serial-number",
        "Definition",
    )

    assert entry == "Specifies a string representing the device's serial number."

# }}}
