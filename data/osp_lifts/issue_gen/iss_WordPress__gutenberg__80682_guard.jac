"""WordPress/gutenberg#80682 — @wordpress/scripts vulnerable build-tool dependency audit.

Hand-rolled adjacency dict + deque BFS for npm install-tree reachability,
stack-based audit-path enumeration, and declared-range drift checks against
the published changelog before patching transitive advisories.
"""

node Pkg {
    has name: str;
    has version: str = "";
}

edge Depends: Pkg --> Pkg {}

walker TransitiveWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Pkg entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        visit [->:Depends:->][?:Pkg];
    }
}

walker DepPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with Pkg entry {
        if here.name in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.name);
        if here.name == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Depends:->][?:Pkg];
        nms: list[str] = [];
        for n in kids { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in kids {
                if n.name == nm {
                    n spawn DepPathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

obj PackageGraph {
    has resolved: dict[str, str] = {};
    has deps: dict[str, list[str]] = {};
    has root_declared: dict[str, str] = {};
    has pkgs: dict[str, Pkg] = {};
}

def _adv_id(rec: dict) -> str {
    return rec["id"];
}

def load_package_graph(
    packages: list[tuple[str, str]],
    edges: list[tuple[str, str]],
    *,
    root_declared: dict[str, str] | None = None,
) -> PackageGraph {
    g = PackageGraph();
    for (name, version) in packages {
        g.resolved[name] = version;
        g.deps.setdefault(name, []);
        if name not in g.pkgs {
            nd = Pkg(name=name, version=version);
            root ++> nd;
            g.pkgs[name] = nd;
        }
    }
    for (src, dst) in edges {
        if src in g.deps and dst in g.resolved {
            g.deps[src].append(dst);
            sn = g.pkgs.get(src, None);
            dn = g.pkgs.get(dst, None);
            if sn is not None and dn is not None { sn +>:Depends:+> dn; }
        }
    }
    if root_declared is not None {
        g.root_declared = dict(root_declared);
    }
    return g;
}

def direct_dependencies(g: PackageGraph, pkg: str) -> list[str] {
    if pkg not in g.resolved { return []; }
    return sorted(g.deps.get(pkg, []));
}

def transitive_dependencies(g: PackageGraph, `root: str) -> list[str] {
    if `root not in g.resolved { return []; }
    nd = g.pkgs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn TransitiveWalk(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def dependency_paths(
    g: PackageGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in g.resolved or target not in g.resolved { return []; }
    nd = g.pkgs.get(source, None);
    if nd is None { return []; }
    w = nd spawn DepPathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def dedupe_advisory_aliases(records: list[dict]) -> list[dict] {
    groups: dict[tuple[str, ...], dict] = {};
    for rec in records {
        aliases = rec.get("aliases") or [rec["id"]];
        key = tuple(sorted(aliases));
        if key not in groups {
            groups[key] = rec;
        }
    }
    out: list[dict] = [];
    for rec in groups.values() {
        out.append(rec);
    }
    return sorted(out, key=_adv_id);
}

def reachable_vulnerability_ids(
    g: PackageGraph,
    `root: str,
    advisories: list[dict],
) -> list[str] {
    reachable: dict[str, bool] = {};
    for n in transitive_dependencies(g, `root) { reachable[n] = True; }
    reachable[`root] = True;
    blocked: list[str] = [];
    for adv in dedupe_advisory_aliases(advisories) {
        if adv.get("kind") != "vulnerability" { continue; }
        if reachable.get(adv["package"]) {
            blocked.append(adv["id"]);
        }
    }
    return sorted(blocked);
}

def changelog_declared_drift(
    g: PackageGraph,
    `root: str,
    changelog_declared: dict[str, str],
) -> list[str] {
    if `root not in g.resolved { return []; }
    drifted: list[str] = [];
    for dep in sorted(g.deps.get(`root, [])) {
        actual = g.root_declared.get(dep, "");
        expected = changelog_declared.get(dep, "");
        if expected and actual != expected {
            drifted.append(dep);
        }
    }
    return drifted;
}

test "diamond revisit transitive closure" {
    g = load_package_graph(
        [("root", "1.0.0"), ("left", "1.0.0"), ("right", "1.0.0"), ("join", "2.0.0")],
        [("root", "left"), ("root", "right"), ("left", "join"), ("right", "join")],
    );
    assert transitive_dependencies(g, "root") == ["join", "left", "right"];
    assert transitive_dependencies(g, "join") == [];
    assert direct_dependencies(g, "root") == ["left", "right"];
}

test "unknown id and phantom edge tolerance" {
    g = load_package_graph([("only", "1.0.0")], []);
    assert transitive_dependencies(g, "missing") == [];
    assert direct_dependencies(g, "missing") == [];
    assert dependency_paths(g, "only", "ghost") == [];
    assert dependency_paths(g, "ghost", "only") == [];
    assert changelog_declared_drift(g, "missing", {"only": "^1.0.0"}) == [];
    g2 = load_package_graph(
        [("only", "1.0.0")],
        [("only", "phantom"), ("phantom", "only")],
    );
    assert direct_dependencies(g2, "only") == [];
    assert transitive_dependencies(g2, "only") == [];
    assert g2.deps["only"] == [];
}

test "dependency paths diamond enumeration" {
    g = load_package_graph(
        [("a", "1.0.0"), ("b", "1.0.0"), ("c", "1.0.0"), ("d", "1.0.0")],
        [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
    );
    assert dependency_paths(g, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]];
    assert dependency_paths(g, "d", "a") == [];
}

test "dependency paths cycle depth and self" {
    g = load_package_graph(
        [("a", "1.0.0"), ("b", "1.0.0"), ("c", "1.0.0")],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert dependency_paths(g, "a", "a") == [["a"]];
    assert dependency_paths(g, "a", "c", max_depth=2) == [];
    assert dependency_paths(g, "a", "c", max_depth=3) == [["a", "b", "c"]];
    assert transitive_dependencies(g, "a") == ["b", "c"];
}

test "advisory alias dedupe and reachable filter" {
    g = load_package_graph(
        [("root-pkg", "1.0.0"), ("dep", "2.0.0"), ("orphan", "3.0.0")],
        [("root-pkg", "dep")],
    );
    advisories = [
        {"id": "ADV-root", "kind": "vulnerability", "package": "root-pkg"},
        {"id": "ADV-dep", "kind": "vulnerability", "package": "dep"},
        {"id": "ADV-orphan", "kind": "vulnerability", "package": "orphan"},
        {"id": "ADV-note", "kind": "advisory", "package": "dep"},
        {"id": "ADV-dup-b", "aliases": ["CVE-9"], "kind": "vulnerability", "package": "dep"},
        {"id": "ADV-dup-a", "aliases": ["CVE-9"], "kind": "vulnerability", "package": "dep"},
    ];
    deduped = dedupe_advisory_aliases(advisories);
    assert len(deduped) == 5;
    ids: list[str] = [];
    for rec in deduped { ids.append(rec["id"]); }
    assert ids == ["ADV-dep", "ADV-dup-b", "ADV-note", "ADV-orphan", "ADV-root"];
    assert reachable_vulnerability_ids(g, "root-pkg", advisories) == ["ADV-dep", "ADV-dup-b", "ADV-root"];
}

test "changelog declared drift direct deps only" {
    g = load_package_graph(
        [("root-pkg", "1.0.0"), ("alpha", "1.0.0"), ("beta", "2.0.0")],
        [("root-pkg", "alpha"), ("root-pkg", "beta")],
        root_declared={"alpha": "^1.0.0", "beta": "~2.0.0"},
    );
    assert changelog_declared_drift(
        g,
        "root-pkg",
        {"alpha": "^2.0.0", "beta": "~2.0.0", "gamma": "^9.0.0"},
    ) == ["alpha"];
    assert changelog_declared_drift(
        g,
        "root-pkg",
        {"alpha": "^1.0.0"},
    ) == [];
}
