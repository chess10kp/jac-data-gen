"""Reference harness for rec_37_plugres (plugin resolver). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_37_plugres import PluginRegistry


def build():
    r = PluginRegistry()
    r.add_group("tools")
    r.add_group("linters", parent="tools")
    r.add_group("themes", parent="tools")
    r.add_plugin("core", "tools")
    r.add_plugin("pylint", "linters")
    r.add_plugin("flake8", "linters")
    r.add_plugin("dark", "themes")
    r.require("pylint", "core")
    r.require("flake8", "core")
    return r


def test_structure():
    r = build()
    assert sorted(r.groups) == ["linters", "themes", "tools"]
    assert sorted(r.plugins) == ["core", "dark", "flake8", "pylint"]
    assert r.group_load("tools") == 4
    assert r.group_load("linters") == 2
    try:
        r.add_group("tools")
        raise AssertionError("expected duplicate group error")
    except ValueError:
        pass
    try:
        r.add_plugin("x", "ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass
    try:
        r.require("core", "core")
        raise AssertionError("expected self dependency error")
    except ValueError:
        pass


def test_dependents_and_cascade():
    r = build()
    assert r.dependents_of("core") == ["flake8", "pylint"]
    removed = r.uninstall("core")
    # cascade removes hard dependents transitively
    assert removed == ["core", "flake8", "pylint"]
    assert "core" not in r.plugins and "dark" in r.plugins
    assert r.group_load("tools") == 1
    assert r.group_load("linters") == 0
    assert r.dependents_of("core") == []


def test_pinned_pruning():
    r = build()
    r.add_plugin("meta", "tools")
    r.add_plugin("helper", "tools")
    r.require("meta", "pylint")     # meta -> pylint -> core
    r.require("helper", "meta")
    r.plugins["pylint"].pinned = True
    removed = r.uninstall("core")
    # pylint is pinned: its branch (meta, helper) is spared; flake8 still goes
    assert removed == ["core", "flake8"]
    assert "pylint" in r.plugins and "meta" in r.plugins and "helper" in r.plugins
    assert r.dependents_of("core") == []  # bookkeeping cleaned


def test_force_overrides_pins():
    r = build()
    r.plugins["pylint"].pinned = True
    removed = r.uninstall("core", force=True)
    assert removed == ["core", "flake8", "pylint"]
    # uninstalling a pinned root directly refuses without force
    r2 = build()
    r2.plugins["dark"].pinned = True
    assert r2.uninstall("dark") == []
    assert r2.uninstall("dark", force=True) == ["dark"]


def test_unknown():
    r = build()
    try:
        r.uninstall("ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


test_structure()
test_dependents_and_cascade()
test_pinned_pruning()
test_force_overrides_pins()
test_unknown()
print("rec_37 ref OK")
sys.exit(0)
