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
