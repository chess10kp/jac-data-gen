"""OSP lift: hull subtree aggregation — Harborline-Software/shipyard#3090."""

node HullPart { has part_id: str; has label: str = ""; has weight: int = 0; }
edge Contains {}

obj HullTree {
    def add_part(part_id: str, label: str = "", weight: int = 0, parent_id: str | None = None) -> None {
        if self._find(part_id) is not None { return; }
        if parent_id is not None and self._find(parent_id) is None { raise KeyError("unknown parent"); }
        root ++> (p := HullPart(part_id=part_id, label=label, weight=weight));
        if parent_id is not None {
            par = self._find(parent_id);
            if par is not None { par +>:Contains:+> p; }
        }
    }

    def aggregate_subtree(root_id: str) -> tuple[int, int] {
        n = self._find(root_id);
        if n is None { return (0, 0); }
        w = n spawn SubtreeAgg();
        return (w.total, w.count);
    }

    def descendants(root_id: str) -> list[str] {
        n = self._find(root_id);
        if n is None { return []; }
        w = n spawn DescCollect();
        return w.ids;
    }

    def ancestors(part_id: str) -> list[str] {
        n = self._find(part_id);
        if n is None { return []; }
        out: list[str] = [];
        cur = n;
        while True {
            parents = [cur<--][?:HullPart];
            if len(parents) == 0 { break; }
            p = parents[0];
            out.append(p.part_id);
            cur = p;
        }
        return out;
    }

    def _find(part_id: str) -> HullPart | None {
        for p in [root-->[?:HullPart]] { if p.part_id == part_id { return p; } }
        return None;
    }
}

walker SubtreeAgg {
    has total: int = 0;
    has count: int = 0;
    has claimed: dict[str, bool] = {};

    can step with HullPart entry {
        if here.part_id in self.claimed { skip; }
        self.claimed[here.part_id] = True;
        self.total += here.weight;
        self.count += 1;
        visit [->:Contains:->];
    }
}

walker DescCollect {
    has ids: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with HullPart entry {
        if here.part_id in self.claimed { skip; }
        self.claimed[here.part_id] = True;
        self.ids.append(here.part_id);
        visit [->:Contains:->];
    }
}

def build_hull() -> HullTree { return HullTree(); }
