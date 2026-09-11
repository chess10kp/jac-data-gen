"""fleetdm/fleet#46263 — batch software installer reachability with cycle guards."""

node Pkg {
    has pkg_id: str;
    has label: str;
}

edge Needs {}

obj InstallerBatch {
    has nodes: list = [];

    def add(pkg_id: str, label: str) -> Pkg {
        p = Pkg(pkg_id=pkg_id, label=label);
        self.nodes.append(p);
        return p;
    }

    def require(pkg: Pkg, needs: Pkg) -> None {
        pkg +>:Needs:+> needs;
    }

    def _find(pkg_id: str) -> Pkg | None {
        for p in self.nodes {
            if p.pkg_id == pkg_id {
                return p;
            }
        }
        return None;
    }

    def closure(seeds: list[str]) -> list[str] {
        out: list[str] = [];
        for s in sorted(seeds) {
            p = self._find(s);
            if p is not None {
                w = p spawn ClosureWalker();
                for x in w.ids {
                    if x not in out {
                        out.append(x);
                    }
                }
            }
        }
        return sorted(out);
    }

    def has_dependency_cycle() -> bool {
        w = root spawn CycleScanWalker(targets=self.nodes);
        return w.found;
    }
}

walker ClosureWalker {
    has ids: list[str] = [];
    has claimed: dict = {};

    can walk with Pkg entry {
        if self.claimed.get(here.pkg_id, False) {
            skip;
        }
        self.claimed[here.pkg_id] = True;
        self.ids.append(here.pkg_id);
        visit [-->];
    }
}

walker CycleScanWalker {
    has targets: list;
    has stack: list[str] = [];
    has found: bool = False;

    can start with Root entry {
        for p in self.targets {
            visit [p];
        }
    }

    can dfs with Pkg entry {
        if here.pkg_id in self.stack {
            self.found = True;
            skip;
        }
        self.stack = self.stack + [here.pkg_id];
        visit [-->];
        self.stack = self.stack[:-1];
    }
}

def _cycle_batch() -> InstallerBatch {
    b = InstallerBatch();
    a = b.add("a", "A");
    bb = b.add("b", "B");
    c = b.add("c", "C");
    d = b.add("d", "D");
    b.require(a, bb);
    b.require(bb, c);
    b.require(c, d);
    b.require(d, bb);
    return b;
}

test "closure with cycle" {
    b = _cycle_batch();
    assert b.closure(["a"]) == ["a", "b", "c", "d"];
    assert b.has_dependency_cycle() is True;
}

test "acyclic closure" {
    b = InstallerBatch();
    x = b.add("x", "X");
    y = b.add("y", "Y");
    b.require(x, y);
    assert b.closure(["x"]) == ["x", "y"];
    assert b.has_dependency_cycle() is False;
}
