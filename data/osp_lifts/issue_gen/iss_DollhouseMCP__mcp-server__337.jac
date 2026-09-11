"""Memory relationships lifted to OSP.

Memories become Memory nodes; every relationship record becomes one Rel
edge archetype carrying its kind and strength payload (the link list is
homogeneous apart from the kind string, so a single payload edge beats
six edge types -- documented design choice), inserted in BOTH directions
because the store's relationships are navigable either way. The deque
BFS over the adjacency dict becomes a shortest-chain relaxation walker
whose claim map doubles as the cycle guard, and whose hop budget is the
multi-hop reasoning bound. ``contradiction_pairs`` stays a link filter:
in the source it never traverses, it canonicalizes contradicts records.
Ref: DollhouseMCP/mcp-server#337
"""
node Memory {
    has mid: str;
}
edge Rel {
    has kind: str;
    has strength: float;
}

"""Loader handle: memory ids resolve through this lookup map."""
obj MemStore {
    has mems: dict[str, Memory];

    def resolve(mid: str) -> Memory | None {
        return self.mems.get(mid);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_store(store: dict) -> MemStore {
    ms = MemStore(mems={});
    for m in list(store["memories"]) {
        n = Memory(mid=str(m));
        root ++> n;
        ms.mems[str(m)] = n;
    }
    for link in list(store["links"]) {
        frm = ms.resolve(str(link[0]));
        to = ms.resolve(str(link[1]));
        if frm is None or to is None {
            continue;  # unknown memory ids in links are skipped
        }
        kind = str(link[2]);
        strength = float(str(link[3]));
        frm +>:Rel(kind=kind, strength=strength):+> to;
        to +>:Rel(kind=kind, strength=strength):+> frm;
    }
    return ms;
}

walker NearWalk {
    # Cycle policy: claim map keyed by memory id (jac walkers do not
    # dedupe). A non-improving revisit skips; a strictly shallower arrival
    # re-expands, so the map ends holding each memory's shortest link
    # distance -- the multi-hop neighborhood within the hop budget, with
    # link loops terminating on the claim map.
    has best: dict[str, int] = {};
    has hops: int = 0;
    has budget: int = 2;

    can step with Memory entry {
        if here.mid in self.best and self.hops >= self.best[here.mid] {
            skip;
        }
        self.best[here.mid] = self.hops;
        if self.hops < self.budget {
            for nbr in [here->:Rel:->] {
                nbr spawn NearWalk(best=self.best, hops=self.hops + 1, budget=self.budget);
            }
        }
    }
}

"""Memory ids within ``hops`` links of ``mid`` (itself excluded), sorted."""
def related_within(store: dict, mid: str, hops: int = 2) -> list[str] {
    ms = load_store(store);
    start = ms.resolve(mid);
    if start is None {
        raise KeyError(mid);
    }
    w = start spawn NearWalk(best={}, hops=0, budget=hops);
    out: list[str] = [];
    for k in w.best.keys() {
        if k != mid and w.best[k] <= hops {
            out.append(k);
        }
    }
    return sorted(out);
}

"""Canonical contradictory pairs ``[[a, b], ...]`` with a < b, sorted."""
def contradiction_pairs(store: dict) -> list {
    # a filter over the link records, not a traversal: no walk in the
    # source, none here
    pairs: set[str] = set();
    mems: set[str] = set();
    for m in list(store["memories"]) {
        mems.add(str(m));
    }
    for link in list(store["links"]) {
        if str(link[2]) != "contradicts" {
            continue;
        }
        frm = str(link[0]);
        to = str(link[1]);
        if frm not in mems or to not in mems {
            continue;
        }
        if frm < to {
            pairs.add(frm + "|" + to);
        } else {
            pairs.add(to + "|" + frm);
        }
    }
    out: list = [];
    for p in sorted(pairs) {
        out.append(p.split("|"));
    }
    return out;
}
