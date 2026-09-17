# georgysavva/scany#57 — scanning into a recursive struct (Parent *Node)
# Lifted: hand-rolled parent-pointer walk -> native OSP nodes + edges + walker.

node Node {
    has id: str;
    has parent_id: str | None = None;
}

edge ParentEdge {}

# row format: [id, parent_id] with "" meaning NULL parent
def link_nodes(rows: list[list[str]]) -> dict[str, Node] {
    built: dict[str, Node] = {};
    for r in rows {
        nid: str = r[0];
        pid: str | None = None;
        if r[1] != "" {
            pid = r[1];
        }
        nd: Node = Node(id=nid, parent_id=pid);
        built[nid] = nd;
        root ++> nd;
    }
    for r in rows {
        if r[1] != "" {
            c: Node = built[r[0]];
            p: Node = built[r[1]];
            c +>:ParentEdge:+> p;
        }
    }
    return built;
}

def ancestors_or_self(store: dict[str, Node], start: str) -> list[str] {
    out: list[str] = [];
    if start not in store {
        return out;
    }
    seen: dict[str, bool] = {};
    cur: Node | None = store[start];
    while cur is not None {
        if cur.id in seen {
            cur = None;   # recursive-struct guard: terminate the loop
        } else {
            seen[cur.id] = True;
            out.append(cur.id);
            ups: list[Node] = [cur ->:ParentEdge:->][?:Node];
            if len(ups) == 0 {
                cur = None;
            } else {
                cur = ups[0];
            }
        }
    }
    return out;
}

def depth_of(store: dict[str, Node], start: str) -> int {
    if start not in store {
        return -1;
    }
    return len(ancestors_or_self(store, start)) - 1;
}

# full scan of the scanned node set; claim-map + skip for cycle safety
walker ScanAll {
    has claimed: dict[str, bool] = {};
    has visited_order: list[str] = [];

    can step with Node entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.visited_order.append(here.id);
        kids: list[Node] = [here ->:ParentEdge:->][?:Node];
        if len(kids) > 0 {
            visit kids;
        } else {
            disengage;
        }
    }
}

def scan_all(rows: list[list[str]]) -> list[str] {
    built: dict[str, Node] = link_nodes(rows);
    w = root spawn ScanAll(claimed={});
    return sorted(w.visited_order);
}

test "linear_chain_ancestors" {
    rows: list[list[str]] = [["a", ""], ["b", "a"], ["c", "b"]];
    built: dict[str, Node] = link_nodes(rows);
    assert ancestors_or_self(built, "c") == ["c", "b", "a"];
    assert depth_of(built, "c") == 2;
    assert depth_of(built, "a") == 0;
}

test "self_recursive_struct_terminates" {
    rows: list[list[str]] = [["n", "n"]];
    built: dict[str, Node] = link_nodes(rows);
    out: list[str] = ancestors_or_self(built, "n");
    assert out == ["n"];
    assert len(out) == 1;
}

test "unknown_id_tolerance" {
    rows: list[list[str]] = [["a", ""]];
    built: dict[str, Node] = link_nodes(rows);
    assert ancestors_or_self(built, "zzz") == [];
    assert depth_of(built, "zzz") == -1;
}

test "scan_all_adversarial_diamond_revisit" {
    rows: list[list[str]] = [
        ["root", ""], ["l", "root"], ["r", "root"],
        ["m", "l"], ["m2", "r"], ["d", "m"], ["d2", "m2"]
    ];
    got: list[str] = scan_all(rows);
    assert len(got) == 6;
    assert "root" in got;
    assert "m" in got and "m2" in got and "d" in got and "d2" in got;
}

test "orphan_and_deep_chain" {
    rows: list[list[str]] = [["x", ""], ["a", ""], ["b", "a"], ["c", "b"], ["e", "c"]];
    built: dict[str, Node] = link_nodes(rows);
    assert ancestors_or_self(built, "e") == ["e", "c", "b", "a"];
    assert ancestors_or_self(built, "x") == ["x"];
    assert depth_of(built, "e") == 3;
}

test "repeated_scan_idempotent" {
    rows: list[list[str]] = [["a", ""], ["b", "a"]];
    first: list[str] = scan_all(rows);
    second: list[str] = scan_all(rows);
    assert first == second;
}
