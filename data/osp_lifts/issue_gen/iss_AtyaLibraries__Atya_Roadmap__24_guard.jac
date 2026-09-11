"""Guard: AtyaLibraries/Atya.Roadmap#24."""

node RepoNode { has name: str; }
edge References {}

obj FleetManifest { has repos: dict[str, RepoNode] = {}; }

walker RefReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with RepoNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:References:->][?:RepoNode];
    }
}

def load_fleet_manifest(
    repos: list[str],
    refs: list[tuple[str, str]],
) -> FleetManifest {
    m = FleetManifest();
    for r in repos {
        nd = RepoNode(name=r);
        root ++> nd;
        m.repos[r] = nd;
    }
    for (src, dst) in refs {
        s = m.repos.get(src, None);
        d = m.repos.get(dst, None);
        if s is not None and d is not None { s +>:References:+> d; }
    }
    return m;
}

def reachable_repos(manifest: FleetManifest, `root: str) -> list[str] {
    if not (`root in manifest.repos) { return []; }
    nd = manifest.repos[`root];
    w = nd spawn RefReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def drift_violations(
    manifest: FleetManifest,
    actual_refs: list[tuple[str, str]],
) -> list[tuple[str, str]] {
    expected: list[tuple[str, str]] = [];
    for (src, nd) in manifest.repos.items() {
        for dst in [nd ->:References:->][?:RepoNode] {
            expected.append((src, dst.name));
        }
    }
    exp_set = {};
    for e in expected { exp_set[e] = True; }
    act_set = {};
    for a in actual_refs { act_set[a] = True; }
    out: list[tuple[str, str]] = [];
    for e in expected {
        if not (e in act_set) { out.append(e); }
    }
    for a in actual_refs {
        if not (a in exp_set) { out.append(a); }
    }
    return sorted(out);
}

def orphan_repos(manifest: FleetManifest, roots: list[str]) -> list[str] {
    reachable: dict[str, bool] = {};
    for r in roots {
        for x in reachable_repos(manifest, r) { reachable[x] = True; }
    }
    out: list[str] = [];
    for k in manifest.repos.keys() {
        if not (k in reachable) { out.append(k); }
    }
    return sorted(out);
}

test "fleet reachability" {
    m = load_fleet_manifest(
        ["roadmap", "cli", "platform"],
        [("roadmap", "cli"), ("roadmap", "platform"), ("cli", "platform")],
    );
    assert reachable_repos(m, "roadmap") == ["cli", "platform", "roadmap"];
    assert drift_violations(m, [("roadmap", "cli")]) == [
        ("cli", "platform"),
        ("roadmap", "platform"),
    ];
    assert orphan_repos(m, ["roadmap"]) == [];
}

test "diamond adversarial revisit" {
    m = load_fleet_manifest(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert reachable_repos(m, "hub") == ["hub", "leaf", "left", "right"];
}
