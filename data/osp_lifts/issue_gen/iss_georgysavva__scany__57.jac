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
