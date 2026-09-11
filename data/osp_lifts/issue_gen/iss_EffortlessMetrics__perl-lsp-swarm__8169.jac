"""EffortlessMetrics/perl-lsp-swarm#8169 — Package parent ancestry queries."""

obj PackageStore { has packages: dict[str, Package] = {}; }
node Package { has name: str; }
edge ChildOf {}

def load_packages(
    names: list[str],
    parent_of: dict[str, str | None],
) -> PackageStore {
    ps = PackageStore();
    for name in names {
        if name not in ps.packages {
            nd = Package(name=name);
            root ++> nd;
            ps.packages[name] = nd;
        }
    }
    for (name, par_name) in parent_of.items() {
        if par_name is None { continue; }
        child = ps.packages.get(name, None);
        parent = ps.packages.get(par_name, None);
        if child is not None and parent is not None { parent +>:ChildOf:+> child; }
    }
    return ps;
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Package entry {
        parents = [here <-:ChildOf:<-][?:Package];
        if len(parents) == 0 { disengage; }
        p = parents[0];
        if p.name in self.claimed { skip; }
        self.claimed[p.name] = True;
        self.chain.append(p.name);
        visit [p];
    }
}

def package_ancestors(store: PackageStore, pkg_id: str) -> list[str] {
    start = store.packages.get(pkg_id, None);
    if start is None { return []; }
    w = start spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

def direct_parent(store: PackageStore, pkg_id: str) -> str | None {
    start = store.packages.get(pkg_id, None);
    if start is None { return None; }
    parents = [start <-:ChildOf:<-][?:Package];
    if len(parents) == 0 { return None; }
    return parents[0].name;
}
