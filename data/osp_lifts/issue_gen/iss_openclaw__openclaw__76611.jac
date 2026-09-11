"""openclaw/openclaw#76611 — Matrix crypto-store deferred persist."""

obj CryptoStore { has stamp: int = 0; }

node KeyPath { has key: str; has dirty: bool = False; has persisted: bool = False; }
edge Child {}

def _find(key: str) -> KeyPath | None {
    for k in [-->][?:KeyPath] { if k.key == key { return k; } }
    return None;
}

def load_crypto_store(edges: list[tuple[str, str]]) -> CryptoStore {
    mp: dict[str, KeyPath] = {};
    for (parent, child) in edges {
        for k in [parent, child] {
            if k not in mp { nd = KeyPath(key=k); root ++> nd; mp[k] = nd; }
        }
        p = mp.get(parent, None); c = mp.get(child, None);
        if p is not None and c is not None { p +>:Child:+> c; }
    }
    return CryptoStore(stamp=1);
}

walker AncestorMark {
    has targets: list[KeyPath] = [];
    can step with KeyPath entry {
        self.targets.append(here);
        parents = [here <-:Child:<-][?:KeyPath];
        if parents { visit parents; } else { disengage; }
    }
}

def mark_dirty(g: CryptoStore, key: str) -> None {
    _ = g;
    n = _find(key);
    if n is None { return; }
    n.dirty = True;
    w = n spawn AncestorMark();
    for t in w.targets { t.dirty = True; }
}

def pending_persist(g: CryptoStore) -> list[str] {
    _ = g;
    out: list[str] = [];
    for k in [-->][?:KeyPath] {
        if k.dirty and not k.persisted { out.append(k.key); }
    }
    return sorted(out);
}

walker FlushCollect {
    has claimed: dict[str, bool] = {};
    has targets: list[KeyPath] = [];
    can step with KeyPath entry {
        if not here.dirty { disengage; }
        if here.key in self.claimed { skip; }
        self.claimed[here.key] = True;
        self.targets.append(here);
        visit [->:Child:->][?:KeyPath] else { disengage; };
    }
}

def flush_dirty(g: CryptoStore) -> list[str] {
    _ = g;
    flushed: list[str] = [];
    for seed in [-->][?:KeyPath] {
        if not seed.dirty { continue; }
        w = seed spawn FlushCollect(claimed={}, targets=[]);
        for t in w.targets {
            if t.dirty {
                t.persisted = True;
                t.dirty = False;
                flushed.append(t.key);
            }
        }
    }
    return sorted(set(flushed));
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can step with KeyPath entry {
        if here.key in self.claimed { skip; }
        self.claimed[here.key] = True;
        self.reached.append(here.key);
        visit [->:Child:->] else { disengage; };
    }
}

def reachable_keys(g: CryptoStore, root_key: str) -> list[str] {
    _ = g;
    anchor = _find(root_key);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}
