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
