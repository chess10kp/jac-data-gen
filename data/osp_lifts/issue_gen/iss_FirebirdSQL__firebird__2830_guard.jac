"""FirebirdSQL/firebird#2830 — recursive CTE anchor scan vs indexed traversal."""

node Tmp {
    has node_id: int;
    has parent_id: int = -1;
}

edge ParentToChild {}

walker NodeGather {
    has claimed: dict[str, bool] = {};
    has found: list[Tmp] = [];

    can gather with Tmp entry {
        cid = str(here.node_id);
        if cid in self.claimed {
            skip;
        }
        self.claimed[cid] = True;
        self.found.append(here);
        print("gather", here.node_id);
        kids: list[Tmp] = [];
        for ch in [here ->:ParentToChild:->][?:Tmp] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        }
    }
}

walker PairCollector {
    has anchor_tid: int;
    has pairs: list[tuple[int, int]] = [];
    has claimed: dict[str, bool] = {};

    can walk with Tmp entry {
        key = str(self.anchor_tid) + ":" + str(here.node_id);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        self.pairs.append((self.anchor_tid, here.node_id));
        print("pair", self.anchor_tid, here.node_id);
        kids: list[Tmp] = [];
        for ch in [here ->:ParentToChild:->][?:Tmp] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};

    can show with Tmp entry {
        cid = str(here.node_id);
        if cid in self.claimed {
            skip;
        }
        self.claimed[cid] = True;
        print("demo node", here.node_id);
        kids: list[Tmp] = [];
        for ch in [here ->:ParentToChild:->][?:Tmp] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        }
    }
}

obj TmpGraph {
    has root_anchor: Tmp | None = None;
    has by_id: dict[str, Tmp] = {};

    def insert(node_id: int, parent_id: int | None = None) {
        sid = str(node_id);
        if sid in self.by_id {
            raise ValueError("duplicate id");
        }
        pid_val = -1;
        if parent_id is not None {
            pid_val = parent_id;
            ps = str(parent_id);
            if ps not in self.by_id {
                raise KeyError("unknown parent");
            }
        }
        nd = Tmp(node_id=node_id, parent_id=pid_val);
        self.by_id[sid] = nd;
        if self.root_anchor is None {
            self.root_anchor = nd;
            root ++> nd;
        } else {
            self.root_anchor ++> nd;
        }
        if parent_id is not None {
            par = self.by_id[str(parent_id)];
            par +>:ParentToChild:+> nd;
        }
    }

    def recursive_pairs(anchor_id: int | None = None) -> list[tuple[int, int]] {
        pairs: list[tuple[int, int]] = [];
        if self.root_anchor is None {
            return pairs;
        }
        seeds: list[Tmp] = [];
        all_nds: list[Tmp] = self._all_nodes_sorted();
        if anchor_id is not None {
            hit = self._find(anchor_id);
            if hit is None {
                return [];
            }
            seeds.append(hit);
        } else {
            for nd in all_nds {
                seeds.append(nd);
            }
        }
        for seed in seeds {
            tid = seed.node_id;
            w = seed spawn PairCollector(anchor_tid=tid, pairs=[], claimed={});
            for p in w.pairs {
                pairs.append(p);
            }
        }
        return sorted(pairs);
    }

    def explain_plan(anchor_id: int | None = None) -> list[str] {
        steps: list[str] = [];
        if anchor_id is not None {
            steps.append("S TMP INDEX (RDB$PRIMARY8)");
            steps.append("S TMP INDEX (RDB$FOREIGN9)");
        } else {
            steps.append("S TMP NATURAL");
            steps.append("S TMP INDEX (RDB$FOREIGN9)");
        }
        return steps;
    }

    def _find(node_id: int) -> Tmp | None {
        sid = str(node_id);
        if sid in self.by_id {
            return self.by_id[sid];
        }
        return None;
    }

    def _all_nodes_sorted() -> list[Tmp] {
        out: list[Tmp] = [];
        keys: list[str] = [];
        for k in self.by_id {
            keys.append(k);
        }
        keys = sorted(keys);
        for k in keys {
            out.append(self.by_id[k]);
        }
        return out;
    }
}

with entry {
    g = TmpGraph();
    g.insert(1, None);
    g.insert(2, 1);
    print("plan", g.explain_plan(1));
    print("pairs", g.recursive_pairs(1));
    root spawn DemoWalker(claimed={});
}

test "recursive_pairs_from_anchor" {
    g = TmpGraph();
    g.insert(1, None);
    g.insert(2, 1);
    g.insert(3, 1);
    pairs = g.recursive_pairs(1);
    assert pairs == [(1, 1), (1, 2), (1, 3)];
}

test "recursive_pairs_full_scan" {
    g = TmpGraph();
    g.insert(1, None);
    g.insert(2, 1);
    g.insert(3, 1);
    pairs = g.recursive_pairs(None);
    assert pairs == [(1, 1), (1, 2), (1, 3), (2, 2), (3, 3)];
}

test "recursive_pairs_unknown_anchor" {
    g = TmpGraph();
    g.insert(1, None);
    pairs = g.recursive_pairs(99);
    assert pairs == [];
}

test "explain_plan_with_anchor" {
    g = TmpGraph();
    steps = g.explain_plan(1);
    assert steps == ["S TMP INDEX (RDB$PRIMARY8)", "S TMP INDEX (RDB$FOREIGN9)"];
}

test "explain_plan_full_scan" {
    g = TmpGraph();
    steps = g.explain_plan(None);
    assert steps == ["S TMP NATURAL", "S TMP INDEX (RDB$FOREIGN9)"];
}

test "insert_duplicate_raises" {
    g = TmpGraph();
    g.insert(1, None);
    raised = False;
    try {
        g.insert(1, None);
    } except ValueError {
        raised = True;
    }
    assert raised;
}
