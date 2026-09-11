"""Reference harness for rec_35_cloudres (cloud resources). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_35_cloudres import CloudManager


def build():
    m = CloudManager()
    m.add_resource("stack", cost=0)          # root stack
    m.add_resource("net", parent="stack", cost=10)
    m.add_resource("db", parent="stack", cost=30)
    m.add_resource("replica", parent="db", cost=20)
    m.add_resource("app", parent="stack", cost=15)
    return m


def test_structure_and_aggregation():
    m = build()
    assert sorted(m.resources) == ["app", "db", "net", "replica", "stack"]
    assert m.aggregate("stack") == 75
    assert m.aggregate("db") == 50
    assert m.ancestors("replica") == ["db", "stack"]
    try:
        m.add_resource("net", cost=1)
        raise AssertionError("expected duplicate error")
    except ValueError:
        pass
    try:
        m.add_resource("x", parent="ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


def test_dependency_closure():
    m = build()
    m.attach_dependency("app", "db")
    m.attach_dependency("app", "net")
    m.attach_dependency("db", "net")
    assert m.dependency_closure("app") == ["db", "net"]
    try:
        m.attach_dependency("net", "net")
        raise AssertionError("expected self dependency error")
    except ValueError:
        pass


def test_delete_cascade_and_recompute():
    m = build()
    doomed = m.delete("db")
    assert doomed == ["db", "replica"]
    # ancestor-aware recomputation
    assert m.aggregate("stack") == 25
    assert "db" not in m.resources and "replica" not in m.resources
    assert m.ancestors("app") == ["stack"]


def test_delete_blocked_by_external_dependency():
    m = build()
    m.attach_dependency("app", "replica")   # survivor depends into subtree
    try:
        m.delete("db")
        raise AssertionError("expected in-use error")
    except ValueError:
        pass
    # refusals are non-mutating: graph and aggregates unchanged
    m.attach_dependency("replica", "net")
    try:
        m.delete("db")
        raise AssertionError("expected in-use error again")
    except ValueError:
        pass
    assert m.aggregate("stack") == 75
    assert sorted(m.resources) == ["app", "db", "net", "replica", "stack"]


def test_delete_unknown():
    m = build()
    try:
        m.delete("ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


test_structure_and_aggregation()
test_dependency_closure()
test_delete_cascade_and_recompute()
test_delete_blocked_by_external_dependency()
test_delete_unknown()
print("rec_35 ref OK")
sys.exit(0)
