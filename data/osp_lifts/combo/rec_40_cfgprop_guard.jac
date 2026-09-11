"""Guard suite for rec_40_cfgprop."""
import from rec_40_cfgprop { ConfigTree }

def fresh() -> ConfigTree {
    t = ConfigTree();
    t.add_zone("region");
    t.add_zone("clusterA", parent="region");
    t.add_zone("node1", parent="clusterA");
    t.add_zone("node2", parent="clusterA");
    t.add_zone("clusterB", parent="region");
    return t;
}

test "structure and observable chain order" {
    t = fresh();
    assert sorted([t.by_zid[z].zid for z in t.by_zid]) == ["clusterA", "clusterB", "node1", "node2", "region"];
    assert t.chain("node1") == ["node1", "clusterA", "region"];
    threw_dup = False;
    try {
        t.add_zone("region");
    } except ValueError as ex {
        threw_dup = True;
    }
    assert threw_dup;
    threw_missing = False;
    try {
        t.add_zone("x", parent="ghost");
    } except KeyError as ex {
        threw_missing = True;
    }
    assert threw_missing;
}

test "nearest override wins along the chain" {
    t = fresh();
    t.set_override("region", "timeout", 30);
    t.set_override("clusterA", "timeout", 10);
    t.set_override("node2", "retries", 5);
    assert t.effective("node1", "timeout") == 10;
    assert t.effective("node2", "timeout") == 10;
    assert t.effective("clusterB", "timeout") == 30;
    assert t.effective("node2", "retries") == 5;
    assert t.effective("clusterB", "retries") is None;
}

test "views materialize and counts aggregate" {
    t = fresh();
    t.set_override("region", "timeout", 30);
    t.set_override("clusterA", "timeout", 10);
    t.set_override("node2", "retries", 5);
    view = t.materialize_view("node2");
    assert view["timeout"] == 10 and view["retries"] == 5;
    # node1 never sees node2-scoped retries
    v1 = t.materialize_view("node1");
    assert v1["timeout"] == 10 and "retries" not in v1.keys();
    assert t.override_count("region") == 3;
    assert t.override_count("clusterA") == 2;
    assert t.override_count("clusterB") == 0;
    assert t.coherent();
}

test "clear invalidates caches and falls through" {
    t = fresh();
    t.set_override("region", "timeout", 30);
    t.set_override("clusterA", "timeout", 10);
    t.materialize_view("node1");
    assert t.clear_override("clusterA", "timeout");
    assert not t.clear_override("clusterA", "timeout");  # idempotent
    assert t.effective("node1", "timeout") == 30;
    t.materialize_view("node1");  # re-materialize after invalidation
    assert t.coherent();
    assert t.effective_view("node1")["timeout"] == 30;
    assert t.override_count("clusterA") == 0;
    assert t.override_count("region") == 1;
}

test "rewrite updates value in place without duplicating records" {
    t = fresh();
    t.set_override("node1", "retries", 3);
    before = t.subtree_overrides("node1");
    t.set_override("node1", "retries", 7);
    assert t.subtree_overrides("node1") == before;
    assert t.effective("node1", "retries") == 7;
    assert t.coherent();
}
