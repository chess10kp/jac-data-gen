import from iss_entif-ai__rosetta__676 { DocRegistry }

def _lineage() -> DocRegistry {
    r = DocRegistry();
    for d in ["TXS-001", "TXS-000", "TXS-LEGACY"] {
        r.register(d);
    }
    r.supersedes("TXS-001", "TXS-000");
    r.supersedes("TXS-000", "TXS-LEGACY");
    return r;
}

def _diamond() -> DocRegistry {
    r = DocRegistry();
    for d in ["n", "l", "r", "m"] {
        r.register(d);
    }
    r.supersedes("n", "l");
    r.supersedes("n", "r");
    r.supersedes("l", "m");
    r.supersedes("r", "m");
    return r;
}

test "lineage closure" {
    r = _lineage();
    assert r.find_cycle() == [];
    assert r.lineage("TXS-001") == ["TXS-000", "TXS-001", "TXS-LEGACY"];
}

test "diamond adversarial lineage" {
    r = _diamond();
    assert r.lineage("n") == ["l", "m", "n", "r"];
}

test "cycle multiset" {
    r = DocRegistry();
    for d in ["a", "b", "c"] {
        r.register(d);
    }
    r.supersedes("a", "b");
    r.supersedes("b", "c");
    r.supersedes("c", "a");
    assert sorted(set(r.find_cycle())) == ["a", "b", "c"];
}
