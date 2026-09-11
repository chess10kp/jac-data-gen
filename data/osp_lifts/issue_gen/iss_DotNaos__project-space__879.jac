"""DotNaos/project-space#879 — Recursive change decomposition tree accounting."""

obj ChangeTree {
    has pieces: dict[str, ChangePiece] = {};
}

node ChangePiece {
    has pid: str;
    has state: str = "deferred";
}

edge Contains {}

def load_change_tree(
    pieces: list[str],
    parent_edges: list[tuple[str, str]],
    states: list[tuple[str, str]],
) -> ChangeTree {
    tree = ChangeTree();
    for pid in pieces {
        if pid not in tree.pieces {
            nd = ChangePiece(pid=pid);
            root ++> nd;
            tree.pieces[pid] = nd;
        }
    }
    for (parent, child) in parent_edges {
        p = tree.pieces.get(parent, None);
        c = tree.pieces.get(child, None);
        if p is not None and c is not None { p +>:Contains:+> c; }
    }
    for (pid, state) in states {
        nd: ChangePiece | None = tree.pieces.get(pid, None);
        if nd is not None { nd.state = state; }
    }
    return tree;
}

def descendant_pieces(tree: ChangeTree, `root: str) -> list[str] {
    anchor = tree.pieces.get(`root, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {`root: True};
    snap: list[str] = [];
    for ch in [anchor ->:Contains:->][?:ChangePiece] {
        if ch.pid not in claimed {
            claimed[ch.pid] = True;
            snap.append(ch.pid);
        }
    }
    i = 0;
    while i < len(snap) {
        pid = snap[i];
        i += 1;
        nd = tree.pieces.get(pid, None);
        if nd is None { continue; }
        for ch in [nd ->:Contains:->][?:ChangePiece] {
            if ch.pid not in claimed {
                claimed[ch.pid] = True;
                snap.append(ch.pid);
            }
        }
    }
    return sorted(snap);
}

def flatten_leaves(tree: ChangeTree, `root: str) -> list[str] {
    anchor = tree.pieces.get(`root, None);
    if anchor is None { return []; }
    leaves: list[str] = [];
    snap: list[str] = [`root];
    i = 0;
    while i < len(snap) {
        pid = snap[i];
        i += 1;
        nd = tree.pieces.get(pid, None);
        if nd is None { continue; }
        kids = [nd ->:Contains:->][?:ChangePiece];
        if not kids {
            leaves.append(pid);
        } else {
            for ch in kids {
                if ch.pid not in snap { snap.append(ch.pid); }
            }
        }
    }
    return sorted(leaves);
}

def partition_accounting(tree: ChangeTree) -> dict[str, int] {
    counts = {"accepted": 0, "rejected": 0, "deferred": 0};
    for pid in tree.pieces.keys() {
        st = tree.pieces[pid].state;
        if st == "accepted" { counts["accepted"] += 1; }
        elif st == "rejected" { counts["rejected"] += 1; }
        else { counts["deferred"] += 1; }
    }
    return counts;
}

def review_complete(tree: ChangeTree) -> bool {
    return partition_accounting(tree)["deferred"] == 0;
}
