"""risingwavelabs/risingwave#15135 — minimal recursive CTE iteration oracle."""

node Row {
    has key: str;
}

edge RecursiveEdge {}

glob MAX_RECURSIVE_ITERATION: int = 16;

walker RcteWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has start: str = "";
    has reports: list[list[str]] = [];

    can begin with Root entry {
        for r in [-->][?:Row] {
            if r.key == self.start {
                visit [r];
                return;
            }
        }
        report [];
        disengage;
    }

    can step with Row entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.order.append(here.key);
        visit [->:RecursiveEdge:->];
    }

    can finish with Root exit {
        report self.order;
    }
}

walker RcteBudgetWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has budget: int = 0;

    can step with Row entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.order.append(here.key);
        if self.budget <= 0 {
            disengage;
        }
        for nxt in [here ->:RecursiveEdge:->] {
            nxt spawn RcteBudgetWalker(
                claimed=self.claimed,
                order=self.order,
                budget=self.budget - 1,
            );
        }
    }
}

obj RcteGraph {
    has _root: Root;
    has _index: dict[str, Row] = {};

    def init {
        self._root = root;
    }

    def load_edges(edges: list[tuple[str, str]]) {
        for (src, dst) in edges {
            if src not in self._index {
                self._index[src] = Row(key=src);
                self._root ++> self._index[src];
            }
            if dst not in self._index {
                self._index[dst] = Row(key=dst);
                self._root ++> self._index[dst];
            }
            self._index[src] +>:RecursiveEdge:+> self._index[dst];
        }
    }

    def _anchor(seed: str) -> Row | None {
        return self._index.get(seed);
    }

    def recursive_union_expand(seed: str, max_iter: int = MAX_RECURSIVE_ITERATION) -> list[str] {
        anchor = self._anchor(seed);
        if anchor is None {
            return [];
        }
        w = anchor spawn RcteBudgetWalker(claimed={}, order=[], budget=max_iter);
        return w.order;
    }

    def cte_ref_reachable(seed: str) -> list[str] {
        got = self.recursive_union_expand(seed);
        seen: set[str] = set();
        for k in got {
            seen.add(k);
        }
        return sorted(seen);
    }

    def stopped_by_iteration_cap(seed: str) -> bool {
        anchor = self._anchor(seed);
        if anchor is None {
            return False;
        }
        full_w = self._root spawn RcteWalker(start=seed, claimed={}, order=[]);
        full = full_w.reports[0] if full_w.reports else [];
        capped = self.recursive_union_expand(seed);
        full_set: set[str] = set();
        cap_set: set[str] = set();
        for k in full {
            full_set.add(k);
        }
        for k in capped {
            cap_set.add(k);
        }
        return len(full_set) > len(cap_set);
    }
}

def build_rcte_graph(edges: list[tuple[str, str]]) -> RcteGraph {
    g = RcteGraph();
    g.load_edges(edges);
    return g;
}

def recursive_union_expand(
    store: RcteGraph,
    seed: str,
    max_iter: int = MAX_RECURSIVE_ITERATION,
) -> list[str] {
    return store.recursive_union_expand(seed, max_iter);
}

def cte_ref_reachable(store: RcteGraph, seed: str) -> list[str] {
    return store.cte_ref_reachable(seed);
}

def stopped_by_iteration_cap(store: RcteGraph, seed: str) -> bool {
    return store.stopped_by_iteration_cap(seed);
}
