"""Reference harness for rec_40_cfgprop (config propagation). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_40_cfgprop import ConfigTree


def build():
    t = ConfigTree()
    t.add_zone("region")
    t.add_zone("clusterA", parent="region")
    t.add_zone("node1", parent="clusterA")
    t.add_zone("node2", parent="clusterA")
    t.add_zone("clusterB", parent="region")
    return t


def test_structure_and_chain_order():
    t = build()
    assert sorted(t.zones) == ["clusterA", "clusterB", "node1", "node2", "region"]
    assert t.chain("node1") == ["node1", "clusterA", "region"]
    try:
        t.add_zone("region")
        raise AssertionError("expected duplicate error")
    except ValueError:
        pass
    try:
        t.add_zone("x", parent="ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass


def test_nearest_override_wins():
    t = build()
    t.set_override("region", "timeout", 30)
    t.set_override("clusterA", "timeout", 10)
    t.set_override("node2", "retries", 5)
    # nearest zone on the chain defines the value
    assert t.effective("node1", "timeout") == 10
    assert t.effective("node2", "timeout") == 10
    assert t.effective("clusterB", "timeout") == 30
    assert t.effective("node2", "retries") == 5
    assert t.effective("clusterB", "retries") is None


def test_views_and_counts():
    t = build()
    t.set_override("region", "timeout", 30)
    t.set_override("clusterA", "timeout", 10)
    t.set_override("node2", "retries", 5)
    assert t.effective_view("node1") == {"retries": None} or \
           t.effective_view("node1").get("timeout") == 10
    view = t.effective_view("node2")
    assert view["timeout"] == 10 and view["retries"] == 5
    assert t.override_count("region") == 3
    assert t.override_count("clusterA") == 2
    assert t.override_count("clusterB") == 0
    assert t.coherent()


def test_clear_and_invalidation():
    t = build()
    t.set_override("region", "timeout", 30)
    t.set_override("clusterA", "timeout", 10)
    assert t.effective_view("node1")["timeout"] == 10
    # clearing the nearer override falls through to the farther one
    assert t.clear_override("clusterA", "timeout")
    assert not t.clear_override("clusterA", "timeout")   # idempotent
    assert t.effective("node1", "timeout") == 30
    assert t.effective_view("node1")["timeout"] == 30
    assert t.override_count("clusterA") == 0
    assert t.override_count("region") == 1
    assert t.coherent()


test_structure_and_chain_order()
test_nearest_override_wins()
test_views_and_counts()
test_clear_and_invalidation()
print("rec_40 ref OK")
sys.exit(0)
