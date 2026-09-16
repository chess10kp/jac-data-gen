# sqlc-dev/sqlc#2390 — recursive depth-walk over tree edges with computed
# integer terms (depth+1), like a recursive CTE whose UNION ALL term computes
# new integers per level. OSP lift: nodes + typed Edge, a walker carries a
# depth field and spawns child walkers at depth+1; a claim-map guards cycles.

node Graph { has name: str; }
node Node {
    has nid: str;
    has kind: str = "generic";
    has name: str = "";
}
edge Edge { has ordinal: int = 0; }

# recursive-CTE analogue: returns list of (nid, depth) rows, sorted by depth
def get_dependent_nodes(start_nid: str, g: Graph | None = None) -> list[tuple[str, int]] {
    src: Graph = root;
    if g is not None {
        src = g;
    }
    start: Node | None = None;
    for nd in [src ->:Edge:->][?:Node] {
        if nd.nid == start_nid { start = nd; }
    }
    rows: list[tuple[str, int]] = [];
    if start is None {
        # unknown id tolerated: empty result, no exception
        return rows;
    }
    wk = start spawn DepWalk(claimed={}, depth=0);
    for r in wk.rows { rows.append(r); }
    rows.sort(key=lambda t: (t[1], t[0]));
    return rows;
}

walker DepWalk {
    has claimed: dict[str, bool] = {};
    has rows: list[tuple[str, int]] = [];
    has depth: int = 0;

    can step with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.rows.append((here.nid, self.depth));
        # collect children; each child becomes a UNION ALL term at depth+1
        kids: list[Node] = [];
        for ch in [here ->:Edge:->][?:Node] {
            kids.append(ch);
        }
        for kd in kids {
            sub = kd spawn DepWalk(claimed=self.claimed, depth=self.depth + 1);
            for r in sub.rows { self.rows.append(r); }
            for k in sub.claimed.keys() { self.claimed[k] = True; }
        }
        disengage;
    }
}
