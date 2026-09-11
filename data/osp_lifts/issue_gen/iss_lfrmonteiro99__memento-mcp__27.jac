"""OSP lift: typed-edge memory graph — lfrmonteiro99/memento-mcp#27."""

node Memory { has mid: str; has label: str = ""; }
edge Relates { has kind: str = "related"; }

obj MemoryGraph {
    def _find(mid: str) -> Memory | None {
        for m in [root-->[?:Memory]] { if m.mid == mid { return m; } }
        return None;
    }

    def add_memory(mid: str, label: str) -> None {
        if self._find(mid) is not None { return; }
        root ++> Memory(mid=mid, label=label);
    }

    def add_link(src: str, dst: str, kind: str = "related") -> None {
        s = self._find(src); d = self._find(dst);
        if s is None or d is None { return; }
        s +>:Relates(kind=kind):+> d;
    }

    def reachable_from(start: str) -> list[str] {
        w = root spawn ReachWalker(start_id=start);
        return w.reports[0] if w.reports else [];
    }

    def has_cycle() -> bool {
        w = root spawn CycleProbeWalker();
        return w.reports[0] if w.reports else False;
    }
}

walker ReachWalker {
    has start_id: str;
    has order: list[str] = [];
    has claimed: dict = {};
    has reports: list[list[str]] = [];

    can begin with Root entry {
        found = False;
        for m in [root-->[?:Memory]] {
            if m.mid == self.start_id { visit [m]; found = True; break; }
        }
        if not found { report []; disengage; }
    }

    can step with Memory entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.order.append(here.mid);
        visit [-->];
    }

    can finish with Root exit { report self.order; }
}

walker CycleProbeWalker {
    has gray: dict = {};
    has black: dict = {};
    has found: bool = False;
    has reports: list[bool] = [];

    can begin with Root entry {
        for m in sorted([root-->[?:Memory]], key=lambda x: x.mid) {
            if m.mid not in self.black { visit [m]; }
        }
    }

    can step with Memory entry {
        if self.found { skip; }
        if here.mid in self.gray { self.found = True; skip; }
        self.gray[here.mid] = True;
        visit [-->];
        del self.gray[here.mid];
        self.black[here.mid] = True;
    }

    can finish with Root exit { report self.found; }
}

def build_graph() -> MemoryGraph { return MemoryGraph(); }
