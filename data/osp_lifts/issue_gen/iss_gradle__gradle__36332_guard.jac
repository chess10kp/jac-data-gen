"""gradle/gradle#36332 — slow eachElement() traversal per dependency during CC serialisation.

Idiomatic OSP lift: one cached BFS-style walk fills a per-module version map,
so maybe_resolve_version never re-traverses the dependency graph.
Specs map module id -> [version, dep_id, dep_id, ...]."""

node Module {
    has cid: str;
    has version: str = "";
    has cache: dict[str, str] = {};
}

edge Depends {
    has constraint: str = "";
}

walker Seed {
    can start with Module entry {
        root ++> here;
        print("seeded " + here.cid);
        disengage;
    }
}

walker ResolveVersions {
    has claimed: dict[str, bool] = {};
    can step with Module entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        here.cache[here.cid] = here.version;
        for nxt in [here ->:Depends:->][?:Module] {
            here.cache[nxt.cid] = nxt.version;
        }
        visit [here ->:Depends:->][?:Module];
    }
}

def build_graph(specs: dict[str, list[str]]) -> Module {
    nodes: dict[str, Module] = {};
    for cid in specs.keys() {
        spec: list[str] = specs[cid];
        nodes[cid] = Module(cid=cid, version=spec[0]);
    }
    for cid in specs.keys() {
        spec: list[str] = specs[cid];
        i: int = 1;
        while i < len(spec) {
            dep: str = spec[i];
            if dep in nodes.keys() {
                nodes[cid] +>:Depends:+> nodes[dep];
            }
            i += 1;
        }
    }
    first: str = sorted(specs.keys())[0];
    entry: Module = nodes[first];
    entry spawn Seed();
    return entry;
}

def maybe_resolve_version(entry: Module, dep_id: str) -> str {
    if dep_id not in entry.cache.keys() {
        entry spawn ResolveVersions(claimed={});
    }
    if dep_id in entry.cache.keys() {
        return entry.cache[dep_id];
    }
    return "unknown";
}

def version_map(entry: Module) -> dict[str, str] {
    if len(entry.cache.keys()) == 0 {
        entry spawn ResolveVersions(claimed={});
    }
    out: dict[str, str] = {};
    for k in entry.cache.keys() {
        out[k] = entry.cache[k];
    }
    return out;
}

test "resolves all versions in one cached walk" {
    specs: dict[str, list[str]] = {
        "app": ["2.0", "lib-core", "lib-util"],
        "lib-core": ["1.1"],
        "lib-util": ["1.3"]
    };
    entry: Module = build_graph(specs);
    assert maybe_resolve_version(entry, "lib-core") == "1.1";
    assert maybe_resolve_version(entry, "lib-util") == "1.3";
    assert version_map(entry)["app"] == "2.0";
}

test "diamond graph revisits skipped via claim map" {
    specs: dict[str, list[str]] = {
        "a": ["1.0", "b", "c"],
        "b": ["1.1", "d"],
        "c": ["1.2", "d"],
        "d": ["1.4"]
    };
    entry: Module = build_graph(specs);
    m: dict[str, str] = version_map(entry);
    assert len(m.keys()) == 4;
    assert m["d"] == "1.4";
    assert m["c"] == "1.2";
}

test "unknown id tolerated" {
    specs: dict[str, list[str]] = {"solo": ["0.9"]};
    entry: Module = build_graph(specs);
    assert maybe_resolve_version(entry, "nope") == "unknown";
    assert maybe_resolve_version(entry, "solo") == "0.9";
}

test "empty dependency list" {
    specs: dict[str, list[str]] = {"lonely": ["5.5"]};
    entry: Module = build_graph(specs);
    m: dict[str, str] = version_map(entry);
    assert len(m.keys()) == 1;
}

test "cache persists across calls" {
    specs: dict[str, list[str]] = {
        "root": ["1.0", "x", "y"],
        "x": ["2.0"],
        "y": ["3.0", "x"]
    };
    entry: Module = build_graph(specs);
    assert maybe_resolve_version(entry, "x") == "2.0";
    assert maybe_resolve_version(entry, "y") == "3.0";
    m2: dict[str, str] = version_map(entry);
    assert m2["x"] == "2.0";
}
