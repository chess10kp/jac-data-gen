"""CachedFunctionPod dangling-ref invalidation.
Provenance: nauticalab/orcapod-python#249
"""

glob root;

node Artifact {
    has path: str;
    has exists: bool = True;
}

node CacheEntry {
    has input_hash: str;
    has entry_id: str;
}

node Pod {
    has name: str;
    has verify_output_exists: bool = False;
}

node CacheGraph {
    has graph_id: str;
    has pod_by_name: dict[str, Pod] = {};
    has entry_key: dict[str, CacheEntry] = {};
    has art_by_path: dict[str, Artifact] = {};
}

edge Refs {}

walker VerifyOutputs {
    has claimed: dict[str, bool] = {};
    has ok: bool = True;

    can step_entry with CacheEntry entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("verify entry ", here.entry_id);
        outs: list = [here ->:Refs:->][?:Artifact];
        for ch in outs {
            visit ch;
        }
    }

    can step_art with Artifact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("verify art ", here.path);
        if not here.exists {
            self.ok = False;
        }
        deps: list = [here ->:Refs:->][?:Artifact];
        for dep in deps {
            visit dep;
        }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};

    can start with ? entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        g = create_cache_graph();
        register_pod(g, "preprocess", verify_output_exists=True);
        write_cache(g, "preprocess", "h1", ["/cache/x"]);
        hit = lookup(g, "preprocess", "h1");
        print(hit);
        delete_path(g, "/cache/x");
        miss = lookup(g, "preprocess", "h1");
        print(miss);
    }
}

def create_cache_graph() -> CacheGraph {
    g = CacheGraph(graph_id="cg0");
    root ++> g;
    return g;
}

def register_pod(g: CacheGraph, pod_name: str, verify_output_exists: bool = False) -> Pod {
    p = Pod(name=pod_name, verify_output_exists=verify_output_exists);
    g.pod_by_name[pod_name] = p;
    g ++> p;
    return p;
}

def ensure_artifact(g: CacheGraph, path: str) -> Artifact {
    if path in g.art_by_path {
        return g.art_by_path[path];
    }
    art = Artifact(path=path, exists=True);
    g.art_by_path[path] = art;
    g ++> art;
    return art;
}

def write_cache(g: CacheGraph, pod_name: str, input_hash: str, output_paths: list[str]) -> str {
    if pod_name not in g.pod_by_name {
        return "";
    }
    key = pod_name + ":" + input_hash;
    if key in g.entry_key {
        ent = g.entry_key[key];
        return ent.entry_id;
    }
    eid = "ent-" + input_hash;
    ent = CacheEntry(input_hash=input_hash, entry_id=eid);
    g.entry_key[key] = ent;
    g ++> ent;
    pod = g.pod_by_name[pod_name];
    pod ++> ent;
    for p in output_paths {
        art = ensure_artifact(g, p);
        ent +>:Refs:+> art;
    }
    return eid;
}

def delete_path(g: CacheGraph, path: str) -> bool {
    if path not in g.art_by_path {
        return False;
    }
    g.art_by_path[path].exists = False;
    return True;
}

def lookup(g: CacheGraph, pod_name: str, input_hash: str, verify_output_exists: bool | None = None) -> dict | None {
    if pod_name not in g.pod_by_name {
        return None;
    }
    key = pod_name + ":" + input_hash;
    if key not in g.entry_key {
        return None;
    }
    ent = g.entry_key[key];
    pod = g.pod_by_name[pod_name];
    do_verify = pod.verify_output_exists;
    if verify_output_exists is not None {
        do_verify = verify_output_exists;
    }
    if do_verify {
        w = ent spawn VerifyOutputs(claimed={});
        if not w.ok {
            print("cache miss dangling refs for ", input_hash);
            return None;
        }
    }
    paths: list[str] = [];
    outs: list = [ent ->:Refs:->][?:Artifact];
    for art in outs {
        paths.append(art.path);
    }
    paths = sorted(paths);
    return {"entry_id": ent.entry_id, "paths": paths, "from_cache": True};
}

def link_artifacts(g: CacheGraph, links: list[list[str]]) {
    for pair in links {
        src = pair[0];
        dst = pair[1];
        a = ensure_artifact(g, src);
        b = ensure_artifact(g, dst);
        a +>:Refs:+> b;
    }
}

with entry {
    root spawn DemoWalker;
}

test "hit_when_outputs_exist" {
    g = create_cache_graph();
    register_pod(g, "preprocess", verify_output_exists=True);
    write_cache(g, "preprocess", "h1", ["/cache/x"]);
    r = lookup(g, "preprocess", "h1");
    assert (r is not None);;
    assert (r["from_cache"] == True);;
    assert (r["paths"] == ["/cache/x"]);;
}

test "dangling_ref_invalidates_hit" {
    g = create_cache_graph();
    register_pod(g, "preprocess", verify_output_exists=True);
    write_cache(g, "preprocess", "h1", ["/cache/x"]);
    delete_path(g, "/cache/x");
    r = lookup(g, "preprocess", "h1");
    assert (r is None);;
}

test "verify_off_allows_dangling" {
    g = create_cache_graph();
    register_pod(g, "preprocess", verify_output_exists=False);
    write_cache(g, "preprocess", "h2", ["/cache/y"]);
    delete_path(g, "/cache/y");
    r = lookup(g, "preprocess", "h2");
    assert (r is not None);;
    assert (r["paths"] == ["/cache/y"]);;
}

test "diamond_shared_ref_revisit" {
    g = create_cache_graph();
    register_pod(g, "preprocess", verify_output_exists=True);
    write_cache(g, "preprocess", "dh", ["/left", "/right"]);
    link_artifacts(g, [["/left", "/shared"], ["/right", "/shared"]]);
    r = lookup(g, "preprocess", "dh");
    assert (r is not None);;
    delete_path(g, "/shared");
    miss = lookup(g, "preprocess", "dh");
    assert (miss is None);;
}

test "lookup_unknown_pod" {
    g = create_cache_graph();
    r = lookup(g, "missing_pod", "h0");
    assert (r is None);;
}

test "delete_unknown_path" {
    g = create_cache_graph();
    ok = delete_path(g, "/does_not_exist");
    assert (ok == False);;
}
