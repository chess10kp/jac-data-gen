"""pmrv/fleche#809 — extract reachable_closure from Cache.gc."""

node GraphHub {
    has tag: str = "hub";
    with entry {
        root spawn DemoW;
    }
}

node Value {
    has did: str;
}

edge Dep {}

node CallRec {
    has cid: str;
    has result_did: str = "";
    has arg_digs: list[str] = [];
}

walker DemoW {
    can ping with GraphHub entry {
        print ["demo", here.tag];
        disengage;
    }
}

walker ClosureW {
    has nodes: dict[str, Value] = {};
    has seeds: list[str] = [];
    has claimed: dict[str, bool] = {};
    has reachable: list[str] = [];

    can begin with GraphHub entry {
        print ["closure", "begin"];
        for sd in self.seeds {
            if sd not in self.claimed {
                if sd in self.nodes {
                    nd = self.nodes[sd] as Value;
                    visit :0: [nd];
                } else {
                    self.claimed[sd] = True;
                    self.reachable.append(sd);
                }
            }
        }
        disengage;
    }

    can expand with Value entry {
        if here.did in self.claimed {
            skip;
        }
        self.claimed[here.did] = True;
        self.reachable.append(here.did);
        print ["reach", here.did];
        ch_ids: list[str] = [];
        for ch in [here ->:Dep:->][?:Value] {
            ch_ids.append(ch.did);
        }
        for cid in ch_ids {
            if cid not in self.claimed {
                if cid in self.nodes {
                    cn = self.nodes[cid] as Value;
                    visit :0: [cn];
                } else {
                    self.claimed[cid] = True;
                    self.reachable.append(cid);
                }
            }
        }
    }
}

obj ValueStore {
    has hub: GraphHub;
    has nodes: dict[str, Value] = {};

    def child_digests(self, key: str) -> list[str] {
        if key not in self.nodes {
            raise KeyError;
        }
        nd = self.nodes[key] as Value;
        out: list[str] = [];
        for ch in [nd ->:Dep:->][?:Value] {
            out.append(ch.did);
        }
        return out;
    }

    def list_keys(self) -> list[str] {
        ks: list[str] = [];
        for k in self.nodes {
            ks.append(k);
        }
        return sorted(ks);
    }

    def evict(self, key: str) -> bool {
        if key not in self.nodes {
            return False;
        }
        nxt: dict[str, Value] = {};
        for k in self.nodes {
            if k != key {
                nxt[k] = self.nodes[k] as Value;
            }
        }
        self.nodes = nxt;
        return True;
    }

    def add(self, nd: Value) {
        self.nodes[nd.did] = nd;
        self.hub ++> nd;
    }
}

obj Cache {
    has hub: GraphHub;
    has calls: dict[str, CallRec] = {};
    has values: ValueStore;

    def discover_roots(self) -> list[str] {
        roots: list[str] = [];
        seen: dict[str, bool] = {};
        cids: list[str] = [];
        for c in self.calls {
            cids.append(c);
        }
        for cid in sorted(cids) {
            cr = self.calls[cid] as CallRec;
            if cr.result_did != "" {
                if cr.result_did not in seen {
                    seen[cr.result_did] = True;
                    roots.append(cr.result_did);
                }
            }
            for ad in cr.arg_digs {
                if ad not in seen {
                    seen[ad] = True;
                    roots.append(ad);
                }
            }
        }
        return roots;
    }

    def run_gc(self) -> list[str] {
        roots: list[str] = self.discover_roots();
        reach: list[str] = reachable_closure(roots, self.values);
        reach_set: dict[str, bool] = {};
        for r in reach {
            reach_set[r] = True;
        }
        evicted: list[str] = [];
        for vk in self.values.list_keys() {
            if vk not in reach_set {
                if self.values.evict(vk) {
                    evicted.append(vk);
                }
            }
        }
        return sorted(evicted);
    }
}

def reachable_closure(roots: list[str], store: ValueStore) -> list[str] {
    wk = store.hub spawn ClosureW(nodes=store.nodes, seeds=roots);
    return sorted(wk.reachable);
}

def make_value(did: str) -> Value {
    return Value(did=did);
}

def link(parent: Value, child: Value) {
    parent +>:Dep:+> child;
}

def make_store -> ValueStore {
    hub = GraphHub();
    root ++> hub;
    vs = ValueStore();
    vs.hub = hub;
    return vs;
}

def make_cache(vals: ValueStore) -> Cache {
    hub = GraphHub();
    root ++> hub;
    ca = Cache();
    ca.hub = hub;
    ca.values = vals;
    return ca;
}

def add_call(cache: Cache, cid: str, res: str, args: list[str] | None) {
    digs: list[str] = [];
    if args != None {
        for a in args {
            digs.append(a);
        }
    }
    cache.calls[cid] = CallRec(cid=cid, result_did=res, arg_digs=digs);
}

test "closure_linear_chain" {
    store = make_store();
    a = make_value("a");
    b = make_value("b");
    c = make_value("c");
    store.add(a);
    store.add(b);
    store.add(c);
    link(a, b);
    link(b, c);
    got = reachable_closure(["a"], store);
    assert got == ["a", "b", "c"];
}

test "closure_unknown_seed_included" {
    store = make_store();
    a = make_value("a");
    store.add(a);
    got = reachable_closure(["a", "missing"], store);
    assert got == ["a", "missing"];
}

test "closure_cycle_skips_revisit" {
    store = make_store();
    a = make_value("a");
    b = make_value("b");
    store.add(a);
    store.add(b);
    link(a, b);
    link(b, a);
    got = reachable_closure(["a"], store);
    assert got == ["a", "b"];
}

test "closure_diamond_adversarial_order" {
    store = make_store();
    root_v = make_value("r");
    left_v = make_value("l");
    right_v = make_value("rt");
    join_v = make_value("j");
    store.add(root_v);
    store.add(left_v);
    store.add(right_v);
    store.add(join_v);
    link(root_v, right_v);
    link(root_v, left_v);
    link(left_v, join_v);
    link(right_v, join_v);
    got = reachable_closure(["r"], store);
    assert got == ["j", "l", "r", "rt"];
}

test "gc_evicts_unreachable_values" {
    store = make_store();
    a = make_value("a");
    b = make_value("b");
    orphan = make_value("orphan");
    store.add(a);
    store.add(b);
    store.add(orphan);
    link(a, b);
    cache = make_cache(store);
    add_call(cache, "c1", "a", None);
    evicted = cache.run_gc();
    assert evicted == ["orphan"];
    assert store.list_keys() == ["a", "b"];
}

test "gc_preserves_call_roots" {
    store = make_store();
    a = make_value("a");
    b = make_value("b");
    store.add(a);
    store.add(b);
    link(a, b);
    cache = make_cache(store);
    add_call(cache, "c1", "b", ["a"]);
    evicted = cache.run_gc();
    assert evicted == [];
    assert store.list_keys() == ["a", "b"];
}
