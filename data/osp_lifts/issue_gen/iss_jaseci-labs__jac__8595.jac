"""jaseci-labs/jac#8595 — paged neighborhood + folded reachability (OSP)."""

node GNode {
    has node_id: str;
}

edge GLink {}

obj GraphView {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def add_node(node_id: str) {
        if self._find(node_id) is None {
            self._root ++> GNode(node_id=node_id);
        }
    }

    def link(src: str, dst: str) {
        s = self._find(src);
        d = self._find(dst);
        if s is None or d is None {
            raise KeyError("unknown node id");
        }
        s +>:GLink:+> d;
    }

    def neighbors_page(node_id: str, offset: int, limit: int) -> list[str] {
        n = self._find(node_id);
        if n is None {
            return [];
        }
        w = n spawn NeighborCollector();
        nbrs = sorted(w.neighbors);
        return nbrs[offset : offset + limit];
    }

    def neighborhood_cost(node_id: str) -> int {
        n = self._find(node_id);
        if n is None {
            return 0;
        }
        w = n spawn NeighborCollector();
        return len(w.neighbors);
    }

    def reachable(seed: str) -> list[str] {
        n = self._find(seed);
        if n is None {
            return [];
        }
        w = self._root spawn ReachFold(start_id=seed);
        return sorted(w.seen);
    }

    def _find(node_id: str) -> GNode | None {
        for n in [self._root-->[?:GNode]] {
            if n.node_id == node_id {
                return n;
            }
        }
        return None;
    }
}

walker NeighborCollector {
    has neighbors: list[str] = [];

    can collect with GNode entry {
        for t in [here->:GLink:->][?:GNode] {
            self.neighbors.append(t.node_id);
        }
    }
}

walker ReachFold {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};

    can start with Root entry {
        for n in [-->][?:GNode] {
            if n.node_id == self.start_id {
                visit [n];
            }
        }
    }

    can walk with GNode entry {
        nid = here.node_id;
        if nid in self.claims {
            skip;
        }
        self.claims[nid] = True;
        self.seen.append(nid);
        visit [here->:GLink:->][?:GNode];
    }
}
