"""OSP lift: basic dependency relations — omnilith/omnilith-core#5."""

node Entity { has eid: str; }
edge Depends {}

obj RelationGraph {
    def _find(eid: str) -> Entity | None {
        for e in [root-->[?:Entity]] {
            if e.eid == eid { return e; }
        }
        return None;
    }

    def add_entity(eid: str) -> None {
        if self._find(eid) is not None { return; }
        root ++> Entity(eid=eid);
    }

    def link(src: str, dst: str) -> None {
        s = self._find(src);
        d = self._find(dst);
        if s is None or d is None { return; }
        s +>:Depends:+> d;
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
    has claimed: dict[str, bool] = {};
    has reports: list[list[str]] = [];

    can begin with Root entry {
        found = False;
        for e in [root-->[?:Entity]] {
            if e.eid == self.start_id {
                visit [e];
                found = True;
                break;
            }
        }
        if not found {
            report [];
            disengage;
        }
    }

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.order.append(here.eid);
        visit [-->];
    }

    can finish with Root exit { report self.order; }
}

walker CycleProbeWalker {
    has gray: dict[str, bool] = {};
    has black: dict[str, bool] = {};
    has found: bool = False;
    has reports: list[bool] = [];

    can begin with Root entry {
        for e in [root-->[?:Entity]] {
            if e.eid not in self.black { visit [e]; }
        }
    }

    can step with Entity entry {
        if self.found { skip; }
        if here.eid in self.gray {
            self.found = True;
            skip;
        }
        self.gray[here.eid] = True;
        visit [-->];
        del self.gray[here.eid];
        self.black[here.eid] = True;
    }

    can finish with Root exit { report self.found; }
}

def build_graph() -> RelationGraph { return RelationGraph(); }
