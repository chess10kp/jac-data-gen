"""Bidirectional lineage impact lifted to OSP (zer0pool/graph-viz#139).

The two adjacency dicts die: ``src feeds dst`` becomes one typed ``Feeds``
edge and reachability becomes an ``ImpactWalk`` over it. The source's depth
cap survives as the walker's hop budget, carried down through per-branch
sub-spawns; the revisit policy is the explicit claim-map (skip on a
revisit, never disengage-on) since jac 0.36.1 has no built-in once-only
visitation. All mutable state lives on a per-instance ``LineageGraph``
handle -- every test constructs a fresh instance, no module-level globals.
"""

node Asset {
    has aid: str;
    has kind: str;
}

edge Feeds: Asset --> Asset {}


walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has budget: int = -1;
    has reverse: bool = False;

    can step with Asset entry {
        if here.aid in self.claimed {
            return;  # diamond/cycle revisit: skip silently
        }
        self.claimed[here.aid] = True;
        self.found.append(here.aid);
        if self.budget == 0 {
            return;  # depth cap: include but do not expand
        }
        next_budget = self.budget - 1;
        if self.budget < 0 {
            next_budget = -1;
        }
        if self.reverse {
            for nb in [here <-:Feeds:<-] {
                sub = ImpactWalk(claimed=self.claimed, budget=next_budget,
                                 reverse=True);
                nb spawn sub;
                self.found.extend(sub.found);
            }
        } else {
            for nb in [here ->:Feeds:->] {
                sub = ImpactWalk(claimed=self.claimed, budget=next_budget,
                                 reverse=False);
                nb spawn sub;
                self.found.extend(sub.found);
            }
        }
    }
}


# Per-instance graph handle: registry lookups are domain API; each test
# builds its own LineageGraph so no state leaks between runs.
obj LineageGraph {
    has assets: dict[str, Asset] = {};

    def add_node(aid: str, kind: str) -> None {
        if kind not in ("table", "job") {
            raise ValueError(kind);
        }
        if aid in self.assets {
            raise ValueError("duplicate node");
        }
        n = Asset(aid=aid, kind=kind);
        root ++> n;
        self.assets[aid] = n;
    }

    def add_edge(src: str, dst: str) -> None {
        # src feeds dst; unknown endpoints fail closed like the source tables
        if src not in self.assets or dst not in self.assets {
            raise KeyError(src if src not in self.assets else dst);
        }
        self.assets[src] +>:Feeds:+> self.assets[dst];
    }

    # sorted asset ids reachable from anchor; reverse selects upstream
    def _closure(anchor: str, max_depth: int | None, reverse: bool) -> list[str] {
        start_budget = -1;
        if max_depth is not None {
            start_budget = max_depth;
        }
        w = self.assets[anchor] spawn ImpactWalk(
            budget=start_budget, reverse=reverse
        );
        return sorted(set(w.found));
    }

    # sorted asset ids reachable from anchor in the given direction
    def impact(anchor: str, direction: str = "downstream",
               max_depth: int | None = None) -> list[str] {
        if anchor not in self.assets {
            raise KeyError(anchor);
        }
        if direction == "upstream" {
            return self._closure(anchor, max_depth, True);
        }
        if direction == "downstream" {
            return self._closure(anchor, max_depth, False);
        }
        if direction == "both" {
            ups = set(self._closure(anchor, max_depth, True));
            downs = set(self._closure(anchor, max_depth, False));
            return sorted(ups | downs);
        }
        raise ValueError(direction);
    }

    def impact_by_kind(anchor: str, direction: str = "downstream",
                       max_depth: int | None = None) -> dict {
        grouped: dict = {"table": [], "job": []};
        for nid in self.impact(anchor, direction, max_depth) {
            grouped[self.assets[nid].kind].append(nid);
        }
        return grouped;
    }

    def max_fanout(anchor: str, max_depth: int | None = None) -> int {
        # widest single join: max direct-feeds count over the closure
        widest = 0;
        for nid in self.impact(anchor, "downstream", max_depth) {
            widest = max(widest, len([self.assets[nid] ->:Feeds:->]));
        }
        return widest;
    }
}


test "happy path: chain, diamond, both directions" {
    g = LineageGraph();
    g.add_node("raw", "table");
    g.add_node("stg", "table");
    g.add_node("mart", "table");
    g.add_node("etl", "job");
    g.add_node("agg", "job");
    g.add_edge("raw", "stg");
    g.add_edge("stg", "mart");
    g.add_edge("raw", "etl");
    g.add_edge("etl", "mart");
    assert g.impact("raw") == ["etl", "mart", "raw", "stg"], g.impact("raw");
    assert g.impact("mart", direction="upstream") == ["etl", "mart", "raw", "stg"];
    assert g.impact("raw", direction="both") == ["etl", "mart", "raw", "stg"];
    assert g.impact_by_kind("raw") == {"job": ["etl"], "table": ["mart", "raw", "stg"]};
    assert g.max_fanout("raw") == 2;
    assert g.max_fanout("mart") == 0;
}

test "depth cap bounds expansion" {
    g = LineageGraph();
    for i in range(6) { g.add_node("n{}".format(i), "table"); }
    for i in range(5) { g.add_edge("n{}".format(i), "n{}".format(i + 1)); }
    assert g.impact("n0", max_depth=1) == ["n0", "n1"];
    assert g.impact("n0", max_depth=2) == ["n0", "n1", "n2"];
}

test "diamond visits shared node once; adversarial cycle terminates" {
    g = LineageGraph();
    g.add_node("a2", "table");
    g.add_node("b1", "table");
    g.add_node("b2", "table");
    g.add_node("shared", "table");
    g.add_edge("a2", "b1");
    g.add_edge("a2", "b2");
    g.add_edge("b1", "shared");
    g.add_edge("b2", "shared");
    assert g.impact("a2") == ["a2", "b1", "b2", "shared"];
    g.assets["shared"] +>:Feeds:+> g.assets["a2"];  # hostile back-edge
    assert g.impact("a2") == ["a2", "b1", "b2", "shared"];
    assert g.impact("shared", direction="both") == [
        "a2", "b1", "b2", "shared"
    ];
}

test "errors preserved" {
    g = LineageGraph();
    g.add_node("t9", "table");
    try {
        g.add_node("x9", "view");
        assert False;
    } except ValueError {
        assert True;
    }
    try {
        g.add_node("t9", "table");
        assert False;
    } except ValueError {
        assert True;
    }
    try {
        g.impact("ghost");
        assert False;
    } except KeyError {
        assert True;
    }
}

test "fresh instances do not leak state" {
    a = LineageGraph();
    b = LineageGraph();
    a.add_node("solo", "table");
    try {
        b.impact("solo");
        assert False;
    } except KeyError {
        assert True;
    }
}
