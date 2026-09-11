"""dbt-labs/dbt-core#10632 — execution_order priority among ready models (OSP lift)."""

node DbtModel {
    has name: str;
    has execution_order: int | None = None;
}

edge Depends {}

obj ModelDag {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def add_model(name: str, execution_order: int | None = None) -> None {
        if self._find(name) is None {
            self._root ++> DbtModel(name=name, execution_order=execution_order);
        }
    }

    def add_ref(model: str, depends_on: str) -> None {
        m = self._find(model);
        dep = self._find(depends_on);
        if m is None or dep is None {
            raise KeyError("unknown model id");
        }
        dep +>:Depends:+> m;
    }

    def ready_models(completed: set[str]) -> list[str] {
        ready: list[str] = [];
        for m in [self._root-->[?:DbtModel]] {
            if m.name in completed { continue; }
            blocked = False;
            for dep in [m<--][?:DbtModel] {
                if dep.name not in completed {
                    blocked = True;
                    break;
                }
            }
            if not blocked { ready.append(m.name); }
        }
        return self._sort_names(ready);
    }

    def has_cycle() -> bool {
        w = self._root spawn CycleProbe();
        return w.found;
    }

    def execution_order() -> list[str] | None {
        if self.has_cycle() { return None; }
        indeg: dict[str, int] = {};
        for m in [self._root-->[?:DbtModel]] {
            indeg[m.name] = len([m<--][?:DbtModel]);
        }
        w = self._root spawn PriorityTopo(indegree=indeg);
        if len(w.order) != len(indeg) { return None; }
        return w.order;
    }

    def _find(name: str) -> DbtModel | None {
        for m in [self._root-->[?:DbtModel]] {
            if m.name == name { return m; }
        }
        return None;
    }

    def _priority_key(name: str) -> tuple[int, int, str] {
        m = self._find(name);
        if m is None { return (2, 0, name); }
        if m.execution_order is None { return (1, 0, name); }
        return (0, m.execution_order, name);
    }

    def _sort_names(names: list[str]) -> list[str] {
        if len(names) <= 1 { return names; }
        out = list(names);
        # simple stable sort by priority key
        for i in range(len(out)) {
            for j in range(i + 1, len(out)) {
                ki = self._priority_key(out[i]);
                kj = self._priority_key(out[j]);
                if kj < ki {
                    tmp = out[i];
                    out[i] = out[j];
                    out[j] = tmp;
                }
            }
        }
        return out;
    }
}

walker CycleProbe {
    has found: bool = False;
    has color: dict[str, int] = {};  # 0=unseen 1=active 2=done

    can start with Root entry {
        visit [-->][?:DbtModel];
    }

    can walk with DbtModel entry {
        if self.found { skip; }
        nm = here.name;
        if self.color.get(nm, 0) == 1 {
            self.found = True;
            skip;
        }
        if self.color.get(nm, 0) == 2 { skip; }
        self.color[nm] = 1;
        visit [here<--][?:DbtModel] else { disengage; };
    }

    can unwind with DbtModel exit {
        self.color[here.name] = 2;
    }
}

walker PriorityTopo {
    has indegree: dict[str, int];
    has order: list[str] = [];
    has placed: dict[str, bool] = {};

    can schedule with Root entry {
        total = 0;
        for _m in [-->][?:DbtModel] { total += 1; }
        while len(self.order) < total {
            ready: list[DbtModel] = [];
            for m in [-->][?:DbtModel] {
                if m.name in self.placed { continue; }
                if self.indegree.get(m.name, 0) == 0 {
                    ready.append(m);
                }
            }
            if not ready { break; }
            best = ready[0];
            for cand in ready {
                if self._better(cand, best) { best = cand; }
            }
            self.placed[best.name] = True;
            visit [best];
        }
    }

    can emit with DbtModel entry {
        self.order.append(here.name);
        for child in [here-->[?:DbtModel]] {
            nm = child.name;
            self.indegree[nm] = self.indegree.get(nm, 0) - 1;
        }
    }

    def _better(a: DbtModel, b: DbtModel) -> bool {
        ka = self._key(a);
        kb = self._key(b);
        return kb < ka;
    }

    def _key(m: DbtModel) -> tuple[int, int, str] {
        if m.execution_order is None { return (1, 0, m.name); }
        return (0, m.execution_order, m.name);
    }
}
