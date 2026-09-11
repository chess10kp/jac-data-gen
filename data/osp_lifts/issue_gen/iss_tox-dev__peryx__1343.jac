"""tox-dev/peryx#1343 — Detect aliased requirement include cycles."""

node Req {
    has alias: str;
}

edge Includes {}

obj IncludeGraph {
    has roots: list[Req] = [];

    def _has(alias: str) -> bool {
        for r in self.roots {
            if r.alias == alias {
                return True;
            }
        }
        return False;
    }

    def _ensure(alias: str) -> Req {
        for r in self.roots {
            if r.alias == alias {
                return r;
            }
        }
        r = Req(alias=alias);
        self.roots.append(r);
        return r;
    }

    def add_include(source: str, target: str) {
        src = self._ensure(source);
        tgt = self._ensure(target);
        src +>:Includes:+> tgt;
    }

    def includes_of(alias: str) -> list[str] {
        if not self._has(alias) {
            return [];
        }
        req = self._ensure(alias);
        out: list[str] = [];
        for n in [req ->:Includes:->][?:Req] {
            out.append(n.alias);
        }
        return sorted(out);
    }

    def closure(alias: str) -> list[str] {
        if not self._has(alias) {
            return [];
        }
        req = self._ensure(alias);
        w = req spawn ClosureWalker();
        if w.reports {
            got = w.reports[0];
            got = [x for x in got if x != alias];
            return sorted(got);
        }
        return [];
    }

    def find_include_cycle() -> list[str] | None {
        w = root spawn CycleWalker(roots=self.roots);
        if w.reports and len(w.reports[0]) > 0 {
            return w.reports[0];
        }
        return None;
    }
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can step with Req entry {
        if self.claimed.get(here.alias, False) {
            skip;
        }
        self.claimed[here.alias] = True;
        self.out.append(here.alias);
        visit [->:Includes:->] else {
            disengage;
        };
    }

    can finish with Req exit {
        report self.out;
    }
}

walker CycleWalker {
    has roots: list[Req] = [];
    has path: list[str] = [];
    has on_path: dict[str, bool] = {};
    has done: dict[str, bool] = {};
    has cycle: list[str] = [];

    def lookup(alias: str) -> Req {
        for r in self.roots {
            if r.alias == alias {
                return r;
            }
        }
        return Req(alias="");
    }

    can probe with Root entry {
        for r in self.roots {
            if len(self.cycle) > 0 {
                break;
            }
            visit [r];
        }
        if len(self.cycle) > 0 {
            report self.cycle;
        } else {
            report [];
        }
    }

    can enter with Req entry {
        if len(self.cycle) > 0 {
            skip;
        }
        if self.on_path.get(here.alias, False) {
            idx = self.path.index(here.alias);
            self.cycle = self.path[idx:] + [here.alias];
            skip;
        }
        if self.done.get(here.alias, False) {
            skip;
        }
        self.on_path[here.alias] = True;
        self.path.append(here.alias);
        visit [->:Includes:->];
    }

    can leave with Req exit {
        if len(self.path) > 0 {
            last = self.path.pop();
            self.on_path[last] = False;
        }
        self.done[here.alias] = True;
    }
}
