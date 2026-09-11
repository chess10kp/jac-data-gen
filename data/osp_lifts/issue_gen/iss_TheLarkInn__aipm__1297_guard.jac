"""TheLarkInn/aipm#1297 — build-unit dependency graph reachability and duplicate lineage."""

class BuildGraphError(Exception) {}

node BuildAnchor {}

node Unit {
    has uid: str;
    has compile_seconds: float;
}

edge BuildDep: Unit --> Unit {}

def sort_units(items: list[Unit]) -> list[Unit] {
    names: list[str] = [];
    for it in items { names.append(it.uid); }
    names = sorted(names);
    out: list[Unit] = [];
    for nm in names {
        for it in items {
            if it.uid == nm { out.append(it); }
        }
    }
    return out;
}

def rank_rows(rows: list[tuple[str, float]]) -> list[tuple[str, float]] {
    out = rows[:];
    for i in range(len(out)) {
        for j in range(i + 1, len(out)) {
            a = out[i];
            b = out[j];
            swap = False;
            if a[1] < b[1] { swap = True; }
            elif a[1] == b[1] and a[0] > b[0] { swap = True; }
            if swap {
                out[i] = b;
                out[j] = a;
            }
        }
    }
    return out;
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can go with Unit entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        self.names.append(here.uid);
        visit [->:BuildDep:->];
    }
}

walker PathFind {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;

    can go with Unit entry {
        if here.uid == self.target {
            self.found = True;
            skip;
        }
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        kids = sort_units([here ->:BuildDep:->]);
        idx = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
    }
}

obj BuildPerformanceGraph {
    has anchor: BuildAnchor;

    def init {
        self.anchor = BuildAnchor();
        root ++> self.anchor;
    }

    def _find(uid: str) -> Unit | None {
        for u in [self.anchor -->][?:Unit] {
            if u.uid == uid { return u; }
        }
        return None;
    }

    def add_unit(unit_id: str, compile_seconds: float) {
        existing = self._find(unit_id);
        if existing is not None {
            existing.compile_seconds = compile_seconds;
            return;
        }
        nd = Unit(uid=unit_id, compile_seconds=compile_seconds);
        self.anchor ++> nd;
    }

    def add_dependency(from_unit: str, to_unit: str) {
        src = self._find(from_unit);
        dst = self._find(to_unit);
        if src is None or dst is None { raise BuildGraphError("unknown unit"); }
        dup = False;
        for ex in [src ->:BuildDep:->] {
            if ex.uid == to_unit { dup = True; }
        }
        if not dup { src +>:BuildDep():+> dst; }
    }

    def reachable_from(root_id: str) -> list[str] {
        rt = self._find(root_id);
        if rt is None { raise BuildGraphError("unknown unit"); }
        w = rt spawn ReachWalk(claimed={}, names=[]);
        return sorted(w.names);
    }

    def critical_path_units(top_n: int = 5) -> list[tuple[str, float]] {
        rows: list[tuple[str, float]] = [];
        for u in [self.anchor -->][?:Unit] {
            rows.append((u.uid, u.compile_seconds));
        }
        ranked = rank_rows(rows);
        if top_n < len(ranked) { return ranked[:top_n]; }
        return ranked;
    }

    def duplicate_lineages(crate_versions: dict[str, list[str]]) -> dict[str, list[str]] {
        out: dict[str, list[str]] = {};
        roots: list[Unit] = [];
        for u in [self.anchor -->][?:Unit] {
            if len([u <-:BuildDep:<-]) == 0 { roots.append(u); }
        }
        roots = sort_units(roots);
        keys = sorted(crate_versions.keys());
        for crate in keys {
            versions = crate_versions[crate];
            if len(versions) < 2 { continue; }
            hits: list[str] = [];
            for rt in roots {
                reach = self.reachable_from(rt.uid);
                present: list[str] = [];
                for ver in sorted(versions) {
                    hit = False;
                    for nm in reach {
                        if nm == ver { hit = True; }
                    }
                    if hit { present.append(ver); }
                }
                if len(present) >= 2 { hits.append(rt.uid); }
            }
            if len(hits) > 0 { out[crate] = hits; }
        }
        return out;
    }

    def path_exists(source: str, target: str) -> bool {
        src = self._find(source);
        if src is None or self._find(target) is None { raise BuildGraphError("unknown unit"); }
        w = src spawn PathFind(claimed={}, target=target, found=False);
        return w.found;
    }

    def wall_clock_share(units: list[str]) -> float {
        total = 0.0;
        for u in [self.anchor -->][?:Unit] { total += u.compile_seconds; }
        if total <= 0.0 { return 0.0; }
        picked = 0.0;
        for uid in units {
            nd = self._find(uid);
            if nd is not None { picked += nd.compile_seconds; }
        }
        return round(picked / total, 4);
    }
}

test "diamond reachable_from dedups convergent sink with adversarial edge order" {
    g = BuildPerformanceGraph();
    g.add_unit("root", 1.0);
    g.add_unit("left", 2.0);
    g.add_unit("right", 3.0);
    g.add_unit("sink", 4.0);
    g.add_dependency("root", "right");
    g.add_dependency("root", "left");
    g.add_dependency("right", "sink");
    g.add_dependency("left", "sink");
    assert g.reachable_from("root") == ["left", "right", "root", "sink"];
}

test "path_exists traverses diamond revisit safely" {
    g = BuildPerformanceGraph();
    g.add_unit("root", 1.0);
    g.add_unit("left", 2.0);
    g.add_unit("right", 3.0);
    g.add_unit("sink", 4.0);
    g.add_dependency("root", "right");
    g.add_dependency("root", "left");
    g.add_dependency("right", "sink");
    g.add_dependency("left", "sink");
    assert g.path_exists("root", "sink") is True;
    assert g.path_exists("sink", "root") is False;
}

test "path_exists unknown source raises" {
    g = BuildPerformanceGraph();
    g.add_unit("only", 1.0);
    raised = False;
    try {
        g.path_exists("ghost", "only");
        assert False, "should have raised";
    } except BuildGraphError {
        raised = True;
    }
    assert raised;
}

test "critical_path_units tie breaks by unit id" {
    g = BuildPerformanceGraph();
    g.add_unit("b", 10.0);
    g.add_unit("a", 10.0);
    g.add_unit("c", 5.0);
    assert g.critical_path_units(3) == [("a", 10.0), ("b", 10.0), ("c", 5.0)];
}

test "duplicate_lineages skips single-version crates" {
    g = BuildPerformanceGraph();
    g.add_unit("root", 0.0);
    g.add_unit("bitflags@1", 0.1);
    g.add_unit("bitflags@2", 0.1);
    g.add_dependency("root", "bitflags@1");
    g.add_dependency("root", "bitflags@2");
    out = g.duplicate_lineages({
        "syn": ["syn@2.0.117"],
        "bitflags": ["bitflags@1", "bitflags@2"],
    });
    assert out == {"bitflags": ["root"]};
}

test "wall_clock_share empty graph returns zero" {
    g = BuildPerformanceGraph();
    assert g.wall_clock_share(["missing"]) == 0.0;
}
