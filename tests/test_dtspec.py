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
        lines = f.readlines()
    expected = "".join(lines[479:514])

    section = get_section("compatible")

    assert section == expected


def test_get_section_compatible_starts_with_heading():
    section = get_section("compatible")
    assert section.startswith("compatible\n~~~~~~~~~~")


def test_get_section_compatible_is_text_before_model_heading():
    with open(SPEC_PATH) as f:
        content = f.read()
    idx = content.index("compatible\n~~~~~~~~~~")
    end = content.index("model\n~~~~~")
    expected = content[idx:end]

    assert get_section("compatible") == expected
