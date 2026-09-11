"""Guard: teamleaderleo/preflight#652."""

node Milestone { has mid: str; has parent_mid: str | None = None; }
edge GateOf {}

obj ReleaseTree { has milestones: dict[str, Milestone] = {}; }

def load_release_tree(
    milestone_ids: list[str],
    parent_edges: list[tuple[str, str]],
) -> ReleaseTree {
    tree = ReleaseTree();
    for mid in milestone_ids {
        if mid not in tree.milestones {
            nd = Milestone(mid=mid);
            root ++> nd;
            tree.milestones[mid] = nd;
        }
    }
    for (parent, child) in parent_edges {
        p = tree.milestones.get(parent, None);
        c = tree.milestones.get(child, None);
        if p is not None and c is not None {
            c.parent_mid = parent;
            p +>:GateOf:+> c;
        }
    }
    return tree;
}

def blocking_chain(tree: ReleaseTree, milestone_id: str) -> list[str] {
    start = tree.milestones.get(milestone_id, None);
    if start is None { return []; }
    chain: list[str] = [];
    cur: Milestone | None = start;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.mid in seen { break; }
        seen[cur.mid] = True;
        chain.append(cur.mid);
        parent_id = cur.parent_mid;
        cur = tree.milestones.get(parent_id, None) if parent_id is not None else None;
    }
    chain.reverse();
    return chain;
}

def next_unlocked(tree: ReleaseTree, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    unlocked: list[str] = [];
    for mid in tree.milestones.keys() {
        if mid in done { continue; }
        blockers = blocking_chain(tree, mid);
        ok = True;
        for b in blockers {
            if b != mid and b not in done { ok = False; }
        }
        if ok { unlocked.append(mid); }
    }
    unlocked.sort();
    return unlocked;
}

test "release gate blocking chain" {
    t = load_release_tree(
        ["source", "benchmark", "desktop", "signing", "beta"],
        [
            ("source", "benchmark"),
            ("benchmark", "desktop"),
            ("desktop", "signing"),
            ("signing", "beta"),
        ],
    );
    assert blocking_chain(t, "beta") == ["source", "benchmark", "desktop", "signing", "beta"];
    assert next_unlocked(t, []) == ["source"];
    assert next_unlocked(t, ["source", "benchmark"]) == ["desktop"];
}

test "parallel gates unlock together" {
    t = load_release_tree(
        ["root", "a", "b", "join"],
        [("root", "a"), ("root", "b"), ("a", "join"), ("b", "join")],
    );
    assert next_unlocked(t, ["root"]) == ["a", "b"];
    assert next_unlocked(t, ["root", "a", "b"]) == ["join"];
}

test "unknown milestone tolerant" {
    t = load_release_tree(["solo"], []);
    assert blocking_chain(t, "missing") == [];
}
