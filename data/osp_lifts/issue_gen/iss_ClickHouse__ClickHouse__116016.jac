"""ClickHouse/ClickHouse#116016 — recursive CTE depth guard with sibling self-join."""

class TooDeepRecursion(Exception) {}

node Cte {
    has name: str;
}

edge DependsOn: Cte --> Cte {}

obj CtePlan {
    has max_depth: int;
    has _spec: dict[str, tuple[str, ...]] = {};
    has _ctes: dict[str, Cte] = {};
}

walker DepsCollectWalk {
    has claimed: dict[str, bool] = {};
    has needed: set[str] = set();

    can step with Cte entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.needed.add(here.name);
        deps = [here ->:DependsOn:->][?:Cte];
        nms: list[str] = [];
        for d in deps { nms.append(d.name); }
        for nm in sorted(nms) {
            for d in deps {
                if d.name == nm { visit d; }
            }
        }
    }
}

walker CteTopoWalk {
    has needed: set[str] = set();
    has order: list[str] = [];
    has indeg: dict[str, int] = {};
    has ready: list[str] = [];

    can begin with Root entry {
        for nm in self.needed { self.indeg[nm] = 0; }
        for nm in self.needed {
            nd: Cte | None = None;
            for c in [root -->][?:Cte] {
                if c.name == nm { nd = c; }
            }
            if nd is not None {
                for dep in [nd ->:DependsOn:->][?:Cte] {
                    if dep.name in self.needed {
                        self.indeg[nm] = self.indeg.get(nm, 0) + 1;
                    }
                }
            }
        }
        seed: list[str] = [];
        for nm in sorted(self.needed) {
            if self.indeg.get(nm, 0) == 0 { seed.append(nm); }
        }
        self.ready = seed;
        while len(self.ready) > 0 {
            cur = self.ready[0];
            rest: list[str] = [];
            idx = 1;
            while idx < len(self.ready) {
                rest.append(self.ready[idx]);
                idx += 1;
            }
            self.ready = rest;
            self.order.append(cur);
            dependents: list[Cte] = [];
            for nm in self.needed {
                nd: Cte | None = None;
                for c in [root -->][?:Cte] {
                    if c.name == nm { nd = c; }
                }
                if nd is not None {
                    for dep in [nd ->:DependsOn:->][?:Cte] {
                        if dep.name == cur { dependents.append(nd); }
                    }
                }
            }
            dnms: list[str] = [];
            for d in dependents { dnms.append(d.name); }
            for nm in sorted(dnms) {
                for d in dependents {
                    if d.name == nm {
                        self.indeg[d.name] = self.indeg.get(d.name, 0) - 1;
                        if self.indeg[d.name] == 0 {
                            self.ready.append(d.name);
                        }
                    }
                }
            }
            self.ready = sorted(self.ready);
        }
        report self.order;
    }
}

def _find_cte(plan: CtePlan, name: str) -> Cte | None {
    return plan._ctes.get(name, None);
}

def _ensure_cte(plan: CtePlan, name: str) -> Cte {
    nd = plan._ctes.get(name, None);
    if nd is None {
        nd = Cte(name=name);
        root ++> nd;
        plan._ctes[name] = nd;
    }
    return nd;
}

def _has_dep_edge(from_nd: Cte, to_nd: Cte) -> bool {
    for d in [from_nd ->:DependsOn:->][?:Cte] {
        if d.name == to_nd.name { return True; }
    }
    return False;
}

def make_plan(max_depth: int = 5) -> CtePlan {
    return CtePlan(max_depth=max_depth);
}

def add_linear_cte(plan: CtePlan, name: str, lo: int, hi: int) -> None {
    plan._spec[name] = ("linear", str(lo), str(hi));
    _ensure_cte(plan, name);
}

def add_projection_cte(plan: CtePlan, name: str, source: str) -> None {
    plan._spec[name] = ("projection", source);
    cte = _ensure_cte(plan, name);
    src = _ensure_cte(plan, source);
    if not _has_dep_edge(cte, src) { cte +>:DependsOn:+> src; }
}

def add_self_join_cte(
    plan: CtePlan, name: str, base: str, join_source: str
) -> None {
    plan._spec[name] = ("self_join", base, join_source);
    cte = _ensure_cte(plan, name);
    _ensure_cte(plan, base);
    _ensure_cte(plan, join_source);
    dep_names: list[str] = sorted(list(set([base, join_source])));
    for dep_name in dep_names {
        dep = _find_cte(plan, dep_name);
        if dep is not None and not _has_dep_edge(cte, dep) {
            cte +>:DependsOn:+> dep;
        }
    }
}

def dependency_closure(plan: CtePlan, target: str) -> list[str] {
    if target not in plan._spec { return []; }
    nd = _find_cte(plan, target);
    if nd is None { return []; }
    w = nd spawn DepsCollectWalk(claimed={}, needed=set());
    topo = root spawn CteTopoWalk(
        needed=w.needed, order=[], indeg={}, ready=[]
    );
    return topo.order;
}

def _eval_linear(plan: CtePlan, lo: int, hi: int) -> list[int] {
    rows: list[int] = [lo];
    depth = 0;
    while rows[-1] < hi {
        depth += 1;
        if depth > plan.max_depth {
            raise TooDeepRecursion("linear", depth);
        }
        rows.append(rows[-1] + 1);
    }
    return rows;
}

def _eval_projection(cache: dict[str, list[int]], source: str) -> list[int] {
    out: list[int] = [];
    for x in cache[source] { out.append(x); }
    return out;
}

def _eval_self_join(
    plan: CtePlan, name: str, cache: dict[str, list[int]]
) -> list[int] {
    spec = plan._spec[name];
    base = spec[1];
    join_src = spec[2];
    join_set: dict[int, bool] = {};
    for x in cache[join_src] { join_set[x] = True; }
    acc: list[int] = [];
    for x in cache[base] { acc.append(x); }
    depth = 0;
    while True {
        depth += 1;
        if depth > plan.max_depth {
            raise TooDeepRecursion(name, depth);
        }
        additions: list[int] = [];
        for row in acc {
            additions.append(row);
            if join_set.get(row, False) { additions.append(row); }
        }
        if len(additions) == 0 { break; }
        for x in additions { acc.append(x); }
    }
    return acc;
}

def _materialize(plan: CtePlan, name: str) -> list[int] {
    cache: dict[str, list[int]] = {};
    for cte in dependency_closure(plan, name) {
        kind = plan._spec[cte][0];
        if kind == "linear" {
            cache[cte] = _eval_linear(
                plan, int(plan._spec[cte][1]), int(plan._spec[cte][2])
            );
        } elif kind == "projection" {
            cache[cte] = _eval_projection(cache, plan._spec[cte][1]);
        } else {
            cache[cte] = _eval_self_join(plan, cte, cache);
        }
    }
    return cache[name];
}

def materialize_cte(plan: CtePlan, name: str) -> list[int] {
    if name not in plan._spec { return []; }
    raw = _materialize(plan, name);
    return sorted(raw);
}

def build_issue_fixture(max_depth: int = 5) -> CtePlan {
    plan = make_plan(max_depth);
    add_linear_cte(plan, "sq1", 1, 5);
    add_projection_cte(plan, "sq2", "sq1");
    add_self_join_cte(plan, "sq3", "sq2", "sq2");
    return plan;
}
