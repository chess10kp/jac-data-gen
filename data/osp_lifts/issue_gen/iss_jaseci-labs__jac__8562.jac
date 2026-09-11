"""jaseci-labs/jac#8562 — OSP lift: cycle-safe once-per-node traversal."""

import from collections { defaultdict }

node Item {
    has name: str;
}

edge Link {}

# Per-test handle — no module-level mutable state (§5.2)
obj GraphHandle {
    has name_to_item: dict = {};

    def seed_cycle_abc() -> None {
        a = Item(name="a");
        b = Item(name="b");
        c = Item(name="c");
        root ++> a;
        root ++> b;
        root ++> c;
        a +>:Link:+> b;
        b +>:Link:+> c;
        c +>:Link:+> a;
        self.name_to_item = {"a": a, "b": b, "c": c};
    }

    def seed_diamond() -> None {
        s = Item(name="s");
        l = Item(name="l");
        r = Item(name="r");
        t = Item(name="t");
        root ++> s;
        s +>:Link:+> l;
        s +>:Link:+> r;
        l +>:Link:+> t;
        r +>:Link:+> t;
        self.name_to_item = {"s": s, "l": l, "r": r, "t": t};
    }

    def count_reachable_dfs(start_name: str) -> int {
        # Spawn from root; visit children only (avoid root off-by-one)
        w = root spawn ReachCounter(start_name=start_name, use_bfs=False);
        return w.count if hasattr(w, "count") else 0;
    }

    def count_reachable_bfs(start_name: str) -> int {
        w = root spawn ReachCounter(start_name=start_name, use_bfs=True);
        return w.count;
    }

    def reachable_nodes(start_name: str) -> list {
        w = root spawn ReachCollector(start_name=start_name);
        return sorted(w.names);
    }
}

walker ReachCounter {
    has start_name: str;
    has use_bfs: bool = False;
    has count: int = 0;
    has claimed: dict = {};  # jid -> True claim-map (cycle policy)

    can begin with Root entry {
        # Resolve start node by name under root
        targets = [-->][?:Item];
        start_node = None;
        for n in targets {
            if n.name == self.start_name {
                start_node = n;
                break;
            }
        }
        if start_node is None {
            disengage;
        }
        if self.use_bfs {
            visit [start_node];
        } else {
            visit :0: [start_node];  # DFS front-insert
        }
    }

    can step with Item entry {
        jid = here.jid;
        if self.claimed.get(jid, False) {
            skip;  # revisit on cycle — NEVER disengage
        }
        self.claimed[jid] = True;
        self.count += 1;
        if self.use_bfs {
            visit [-->];
        } else {
            visit :0: [-->];
        }
    }
}

walker ReachCollector {
    has start_name: str;
    has names: list = [];
    has claimed: dict = {};

    can begin with Root entry {
        targets = [-->][?:Item];
        start_node = None;
        for n in targets {
            if n.name == self.start_name {
                start_node = n;
                break;
            }
        }
        if start_node is None {
            disengage;
        }
        visit [start_node];
    }

    can step with Item entry {
        jid = here.jid;
        if self.claimed.get(jid, False) {
            skip;
        }
        self.claimed[jid] = True;
        self.names.append(here.name);
        visit [-->];
    }
}
