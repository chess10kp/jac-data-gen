"""NewChoBo/workbench-kit#286 — Agent Harness governance resource tree."""

node Resource {
    has name: str;
}

edge ChildOf {}

obj HarnessStore {
    has resources: dict[str, Resource] = {};
}

walker DescCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Resource entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        for ch in [here ->:ChildOf:->][?:Resource] {
            visit [ch];
        }
    }
}

def load_harness(resources: list[tuple[str, str | None]]) -> HarnessStore {
    store = HarnessStore();
    for (name, parent) in resources {
        if parent is not None and store.resources.get(parent, None) is None {
            raise KeyError("unknown parent resource");
        }
        nd = Resource(name=name);
        root ++> nd;
        store.resources[name] = nd;
        if parent is not None {
            p = store.resources.get(parent, None);
            if p is not None { p +>:ChildOf:+> nd; }
        }
    }
    return store;
}

def governance_chain(store: HarnessStore, resource: str) -> list[str] {
    nd = store.resources.get(resource, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: Resource | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parent: Resource | None = None;
        for p in [cur <-:ChildOf:<-][?:Resource] {
            parent = p;
            break;
        }
        cur = parent;
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def descendant_resources(store: HarnessStore, `root: str) -> list[str] {
    nd = store.resources.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DescCollect(claimed={}, found=[]);
    return sorted(w.found);
}

def has_cycle(store: HarnessStore) -> bool {
    for k in store.resources.keys() {
        seen: dict[str, bool] = {};
        cur: Resource | None = store.resources.get(k, None);
        while cur is not None {
            if cur.name in seen { return True; }
            seen[cur.name] = True;
            parent: Resource | None = None;
            for p in [cur <-:ChildOf:<-][?:Resource] {
                parent = p;
                break;
            }
            cur = parent;
        }
    }
    return False;
}
