"""KronicDeth/intellij-elixir#3928 — wire mix deps into dependency resolution."""

node ManifestNode {
    has name: str;
}

edge Declares {}

walker TransitResolveWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_manifest with ManifestNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        print("transitive", here.name);
        kids: list[ManifestNode] = [here ->:Declares:->][?:ManifestNode];
        visit :0: kids;
    }
}

def parse_dep_name(line: str) -> tuple[str, str] {
    name: str = "";
    tool: str = "hex";
    if line == "" {
        return (name, tool);
    }
    parts: list[str] = line.split(" ");
    if len(parts) > 0 {
        name = parts[0];
    }
    if "(rebar3)" in line {
        tool = "rebar3";
    } elif "(git)" in line {
        tool = "git";
    } elif "(path)" in line {
        tool = "path";
    } elif "(Hex package)" in line {
        tool = "hex";
    }
    return (name, tool);
}

def build_manifest_graph(adj: dict[str, list[str]]) -> dict[str, ManifestNode] {
    names: dict[str, bool] = {};
    for parent in adj {
        names[parent] = True;
        kids: list[str] = adj[parent];
        for kid_name in kids {
            names[kid_name] = True;
        }
    }
    store: dict[str, ManifestNode] = {};
    for nm in names {
        nd = ManifestNode(name=nm);
        root ++> nd;
        store[nm] = nd;
    }
    for parent in adj {
        parent_nd = store[parent] as ManifestNode;
        kids: list[str] = adj[parent];
        for kid_name in kids {
            kid_nd = store[kid_name] as ManifestNode;
            parent_nd +>: Declares:+> kid_nd;
        }
    }
    return store;
}

def transitively_resolve(adj: dict[str, list[str]], start: str) -> list[str] {
    store = build_manifest_graph(adj);
    if start not in store {
        return [];
    }
    start_nd = store[start] as ManifestNode;
    w = start_nd spawn TransitResolveWalker(claimed={});
    return sorted(w.found);
}

def union_dep_names(locked: list[str], walked: list[str]) -> list[str] {
    seen: dict[str, bool] = {};
    out: list[str] = [];
    for n in locked {
        if n not in seen {
            seen[n] = True;
            out.append(n);
        }
    }
    for n in walked {
        if n not in seen {
            seen[n] = True;
            out.append(n);
        }
    }
    return sorted(out);
}

def dep_path_for(name: str, build_tool: str) -> str {
    if build_tool == "path" {
        return name;
    }
    if build_tool == "module" {
        return name;
    }
    return "deps/" + name;
}

def cached_mix_deps(cache: dict[str, list[str]] | None, root_key: str, fallback_lines: list[str]) -> list[str] {
    if cache != None and root_key in cache {
        return sorted(cache[root_key]);
    }
    seen: dict[str, bool] = {};
    out: list[str] = [];
    for ln in fallback_lines {
        pair = parse_dep_name(ln);
        nm = pair[0];
        if nm != "" and nm not in seen {
            seen[nm] = True;
            out.append(nm);
        }
    }
    return sorted(out);
}

def build_module_deps_plan(mix_lines: list[str], adj: dict[str, list[str]], manifest_root: str) -> list[str] {
    locked: list[str] = [];
    seen_locked: dict[str, bool] = {};
    for ln in mix_lines {
        pair = parse_dep_name(ln);
        nm = pair[0];
        if nm != "" and nm not in seen_locked {
            seen_locked[nm] = True;
            locked.append(nm);
        }
    }
    walked = transitively_resolve(adj, manifest_root);
    return union_dep_names(locked, walked);
}
