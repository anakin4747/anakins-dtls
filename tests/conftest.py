import pytest

_nodeid_lines: dict[str, int] = {}


@pytest.hookimpl(trylast=True)
def pytest_collection_modifyitems(config, items):
    for item in items:
        _nodeid_lines[item.nodeid] = item.location[1] + 1


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_logreport(report):
    line = _nodeid_lines.get(report.nodeid)
    if line is not None:
        path, _, name = report.nodeid.partition("::")
        report.nodeid = f"{path}:{line}: {name}"
    yield
