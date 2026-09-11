"""openSUSE/docbuild#447 — dependency-aware DAPS metadata cache."""

node Deliverable {
    has path: str;
}

edge Includes {}

walker DepsWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Deliverable entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.path != self.origin {
            self.found.append(here.path);
        }
        visit [->:Includes:->][?:Deliverable];
    }
}

def _find_deliverable(path: str) -> Deliverable | None {
    for nd in [root -->][?:Deliverable] {
        if nd.path == path { return nd; }
    }
    return None;
}

def _has_include(from_nd: Deliverable, to_nd: Deliverable) -> bool {
    for k in [from_nd ->:Includes:->][?:Deliverable] {
        if k.path == to_nd.path { return True; }
    }
    return False;
}

def make_store(
    includes: list[tuple[str, str]],
    fingerprints: dict[str, str],
    records: dict[str, dict] | None = None,
) -> dict {
    adj: dict[str, list[str]] = {};
    for (parent, child) in includes {
        adj.setdefault(parent, []);
        adj.setdefault(child, []);
        if child not in adj[parent] {
            adj[parent].append(child);
        }
    }
    for path in fingerprints {
        adj.setdefault(path, []);
    }
    for path in adj.keys() {
        nd = _find_deliverable(path);
        if nd is None {
            nd = Deliverable(path=path);
            root ++> nd;
        }
    }
    for (parent, child) in includes {
        p = _find_deliverable(parent);
        c = _find_deliverable(child);
        if p is not None and c is not None and not _has_include(p, c) {
            p +>:Includes:+> c;
        }
    }
    recs = dict(records) if records is not None else {};
    return {
        "adj": adj,
        "fingerprints": dict(fingerprints),
        "records": recs,
        "_memo": {},
    };
}

def transitive_deps(store: dict, deliverable_id: str) -> list[str] {
    memo = store["_memo"] as dict[str, list[str]];
    if deliverable_id in memo {
        out: list[str] = [];
        for x in memo[deliverable_id] { out.append(x); }
        return out;
    }
    adj = store["adj"] as dict[str, list[str]];
    if deliverable_id not in adj {
        memo[deliverable_id] = [];
        return [];
    }
    nd = _find_deliverable(deliverable_id);
    if nd is None {
        memo[deliverable_id] = [];
        return [];
    }
    w = nd spawn DepsWalk(claimed={}, found=[], origin=deliverable_id);
    result = sorted(w.found);
    memo[deliverable_id] = result;
    out2: list[str] = [];
    for x in result { out2.append(x); }
    return out2;
}

def dependency_fingerprint(store: dict, deliverable_id: str) -> str {
    deps = transitive_deps(store, deliverable_id);
    parts: list[str] = [];
    fps = store["fingerprints"] as dict[str, str];
    for path in deps {
        if path in fps {
            parts.append(f"{path}:{fps[path]}");
        }
    }
    return "|".join(sorted(parts));
}

def get_cached_metadata(store: dict, deliverable_id: str) -> dict | None {
    records = store["records"] as dict[str, dict];
    rec = records.get(deliverable_id, None);
    if rec is None { return None; }
    if rec.get("fingerprint", None) != dependency_fingerprint(store, deliverable_id) {
        return None;
    }
    meta = rec["metadata"] as dict;
    return {**meta};
}

def resolve_metadata(
    store: dict,
    deliverable_id: str,
    runner: Callable[[str], dict],
) -> dict {
    adj = store["adj"] as dict[str, list[str]];
    if deliverable_id not in adj {
        raise KeyError(deliverable_id);
    }
    fp = dependency_fingerprint(store, deliverable_id);
    records = store["records"] as dict[str, dict];
    rec = records.get(deliverable_id, None);
    if rec is not None and rec.get("fingerprint", None) == fp {
        meta_hit = rec["metadata"] as dict;
        return {**meta_hit};
    }
    meta = runner(deliverable_id);
    deps = transitive_deps(store, deliverable_id);
    fp = dependency_fingerprint(store, deliverable_id);
    meta_copy: dict = {};
    for (k, v) in meta.items() { meta_copy[k] = v; }
    deps_copy: list[str] = [];
    for d in deps { deps_copy.append(d); }
    records[deliverable_id] = {
        "metadata": meta_copy,
        "deps": deps_copy,
        "fingerprint": fp,
    };
    out: dict = {};
    for (k, v) in meta.items() { out[k] = v; }
    return out;
}

def list_deliverables(store: dict) -> list[str] {
    records = store["records"] as dict[str, dict];
    keys: list[str] = [];
    for k in records.keys() { keys.append(k); }
    return sorted(keys);
}

def invalidate_cache(store: dict, deliverable_id: str) -> bool {
    records = store["records"] as dict[str, dict];
    if deliverable_id not in records {
        return False;
    }
    del records[deliverable_id];
    memo = store["_memo"] as dict[str, list[str]];
    if deliverable_id in memo {
        del memo[deliverable_id];
    }
    return True;
}
