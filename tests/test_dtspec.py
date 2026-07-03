import os

from anakins_dtls.dtspec import get_section

SPEC_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "devicetree-specification",
    "source",
    "chapter2-devicetree-basics.rst",
)


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
    pass # waiting on -> def get_subsection(section, depth = 1):

