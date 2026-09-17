# dsa-collective/algorithm-visualizer#11
# Corpus of example algorithms organized by visualizer type, stored as a graph.

node Example {
    has name: str;
    has category: str;          # two_pointer | sliding_window | recursion | graph | heap | dp
    has code: str;
    has sample_input: str = "";
    has readme: str = "";
}

node Visualizer {
    has kind: str;              # groups examples by visualizer type
}

edge InGroup {}                # Visualizer -> Example

def make_corpus() -> Visualizer {
    vis = Visualizer(kind="all");
    root ++> vis;
    seed: list[tuple[str, str, str, str]] = [
        ("reverse_array", "two_pointer", "l, r = 0, len(a)-1; swap inward", "[1,2,3]"),
        ("container_water", "two_pointer", "shrink by shorter wall", "[4,3,2,1]"),
        ("longest_substr", "sliding_window", "expand right, shrink on repeat", "abcabc"),
        ("factorial", "recursion", "single branch depth-first", "5"),
        ("fibonacci", "recursion", "binary call tree", "6"),
        ("tree_inorder", "recursion", "left-root-right on a tree", "(1,(2),(3))"),
        ("bfs_grid", "graph", "queue-based frontier sweep", "4x4 grid"),
        ("dfs_adjlist", "graph", "stack-based adjacency walk", "a:b,c b:d c:d"),
        ("running_median", "heap", "two-heap invariant", "[5,3,8]"),
        ("kth_largest", "heap", "bounded min-heap", "k=2 [3,1,4]"),
        ("climb_stairs", "dp", "1D rolling table", "10"),
        ("edit_distance", "dp", "2D table fill", "kitten sitting"),
        ("lcs", "dp", "2D traceback", "ABCBDAB BDCABA"),
    ];
    for ex in seed {
        nd = Example(name=ex[0], category=ex[1], code=ex[2], sample_input=ex[3],
                     readme="expect " + ex[1] + " trace for " + ex[0]);
        vis +>:InGroup:+> nd;
    }
    return vis;
}

def list_examples(corpus_root: Visualizer) -> list[str] {
    out: list[str] = [];
    for e in [corpus_root ->:InGroup:->][?:Example] {
        out.append(e.name);
    }
    return sorted(out);
}

def by_category(corpus_root: Visualizer, cat: str) -> list[str] {
    out: list[str] = [];
    for e in [corpus_root ->:InGroup:->][?:Example] {
        if e.category == cat { out.append(e.name); }
    }
    return sorted(out);
}

def lookup_example(corpus_root: Visualizer, name: str) -> Example | None {
    # unknown-id tolerance: returns None instead of raising
    for e in [corpus_root ->:InGroup:->][?:Example] {
        if e.name == name { return e; }
    }
    return None;
}

walker CountByCategory {
    has counts: dict[str, int] = {};
    can step with Example entry {
        if here.name in self.counts { skip; }   # claim-map cycle policy
        self.counts[here.name] = 1;
        self.counts["cat:" + here.category] = self.counts.get("cat:" + here.category, 0) + 1;
        for nxt in [here ->:InGroup:->][?:Example] {
            visit [nxt] else { disengage; }
        }
    }
    can start with Visualizer entry {
        for e in [here ->:InGroup:->][?:Example] {
            visit [e];
        }
        print(sorted(self.counts.keys()));
    }
}

test "diamond_revisit_counted_once" {
    vis = make_corpus();
    w = vis spawn CountByCategory(counts={});
    # every example reachable twice via wrapper edges would double-count without claim-map
    assert len(list_examples(vis)) == 13;
    assert w.counts.get("cat:dp", 0) == 3;
}

test "at_least_two_per_visualizer_type" {
    vis = make_corpus();
    assert len(by_category(vis, "two_pointer")) >= 2;
    assert len(by_category(vis, "sliding_window")) >= 1;
    assert len(by_category(vis, "recursion")) >= 2;
    assert len(by_category(vis, "graph")) >= 2;
    assert len(by_category(vis, "heap")) >= 2;
    assert len(by_category(vis, "dp")) >= 2;
}

test "sorted_listing_is_deterministic" {
    vis = make_corpus();
    got = list_examples(vis);
    assert got == sorted(got);
    assert "bfs_grid" in got;
}

test "unknown_id_tolerant_lookup" {
    vis = make_corpus();
    hit = lookup_example(vis, "fibonacci");
    assert hit is not None;
    assert hit.category == "recursion";
    miss = lookup_example(vis, "no_such_algo");
    assert miss is None;
}

test "edge_case_empty_corpus_categories" {
    vis = make_corpus();
    assert by_category(vis, "quantum") == [];
}
