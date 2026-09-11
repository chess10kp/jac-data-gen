"""EffortlessMetrics/perl-lsp-swarm#8169 — Package parent ancestry queries."""
import from __future__ { annotations }
class PackageStore {
    def init(self: PackageStore) -> None {
        self._packages: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
    }
}
def load_packages(
    names: list[str], parent_of: dict[(str, (str | None))]
) -> PackageStore {
    ps = PackageStore();
    for name in names {
        ps._packages.add(name);
        ps._parent[name] = parent_of.get(name);
    }
    return ps;
}
def _ancestors(store: PackageStore, pkg: str, acc: list[str]) -> None {
    par = store._parent.get(pkg);
    if ((par is None) or (par not in store._packages)) {
        return;
    }
    if (par in acc) {
        return;
    }
    acc.append(par);
    _ancestors(store, par, acc);
}
def package_ancestors(store: PackageStore, pkg_id: str) -> list[str] {
    if (pkg_id not in store._packages) {
        return [];
    }
    out: list[str] = [];
    _ancestors(store, pkg_id, out);
    return out;
}
def direct_parent(store: PackageStore, pkg_id: str) -> (str | None) {
    if (pkg_id not in store._packages) {
        return None;
    }
    par = store._parent.get(pkg_id);
    if ((par is None) or (par not in store._packages)) {
        return None;
    }
    return par;
}

