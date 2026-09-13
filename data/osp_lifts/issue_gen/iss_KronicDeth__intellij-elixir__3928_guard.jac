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

test "diamond_revisit_claim_skip" {
    adj: dict[str, list[str]] = {
        "app": ["left", "right"],
        "left": ["shared"],
        "right": ["shared"],
    };
    got = transitively_resolve(adj, "app");
    assert got == ["app", "left", "right", "shared"];;
}

test "mix_deps_union_rebar3_tier" {
    mix_lines: list[str] = [
        "hackney 1.17.0 (Hex package) (rebar3)",
        "certifi 2.12.0 (Hex package) (rebar3)",
        "metrics 1.0.1 (Hex package) (rebar3)",
    ];
    adj: dict[str, list[str]] = {
        "app": ["hackney", "idna"],
        "hackney": ["idna"],
    };
    plan = build_module_deps_plan(mix_lines, adj, "app");
    assert plan == ["app", "certifi", "hackney", "idna", "metrics"];;
}

test "unknown_manifest_root_tolerance" {
    adj: dict[str, list[str]] = {"app": ["plug"]};
    walked = transitively_resolve(adj, "missing_root");
    plan = build_module_deps_plan(["plug 1.0.0 (Hex package)"], adj, "missing_root");
    assert walked == [];;
    assert plan == ["plug"];;
}

test "declared_unfetched_kept_in_union" {
    adj: dict[str, list[str]] = {
        "app": ["new_dep"],
        "new_dep": [],
    };
    plan = build_module_deps_plan([], adj, "app");
    assert plan == ["app", "new_dep"];;
}

test "cached_mix_deps_read_not_await" {
    cache: dict[str, list[str]] = {"phoenix_root": ["cowboy", "plug"]};
    got = cached_mix_deps(cache, "phoenix_root", ["ignored 0.0.0 (Hex package)"]);
    assert got == ["cowboy", "plug"];;
}

test "dep_path_for_build_tools" {
    assert dep_path_for("hackney", "rebar3") == "deps/hackney";;
    assert dep_path_for("../vendor/foo", "path") == "../vendor/foo";;
    pair = parse_dep_name("ssl_verify_fun 1.1.7 (Hex package) (rebar3)");
    assert pair == ("ssl_verify_fun", "rebar3");;
}
