"""WITH-clause name resolution — Dtronix/Quarry#331."""

node Cte { has name: str; }
edge RefsTo {}

obj CteRegistry {
    has nodes: dict[str, Cte] = {};
    has _root: Root;
    def init() { self._root = root; }

    def register_with(name: str, refs: list[str] | None = None) -> None {
        if name not in self.nodes {
            n = Cte(name=name);
            self._root ++> n;
            self.nodes[name] = n;
        }
        if refs is not None {
            src = self.nodes[name];
            for rname in refs {
                dst = self.nodes.get(rname);
                if dst is not None { src +>:RefsTo:+> dst; }
            }
        }
    }

    def reachable_ctes(start: str) -> list[str] {
        n = self.nodes.get(start);
        if n is None { return []; }
        w = n spawn ReachCte(claimed={});
        return w.order;
    }

    def column_context(query_name: str) -> list[str] {
        return sorted(self.reachable_ctes(query_name));
    }

    def has_unknown_ref(name: str) -> bool {
        for (src_name, n) in self.nodes.items() {
            for dst in [n->:RefsTo:->] {
                if dst.name not in self.nodes { return True; }
            }
        }
        return False;
    }
}

walker ReachCte {
    has claimed: dict[str, bool];
    has order: list[str] = [];
    can step with Cte entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [->:RefsTo:->];
    }
}

def build_registry() -> CteRegistry { return CteRegistry(); }
