"""nuxt-contrib/vue-bundle-renderer#398 — precomputeDependencies style closure under import cycles."""

node Chunk {
    has cid: str;
    has file: str = "";
    has resource_type: str = "script";
    has css_ids: list[str] = [];
}

edge Imports {}

node GraphHub {
    has by_id: dict[str, Chunk] = {};
}

walker DepStyleWalk {
    has claimed: dict[str, bool] = {};
    has styles: dict[str, bool] = {};

    can walk with Chunk entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        for css_id in here.css_ids {
            self.styles[css_id] = True;
        }
        kids: list[Chunk] = [];
        for ch in [here ->:Imports:->][?:Chunk] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        };
        print(here.cid, len(self.styles));
    }
}

def empty_dep_bundle() -> dict {
    scripts: dict[str, bool] = {};
    styles: dict[str, bool] = {};
    preload: dict[str, bool] = {};
    prefetch: dict[str, bool] = {};
    return {
        "scripts": scripts,
        "styles": styles,
        "preload": preload,
        "prefetch": prefetch,
    };
}

def build_graph(manifest: dict) -> GraphHub {
    hub = GraphHub(by_id={});
    for cid in manifest {
        meta = manifest[cid] as dict;
        file_name: str = "";
        if "file" in meta {
            file_name = str(meta["file"]);
        }
        rtype: str = "script";
        if "resourceType" in meta {
            rtype = str(meta["resourceType"]);
        }
        css_ids: list[str] = [];
        if "css" in meta {
            raw_css = meta["css"] as list;
            for item in raw_css {
                css_ids.append(str(item));
            }
        }
        nd = Chunk(
            cid=str(cid),
            file=file_name,
            resource_type=rtype,
            css_ids=css_ids,
        );
        hub.by_id[str(cid)] = nd;
        root ++> nd;
    }
    for cid in manifest {
        meta = manifest[cid] as dict;
        if "imports" not in meta {
            continue;
        }
        src = hub.by_id[str(cid)];
        imports_list = meta["imports"] as list;
        for imp in imports_list {
            imp_id = str(imp);
            if imp_id in hub.by_id {
                dst = hub.by_id[imp_id];
                src +>:Imports:+> dst;
            }
        }
    }
    return hub;
}

def styles_for_chunk(hub: GraphHub, cid: str) -> dict[str, bool] {
    if cid not in hub.by_id {
        return {};
    }
    start = hub.by_id[cid];
    w = start spawn DepStyleWalk(claimed={}, styles={});
    return w.styles;
}

def precompute_dependencies(manifest: dict) -> dict {
    hub = build_graph(manifest);
    dependencies: dict = {};
    for mid in manifest {
        bundle = empty_dep_bundle();
        collected = styles_for_chunk(hub, str(mid));
        slot = bundle["styles"] as dict[str, bool];
        for sk in collected {
            slot[str(sk)] = True;
        }
        dependencies[str(mid)] = bundle;
    }
    return {"dependencies": dependencies};
}

test "cycle_key_order_a_shared_b" {
    manifest: dict = {};
    manifest["a.js"] = {
        "file": "a.js",
        "resourceType": "script",
        "imports": ["_shared.js"],
    };
    manifest["_shared.js"] = {
        "file": "shared.js",
        "resourceType": "script",
        "css": ["shared.css"],
        "imports": ["b.js"],
    };
    manifest["b.js"] = {
        "file": "b.js",
        "resourceType": "script",
        "imports": ["a.js"],
    };
    manifest["shared.css"] = {
        "file": "shared.css",
        "resourceType": "style",
    };
    out = precompute_dependencies(manifest);
    deps = out["dependencies"] as dict;
    b_styles = deps["b.js"]["styles"] as dict;
    keys: list[str] = [];
    for k in b_styles {
        keys.append(str(k));
    }
    assert (sorted(keys) == ["shared.css"]);
}

test "cycle_key_order_b_a_shared" {
    manifest: dict = {};
    manifest["b.js"] = {
        "file": "b.js",
        "resourceType": "script",
        "imports": ["a.js"],
    };
    manifest["a.js"] = {
        "file": "a.js",
        "resourceType": "script",
        "imports": ["_shared.js"],
    };
    manifest["_shared.js"] = {
        "file": "shared.js",
        "resourceType": "script",
        "css": ["shared.css"],
        "imports": ["b.js"],
    };
    manifest["shared.css"] = {
        "file": "shared.css",
        "resourceType": "style",
    };
    out = precompute_dependencies(manifest);
    deps = out["dependencies"] as dict;
    for cid in ["a.js", "_shared.js", "b.js"] {
        styles = deps[cid]["styles"] as dict;
        keys: list[str] = [];
        for k in styles {
            keys.append(str(k));
        }
        assert (sorted(keys) == ["shared.css"]);
    }
}

test "diamond_revisit_before_deep_first_visit" {
    manifest: dict = {};
    manifest["d0.js"] = {
        "file": "d0.js",
        "resourceType": "script",
        "imports": ["d2.js", "d1.js"],
    };
    manifest["d1.js"] = {
        "file": "d1.js",
        "resourceType": "script",
        "imports": ["d3.js"],
    };
    manifest["d2.js"] = {
        "file": "d2.js",
        "resourceType": "script",
        "imports": ["d3.js"],
    };
    manifest["d3.js"] = {
        "file": "d3.js",
        "resourceType": "script",
        "css": ["d.css"],
        "imports": [],
    };
    out = precompute_dependencies(manifest);
    deps = out["dependencies"] as dict;
    d0_styles = deps["d0.js"]["styles"] as dict;
    keys: list[str] = [];
    for k in d0_styles {
        keys.append(str(k));
    }
    assert (sorted(keys) == ["d.css"]);
}

test "unknown_import_id_tolerated" {
    manifest: dict = {};
    manifest["lonely.js"] = {
        "file": "lonely.js",
        "resourceType": "script",
        "imports": ["missing.js"],
    };
    out = precompute_dependencies(manifest);
    deps = out["dependencies"] as dict;
    assert ("lonely.js" in deps);
    lonely = deps["lonely.js"] as dict;
    styles = lonely["styles"] as dict;
    assert (len(styles) == 0);
}

test "parent_styles_superset_of_each_import" {
    manifest: dict = {};
    manifest["a.js"] = {
        "file": "a.js",
        "resourceType": "script",
        "imports": ["_shared.js"],
    };
    manifest["_shared.js"] = {
        "file": "shared.js",
        "resourceType": "script",
        "css": ["shared.css"],
        "imports": ["b.js"],
    };
    manifest["b.js"] = {
        "file": "b.js",
        "resourceType": "script",
        "imports": ["a.js"],
    };
    manifest["shared.css"] = {
        "file": "shared.css",
        "resourceType": "style",
    };
    out = precompute_dependencies(manifest);
    deps = out["dependencies"] as dict;
    for cid in ["a.js", "_shared.js", "b.js"] {
        parent_styles = deps[cid]["styles"] as dict;
        meta = manifest[cid] as dict;
        imports_list = meta["imports"] as list;
        for imp in imports_list {
            imp_id = str(imp);
            child_styles = deps[imp_id]["styles"] as dict;
            child_keys: list[str] = [];
            for ck in child_styles {
                child_keys.append(str(ck));
            }
            for ck in child_keys {
                assert (ck in parent_styles);
            }
        }
    }
}
