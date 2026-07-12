import pytest

_nodeid_lines: dict[str, int] = {}


@pytest.hookimpl(trylast=True)
def pytest_collection_modifyitems(config, items):
    for item in items:
        _nodeid_lines[item.nodeid] = item.location[1] + 1
