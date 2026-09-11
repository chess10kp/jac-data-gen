"""Nested dependency lockfile lifted to OSP.

Installed packages nest exactly like on-disk ``node_modules``: each
dependency version lives under the single package that requires it,
so ``DepOf`` edges form a tree. The id registry stays public API
lookup state; ``resolve`` raises KeyError for unknown ids.
"""

node Package {
    has pid: str;
    has version: str;
    has nested: int = 0;     # staging: deps below, folded at exit
}

edge DepOf: Package --> Package {}

"""Register every fixture package into `registry`; returns the lockfile root."""
def build_lockfile(registry: dict[str, Package]) -> Package {
    root_pkg = register(registry, None, "app", "1.0.0");
    left_pad = register(registry, root_pkg, "left-pad", "1.3.0");
    register(registry, root_pkg, "lodash", "4.17.21");
    register(registry, left_pad, "ms", "2.1.3");
    register(registry, left_pad, "lodash@3", "3.10.1");
    return root_pkg;
}

"""Install `pid` under `parent` (None for root) and index it.

Raises ValueError when `pid` is already registered.
"""
def register(registry: dict[str, Package], parent: Package | None, pid: str, version: str) -> Package {
    if pid in registry {
        raise ValueError("duplicate package id");
    }
    root ++> (pkg := Package(pid=pid, version=version));
    registry[pid] = pkg;
    if parent is not None {
        pkg +>:DepOf:+> parent;
    }
    return pkg;
}

"""Look up a package by id; KeyError when absent (dangling ref)."""
def resolve(registry: dict[str, Package], pid: str) -> Package {
    return registry[pid];
}

walker PathClimb {
    """Climbs DepOf edges to the lockfile root; linear walk."""
    has pids: list[str] = [];
    has claimed: dict[str, bool] = {};

    can climb with Package entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        self.pids.append(here.pid);
        visit [->:DepOf:->] else { report self.pids; disengage; }
    }
}

walker DepFold {
    """Exit folds nested dependency counts bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with Package entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        visit [<-:DepOf:<-];
    }

    can fold with Package exit {
        total = 1;
        for d in [<-:DepOf:<-] {
            total += d.nested;
        }
        here.nested = total;
    }
}

walker VersionSweep {
    """Collects versions of packages whose pid starts with the prefix."""
    has prefix: str;
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can sweep with Package entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        if here.pid.startswith(self.prefix) {
            self.found.append(here.version);
        }
        visit [<-:DepOf:<-];
    }
}

"""Nesting path of `pkg`, root-first, segments joined by ' / '."""
def install_path(pkg: Package) -> str {
    w = pkg spawn PathClimb();
    return " / ".join(reversed(w.pids));
}

"""Number of packages at or below `pkg`, counting it."""
def dep_tree_size(pkg: Package) -> int {
    pkg spawn DepFold();
    return pkg.nested;
}

"""Versions of packages under `pkg` whose pid starts with `prefix`."""
def versions_under(pkg: Package, prefix: str) -> list[str] {
    w = pkg spawn VersionSweep(prefix=prefix);
    return sorted(w.found);
}

test "build_lockfile indexes registry" {
    reg: dict[str, Package] = {};
    root_pkg = build_lockfile(reg);
    assert resolve(reg, "ms").version == "2.1.3";
    assert dep_tree_size(root_pkg) == 5;
}

test "resolve raises KeyError on dangling id" {
    reg: dict[str, Package] = {};
    build_lockfile(reg);
    raised = False;
    try {
        resolve(reg, "ghost");
    } except KeyError {
        raised = True;
    }
    assert raised;
}

test "register raises ValueError on duplicate id" {
    reg: dict[str, Package] = {};
    root_pkg = build_lockfile(reg);
    dup = False;
    try {
        register(reg, root_pkg, "app", "9.9.9");
    } except ValueError {
        dup = True;
    }
    assert dup;
}

test "install_path climbs to lockfile root" {
    reg: dict[str, Package] = {};
    build_lockfile(reg);
    ms = resolve(reg, "ms");
    assert install_path(ms) == "app / left-pad / ms";
}

test "versions_under matches prefix multiset" {
    reg: dict[str, Package] = {};
    root_pkg = build_lockfile(reg);
    assert versions_under(root_pkg, "lodash") == ["3.10.1", "4.17.21"];
}
