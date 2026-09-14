node Checkpoint {
    has cid: str;
    has rendered_prefix: str;
    has exact_tokens: list[str];
    has history_bytes: int = 0;
    has frontier_bytes: int = 0;
    has available: bool = True;
}

edge ChildOf {}

obj CheckpointStore {
    has root_node: Checkpoint | None = None;
    has nodes: dict[str, Checkpoint] = {};
}

walker BestPrefix {
    has prompt_tokens: list[str];
    has claimed: dict[str, bool] = {};
    has best: Checkpoint | None = None;

    can seek with Checkpoint entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        if here.available and _prefix_match(self.prompt_tokens, here.exact_tokens) {
            if self.best is None {
                self.best = here;
            } else {
                current: Checkpoint = self.best;
                if len(here.exact_tokens) > len(current.exact_tokens) {
                    self.best = here;
                }
            }
        }
        for kid in [here ->:ChildOf:->][?:Checkpoint] {
            if kid.available { visit :0: [kid]; }
        }
    }
}

walker LeafCollector {
    has protected: str;
    has claimed: dict[str, bool] = {};
    has leaves: list[str] = [];

    can collect with Checkpoint entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.available == False { skip; }
        print(here.cid);
        kids: list[Checkpoint] = [];
        for kid in [here ->:ChildOf:->][?:Checkpoint] {
            if kid.available {
                kids.append(kid);
                visit :0: [kid];
            }
        }
        if len(kids) == 0 and here.cid != self.protected {
            self.leaves.append(here.cid);
        }
    }
}

def _prefix_match(full: list[str], prefix: list[str]) -> bool {
    if len(prefix) > len(full) { return False; }
    i: int = 0;
    for token in prefix {
        if full[i] != token { return False; }
        i += 1;
    }
    return True;
}

def new_store() -> CheckpointStore {
    return CheckpointStore();
}

def publish_checkpoint(
    store: CheckpointStore,
    cid: str,
    parent_id: str | None,
    rendered_prefix: str,
    exact_tokens: list[str],
    history_bytes: int,
    frontier_bytes: int
) -> Checkpoint {
    if cid in store.nodes { return store.nodes[cid]; }
    node = Checkpoint(
        cid=cid,
        rendered_prefix=rendered_prefix,
        exact_tokens=exact_tokens,
        history_bytes=history_bytes,
        frontier_bytes=frontier_bytes,
        available=True
    );
    store.nodes[cid] = node;
    parent_node: Checkpoint | None = None;
    if parent_id is not None and parent_id in store.nodes {
        parent_node = store.nodes[parent_id];
    }
    if parent_node is not None {
        parent_node +>:ChildOf:+> node;
    } else if store.root_node is None {
        store.root_node = node;
    }
    return node;
}

def lookup_checkpoint(store: CheckpointStore, cid: str) -> Checkpoint | None {
    if cid in store.nodes { return store.nodes[cid]; }
    return None;
}

def deepest_prefix(store: CheckpointStore, prompt_tokens: list[str]) -> str | None {
    if store.root_node is None { return None; }
    graph_root: Checkpoint = store.root_node;
    w = graph_root spawn BestPrefix(prompt_tokens=prompt_tokens);
    if w.best is None { return None; }
    return w.best.cid;
}

def ram_bytes(store: CheckpointStore) -> int {
    total: int = 0;
    for cid in store.nodes {
        if store.nodes[cid].available {
            total += store.nodes[cid].history_bytes + store.nodes[cid].frontier_bytes;
        }
    }
    return total;
}

def prune_ram(store: CheckpointStore, budget: int) -> list[str] {
    removed: list[str] = [];
    if store.root_node is None { return removed; }
    graph_root: Checkpoint = store.root_node;
    used: int = ram_bytes(store);
    while used > budget {
        scan = graph_root spawn LeafCollector(protected=graph_root.cid);
        if len(scan.leaves) == 0 { break; }
        candidates: list[str] = sorted(scan.leaves);
        target: str = candidates[0];
        if target in store.nodes {
            victim: Checkpoint = store.nodes[target];
            victim.available = False;
            del store.nodes[target];
            removed.append(target);
            used = ram_bytes(store);
        } else {
            break;
        }
    }
    return removed;
}

test "diamond revisit keeps deepest checkpoint" {
    store = new_store();
    root_node = publish_checkpoint(store, "r", None, "", [], 10, 10);
    a = publish_checkpoint(store, "a", "r", "A", ["S", "A"], 10, 10);
    b = publish_checkpoint(store, "b", "r", "B", ["S", "B"], 10, 10);
    d = publish_checkpoint(store, "d", "a", "AD", ["S", "A", "D"], 10, 10);
    b +>:ChildOf:+> d;
    e = publish_checkpoint(store, "e", "d", "ADE", ["S", "A", "D", "E"], 10, 10);
    assert (deepest_prefix(store, ["S", "A", "D", "E", "tail"]) == "e");
}

test "unknown checkpoint ids are tolerated" {
    store = new_store();
    publish_checkpoint(store, "r", None, "", [], 1, 2);
    missing: Checkpoint | None = lookup_checkpoint(store, "missing");
    assert (missing is None);
    assert (prune_ram(store, 100) == []);
}

test "short terminal captures are reusable" {
    store = new_store();
    publish_checkpoint(store, "r", None, "", [], 1, 1);
    publish_checkpoint(store, "short", "r", "a", ["a"], 2, 3);
    publish_checkpoint(store, "long", "short", "ab", ["a", "b"], 4, 5);
    assert (deepest_prefix(store, []) == "r");
    assert (deepest_prefix(store, ["a"]) == "short");
    assert (deepest_prefix(store, ["a", "b", "c"]) == "long");
}

test "ram pruning removes leaves only" {
    store = new_store();
    publish_checkpoint(store, "r", None, "", [], 90, 10);
    publish_checkpoint(store, "a", "r", "a", ["a"], 10, 10);
    publish_checkpoint(store, "b", "r", "b", ["b"], 15, 15);
    publish_checkpoint(store, "c", "a", "ac", ["a", "c"], 20, 20);
    removed: list[str] = prune_ram(store, 120);
    assert (removed == ["b", "c"]);
    assert (lookup_checkpoint(store, "a") is not None);
    assert (lookup_checkpoint(store, "b") is None);
    assert (ram_bytes(store) == 120);
}
