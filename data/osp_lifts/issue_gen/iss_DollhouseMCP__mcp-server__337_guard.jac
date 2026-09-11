"""Memory relationships lifted to OSP.

Memories become Memory nodes; every relationship record becomes one Rel
edge archetype carrying its kind and strength payload (the link list is
homogeneous apart from the kind string, so a single payload edge beats
six edge types -- documented design choice), inserted in BOTH directions
because the store's relationships are navigable either way. The deque
BFS over the adjacency dict becomes a shortest-chain relaxation walker
whose claim map doubles as the cycle guard, and whose hop budget is the
multi-hop reasoning bound. ``contradiction_pairs`` stays a link filter:
in the source it never traverses, it canonicalizes contradicts records.
Ref: DollhouseMCP/mcp-server#337
"""
node Memory {
    has mid: str;
}
edge Rel {
    has kind: str;
    has strength: float;
}

"""Loader handle: memory ids resolve through this lookup map."""
obj MemStore {
    has mems: dict[str, Memory];

    def resolve(mid: str) -> Memory | None {
        return self.mems.get(mid);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_store(store: dict) -> MemStore {
    ms = MemStore(mems={});
    for m in list(store["memories"]) {
        n = Memory(mid=str(m));
        root ++> n;
        ms.mems[str(m)] = n;
    }
    for link in list(store["links"]) {
        frm = ms.resolve(str(link[0]));
        to = ms.resolve(str(link[1]));
        if frm is None or to is None {
            continue;  # unknown memory ids in links are skipped
        }
        kind = str(link[2]);
        strength = float(str(link[3]));
        frm +>:Rel(kind=kind, strength=strength):+> to;
        to +>:Rel(kind=kind, strength=strength):+> frm;
    }
    return ms;
}

walker NearWalk {
    # Cycle policy: claim map keyed by memory id (jac walkers do not
    # dedupe). A non-improving revisit skips; a strictly shallower arrival
    # re-expands, so the map ends holding each memory's shortest link
    # distance -- the multi-hop neighborhood within the hop budget, with
    # link loops terminating on the claim map.
    has best: dict[str, int] = {};
    has hops: int = 0;
    has budget: int = 2;

    can step with Memory entry {
        if here.mid in self.best and self.hops >= self.best[here.mid] {
            skip;
        }
        self.best[here.mid] = self.hops;
        if self.hops < self.budget {
            for nbr in [here->:Rel:->] {
                nbr spawn NearWalk(best=self.best, hops=self.hops + 1, budget=self.budget);
            }
        }
    }
}

"""Memory ids within ``hops`` links of ``mid`` (itself excluded), sorted."""
def related_within(store: dict, mid: str, hops: int = 2) -> list[str] {
    ms = load_store(store);
    start = ms.resolve(mid);
    if start is None {
        raise KeyError(mid);
    }
    w = start spawn NearWalk(best={}, hops=0, budget=hops);
    out: list[str] = [];
    for k in w.best.keys() {
        if k != mid and w.best[k] <= hops {
            out.append(k);
        }
    }
    return sorted(out);
}

"""Canonical contradictory pairs ``[[a, b], ...]`` with a < b, sorted."""
def contradiction_pairs(store: dict) -> list {
    # a filter over the link records, not a traversal: no walk in the
    # source, none here
    pairs: set[str] = set();
    mems: set[str] = set();
    for m in list(store["memories"]) {
        mems.add(str(m));
    }
    for link in list(store["links"]) {
        if str(link[2]) != "contradicts" {
            continue;
        }
        frm = str(link[0]);
        to = str(link[1]);
        if frm not in mems or to not in mems {
            continue;
        }
        if frm < to {
            pairs.add(frm + "|" + to);
        } else {
            pairs.add(to + "|" + frm);
        }
    }
    out: list = [];
    for p in sorted(pairs) {
        out.append(p.split("|"));
    }
    return out;
}


test "multi-hop neighborhoods at several budgets" {
    S = {
        "memories": ["m1", "m2", "m3", "m4", "m5", "m6"],
        "links": [
            ("m1", "m2", "builds_on", 0.9),
            ("m2", "m3", "caused_by", 0.7),
            ("m3", "m4", "references", 0.5),
            ("m1", "m5", "similar_to", 0.8),
            ("m5", "m6", "contradicts", 0.6),
            ("m2", "m3", "references", 0.4),
        ],
    };
    assert related_within(S, "m1", hops=1) == ["m2", "m5"];
    assert related_within(S, "m1", hops=2) == ["m2", "m3", "m5", "m6"];
    assert related_within(S, "m1", hops=3) == ["m2", "m3", "m4", "m5", "m6"];
    assert related_within(S, "m1", hops=4) == ["m2", "m3", "m4", "m5", "m6"];
    assert related_within(S, "m6", hops=2) == ["m1", "m5"];
    assert related_within(S, "m4", hops=1) == ["m3"];
    assert related_within(S, "m1") == ["m2", "m3", "m5", "m6"];
}

test "adversarial-order diamond counts the short chain" {
    D = {
        "memories": ["a", "b", "c", "d"],
        "links": [
            ("a", "b", "references", 0.9),
            ("b", "c", "references", 0.9),
            ("c", "d", "references", 0.9),
            ("a", "d", "similar_to", 0.5),
        ],
    };
    assert related_within(D, "a", hops=1) == ["b", "d"];
    assert related_within(D, "a", hops=2) == ["b", "c", "d"];
}

test "link cycles terminate" {
    C = {
        "memories": ["p", "q", "r"],
        "links": [
            ("p", "q", "references", 0.9),
            ("q", "r", "references", 0.9),
            ("r", "p", "part_of", 0.9),
        ],
    };
    assert related_within(C, "p", hops=2) == ["q", "r"];
}

test "lone memory and unknown start" {
    assert related_within({"memories": ["solo"], "links": []}, "solo", hops=3) == [];
    S = {"memories": ["m1"], "links": []};
    try {
        related_within(S, "ghost", hops=1);
        assert False, "expected KeyError";
    } except KeyError { assert True; }
}

test "unknown ids in links are skipped" {
    U = {
        "memories": ["a", "b"],
        "links": [
            ("a", "ghost", "references", 0.9),
            ("a", "b", "contradicts", 0.6),
            ("ghost", "b", "contradicts", 0.6),
        ],
    };
    assert related_within(U, "a", hops=2) == ["b"];
    assert contradiction_pairs(U) == [["a", "b"]];
}

test "contradiction pairs canonical, deduped, sorted" {
    S = {
        "memories": ["m1", "m2", "m3", "m4", "m5", "m6"],
        "links": [
            ("m1", "m2", "builds_on", 0.9),
            ("m5", "m6", "contradicts", 0.6),
        ],
    };
    assert contradiction_pairs(S) == [["m5", "m6"]];
    B = {
        "memories": ["x", "y", "z", "w"],
        "links": [
            ("z", "x", "contradicts", 0.9),
            ("x", "z", "contradicts", 0.4),
            ("y", "w", "contradicts", 0.7),
            ("y", "x", "builds_on", 0.9),
        ],
    };
    assert contradiction_pairs(B) == [["w", "y"], ["x", "z"]];
    assert contradiction_pairs({"memories": ["a"], "links": []}) == [];
}
