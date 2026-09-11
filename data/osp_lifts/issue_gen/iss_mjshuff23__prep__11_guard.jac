"""mjshuff23/prep#11 — candidate + hidden guards."""

import from iss_mjshuff23__prep__11 {
    PackGraph,
}

test "linear pack chain" {
    g = PackGraph();
    g.add_pack("graph");
    g.link("graph", "heap");
    g.link("heap", "trie");
    assert g.descendants("graph") == ["heap", "trie"];
    assert g.descendants("heap") == ["trie"];
    assert g.descendants("trie") == [];
    assert g.descendants("missing") == [];
}

test "diamond adversarial edge order" {
    g = PackGraph();
    # insert merge target before hub arms — stresses revisit ordering
    g.link("array", "shared");
    g.link("deque", "shared");
    g.link("wave", "array");
    g.link("wave", "deque");
    assert g.descendants("wave") == ["array", "deque", "shared"];
}

test "cycle claim-map not disengage" {
    g = PackGraph();
    g.link("a", "b");
    g.link("b", "c");
    g.link("c", "a");
    g.link("b", "d");
    assert g.descendants("a") == ["b", "c", "d"];
}

test "idempotent add_pack" {
    g = PackGraph();
    g.add_pack("solo");
    g.add_pack("solo");
    assert g.descendants("solo") == [];
}
