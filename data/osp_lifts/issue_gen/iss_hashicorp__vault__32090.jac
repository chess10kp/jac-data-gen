"""hashicorp/vault#32090 — bounded KV mount LIST scan vs counter endpoint billing."""

glob DEFAULT_LIST_CAP = 500;
glob MODE_LIST = "list";
glob MODE_ENDPOINT = "endpoint";

node KvMount {
    has mid: str;
}

node KvSecret {
    has sid: str;
}

edge MountHas {}
edge SecretChild {}

walker ListCountWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has list_calls: int = 0;
    has list_cap: int = 0;
    has truncated: bool = False;

    can step with KvSecret entry {
        if here.sid in self.claimed { skip; }
        if self.list_cap > 0 and self.list_calls >= self.list_cap {
            self.truncated = True;
            disengage;
        }
        self.claimed[here.sid] = True;
        self.order.append(here.sid);
        self.list_calls += 1;
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: KvSecret) -> list[KvSecret] {
    kids: list[KvSecret] = [];
    for ch in [nd ->:SecretChild:->][?:KvSecret] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.sid); }
    names = sorted(names);
    ordered: list[KvSecret] = [];
    for nm in names { for ch in kids { if ch.sid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_mount(mid: str, store: dict) -> KvMount | None {
    mmap = store["mount_nodes"] as dict[str, KvMount];
    if mid in mmap { return mmap[mid]; }
    return None;
}

def _find_secret(sid: str, store: dict) -> KvSecret | None {
    nmap = store["nodes"] as dict[str, KvSecret];
    if sid in nmap { return nmap[sid]; }
    return None;
}

def fresh_vault_store() -> dict {
    return {"mounts": {}, "secrets": {}, "deps": {}, "nodes": {}, "mount_nodes": {}, "roots": {}, "counters": {}};
}

def register_mount(mid: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_vault_store(); }
    (s["mounts"] as dict[str, bool])[mid] = True;
    roots = s["roots"] as dict[str, list[str]];
    if mid not in roots { roots[mid] = []; }
    counters = s["counters"] as dict[str, int];
    if mid not in counters { counters[mid] = 0; }
    mnd = KvMount(mid=mid);
    root ++> mnd;
    (s["mount_nodes"] as dict[str, KvMount])[mid] = mnd;
    return s;
}

def register_secret(sid: str, store: dict) -> dict {
    if sid in (store["secrets"] as dict) { return store; }
    (store["secrets"] as dict[str, bool])[sid] = True;
    deps = store["deps"] as dict[str, list[str]];
    if sid not in deps { deps[sid] = []; }
    nd = KvSecret(sid=sid);
    root ++> nd;
    (store["nodes"] as dict[str, KvSecret])[sid] = nd;
    return store;
}

def add_mount_root(mount_id: str, secret_id: str, store: dict) {
    if mount_id not in (store["mounts"] as dict) { raise KeyError(mount_id); }
    register_secret(secret_id, store);
    mnd = _find_mount(mount_id, store);
    sec_nd = _find_secret(secret_id, store);
    if mnd is not None and sec_nd is not None {
        seen = False;
        for ex in [mnd ->:MountHas:->][?:KvSecret] { if ex.sid == secret_id { seen = True; } }
        if not seen { mnd +>:MountHas:+> sec_nd; }
    }
    roots = store["roots"] as dict[str, list[str]];
    if secret_id not in roots[mount_id] { roots[mount_id].append(secret_id); roots[mount_id] = sorted(roots[mount_id]); }
}

def add_secret_child(source_id: str, target_id: str, store: dict) {
    smap = store["secrets"] as dict[str, bool];
    if source_id not in smap or target_id not in smap { raise KeyError("unknown secret id"); }
    if source_id == target_id { return; }
    src_nd = _find_secret(source_id, store);
    tgt_nd = _find_secret(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:SecretChild:->][?:KvSecret] { if ex.sid == target_id { seen = True; } }
        if not seen { src_nd +>:SecretChild:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
}

def recursive_list_count(mount_id: str, store: dict, list_cap: int = 0) -> dict {
    if mount_id not in (store["mounts"] as dict) { raise KeyError(mount_id); }
    roots = (store["roots"] as dict[str, list[str]]).get(mount_id, []);
    order: list[str] = [];
    list_calls = 0;
    truncated = False;
    for rid in roots {
        nd = _find_secret(rid, store);
        if nd is None { continue; }
        w = nd spawn ListCountWalk(claimed={}, order=[], list_calls=0, list_cap=list_cap, truncated=False);
        list_calls += w.list_calls;
        if w.truncated { truncated = True; }
        for sid in w.order { if sid not in order { order.append(sid); } }
    }
    order = sorted(order);
    return {"secrets": order, "secret_count": len(order), "list_calls": list_calls, "truncated": truncated};
}

def set_mount_counter(mount_id: str, count: int, store: dict) {
    if mount_id not in (store["mounts"] as dict) { raise KeyError(mount_id); }
    (store["counters"] as dict[str, int])[mount_id] = count;
}

def billing_report(mount_id: str, store: dict, use_endpoint: bool = False) -> dict {
    if mount_id not in (store["mounts"] as dict) { raise KeyError(mount_id); }
    if use_endpoint {
        cnt = (store["counters"] as dict[str, int]).get(mount_id, 0);
        return {"secret_count": cnt, "list_calls": 0, "mode": MODE_ENDPOINT, "truncated": False};
    }
    scan = recursive_list_count(mount_id, store, list_cap=0);
    return {"secret_count": scan["secret_count"], "list_calls": scan["list_calls"], "mode": MODE_LIST, "truncated": scan["truncated"]};
}
