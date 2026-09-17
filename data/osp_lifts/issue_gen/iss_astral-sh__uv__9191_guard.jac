# astral-sh/uv#9191 — cache invalidation on local deps (docker ctime drift)
# Use checksums (not inode/ctime) for freshness of local dependency graph.

node Package {
    has name: str;
    has checksum: str;
    has installed_checksum: str = "";
}

edge DependsOn {}

# build dependency graph: parent depends on children
def add_dep(parent: Package, child: Package) {
    parent +>:DependsOn:+> child;
}

# checksum-based freshness: fresh iff installed checksum matches current
def is_fresh(pkg: Package) -> bool {
    return pkg.installed_checksum == pkg.checksum and pkg.installed_checksum != "";
}

def install(pkg: Package) {
    pkg.installed_checksum = pkg.checksum;
}

# memoized stale-closure: mark pkg stale and cascade to all dependents
walker Invalidate {
    has claimed: dict[str, bool] = {};
    has invalidated: list[str] = [];

    can sweep with Package entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.invalidated.append(here.name);
        here.installed_checksum = "";
        # move up to dependents (parents that depend on here): incoming DependsOn
        visit [here <-:DependsOn:-];
    }
}

def mark_stale(pkg: Package) -> list[str] {
    wk = pkg spawn Invalidate(claimed={});
    return sorted(wk.invalidated);
}

# memoized fresh closure: all transitive local deps that are fresh
walker FreshCheck {
    has claimed: dict[str, bool] = {};
    has stale: list[str] = [];

    can check with Package entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if not is_fresh(here) {
            self.stale.append(here.name);
        }
        visit [here ->:DependsOn:->];
    }
}

def stale_closure(pkg: Package) -> list[str] {
    wk = pkg spawn FreshCheck(claimed={});
    return sorted(wk.stale);
}

walker Demo {
    can go with root entry {
        api = Package(name="api", checksum="c1");
        lib = Package(name="lib", checksum="c2");
        core = Package(name="core", checksum="c3");
        root ++> api; root ++> lib; root ++> core;
        add_dep(api, lib);
        add_dep(lib, core);
        install(api); install(lib); install(core);
        print(sorted(stale_closure(api)));
        core.checksum = "c3b";
        print(sorted(stale_closure(api)));
        print(mark_stale(core));
        print(sorted(stale_closure(api)));
    }
}

with entry {
    root spawn Demo();
}

test "fresh_after_install" {
    api = Package(name="api", checksum="c1");
    lib = Package(name="lib", checksum="c2");
    add_dep(api, lib);
    install(api);
    install(lib);
    assert stale_closure(api) == [];
    assert is_fresh(api);
    assert is_fresh(lib);
}

test "stale_closure_detects_mismatch" {
    api = Package(name="api", checksum="c1");
    lib = Package(name="lib", checksum="c2");
    core = Package(name="core", checksum="c3");
    add_dep(api, lib);
    add_dep(lib, core);
    install(api);
    install(lib);
    install(core);
    core.checksum = "c3b";
    assert sorted(stale_closure(api)) == ["core"];
}

test "mark_stale_cascades_to_dependents" {
    api = Package(name="api", checksum="c1");
    lib = Package(name="lib", checksum="c2");
    core = Package(name="core", checksum="c3");
    add_dep(api, lib);
    add_dep(lib, core);
    install(api);
    install(lib);
    install(core);
    assert sorted(mark_stale(core)) == ["api", "core", "lib"];
    assert not is_fresh(core);
    assert not is_fresh(lib);
    assert not is_fresh(api);
}

test "cycle_terminates_via_claim_map" {
    a = Package(name="a", checksum="ka");
    b = Package(name="b", checksum="kb");
    add_dep(a, b);
    add_dep(b, a);
    install(a);
    install(b);
    assert sorted(mark_stale(a)) == ["a", "b"];
    assert stale_closure(a) == [];
}

test "uninstalled_is_stale" {
    solo = Package(name="solo", checksum="k1");
    assert sorted(stale_closure(solo)) == ["solo"];
    install(solo);
    assert stale_closure(solo) == [];
}
