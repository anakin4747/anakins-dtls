import os

from anakins_dtls.dtspec import (
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
    build_hover_docs,
    get_section,
)

SPEC_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "devicetree-specification",
    "source",
    "chapter2-devicetree-basics.rst",
)


# ---------------------------------------------------------------------------
# _convert_inline
# ---------------------------------------------------------------------------

def test_convert_inline_unicode_punctuation():
    assert _convert_inline("\u2018foo\u2019") == "'foo'"
    assert _convert_inline("\u201cbar\u201d") == '"bar"'
    assert _convert_inline("\u2013 \u2014") == "- -"

def test_convert_inline_strips_numref():
    result = _convert_inline("see :numref:`some-ref` for details")
    assert result == "see `some-ref` for details"

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


# ---------------------------------------------------------------------------
# _expand_subst
# ---------------------------------------------------------------------------

def test_expand_subst_known():
    from anakins_dtls.dtspec import SUBSTITUTIONS
    import re
    m = re.match(r"\|([^|]+)\|", "|spec|")
    assert _expand_subst(m) == SUBSTITUTIONS["|spec|"]

def test_expand_subst_unknown_preserved():
    import re
    m = re.match(r"\|([^|]+)\|", "|foo|")
    assert _expand_subst(m) == "|foo|"


# ---------------------------------------------------------------------------
# _is_underline
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Block-level detection helpers
# ---------------------------------------------------------------------------

def test_is_label():
    assert _is_label(".. _foo:")
    assert not _is_label("foo")

def test_is_code_block_start():
    assert _is_code_block_start(".. code-block:: dts")
    assert not _is_code_block_start(".. note::")

def test_is_note_start():
    assert _is_note_start(".. note::")
    assert not _is_note_start(".. code-block::")

def test_is_table_start():
    assert _is_table_start(".. table::")
    assert not _is_table_start(".. note::")

def test_is_tabularcolumns():
    assert _is_tabularcolumns(".. tabularcolumns::")
    assert _is_tabularcolumns(".. tabularcolumns:: |p|")
    assert not _is_tabularcolumns(".. code-block::")

def test_is_literal_block_marker():
    assert _is_literal_block_marker("Some text::")
    assert _is_literal_block_marker("::")
    assert not _is_literal_block_marker(".. code-block::")

def test_is_table_separator():
    assert _is_table_separator("=====  =======")
    assert _is_table_separator("-----  -------")
    assert not _is_table_separator("foo  bar")


# ---------------------------------------------------------------------------
# Block handlers
# ---------------------------------------------------------------------------

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

    def test_with_prefix(self):
        prefix_line = "Here is some code::"
        lines = [prefix_line, "", "   code"]
        md = _handle_literal_block(lines, 1)
        # invoke from after prefix


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
        md, i = _handle_bullet_list(lines, 0)
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
        assert rows[2] == "| foo | 1 |"
        assert i == 6


# ---------------------------------------------------------------------------
# _format_section
# ---------------------------------------------------------------------------

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

def test_format_section_skips_heading_title():
    raw = (
        "model\n"
        "=====\n"
        "\n"
        "Property name: ``model``\n"
    )
    result = _format_section(raw)
    assert "**Property name:**" in result
    assert result.startswith("**Property name:**")

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
    assert lines[0] == "**Property name:** `foo`"
    assert lines[1] == ""
    assert lines[2] == "**Value type:** `<u32>`"
    assert lines[3] == ""
    assert "`some text`" not in result  # no backtick conversion

def test_format_section_empty_returns_empty_line():
    result = _format_section("")
    assert result == "\n"

def test_format_section_just_a_heading():
    raw = "Foo\n===\n"
    result = _format_section(raw)
    assert result == "\n"


# ---------------------------------------------------------------------------
# build_hover_docs
# ---------------------------------------------------------------------------

def test_build_hover_docs_all_keys_present():
    docs = build_hover_docs()
    expected = {
        "compatible", "model", "phandle", "status",
        "#address-cells", "#size-cells", "reg", "virtual-reg",
        "ranges", "dma-ranges", "dma-coherent", "dma-noncoherent",
        "name", "device_type",
    }
    assert set(docs.keys()) == expected

def test_build_hover_docs_all_non_empty():
    docs = build_hover_docs()
    for key, value in docs.items():
        assert value, f"{key} produced empty documentation"

def test_build_hover_docs_address_and_size_cells_identical():
    docs = build_hover_docs()
    assert docs["#address-cells"] == docs["#size-cells"]

def test_build_hover_docs_each_begins_with_property_name():
    docs = build_hover_docs()
    for key, value in docs.items():
        assert value.startswith("**Property name:**"), f"{key} does not start with Property name"


# ---------------------------------------------------------------------------
# Existing get_section tests
# ---------------------------------------------------------------------------

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

def test_get_subsection():
    pass

