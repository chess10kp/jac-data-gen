"""Harborline-Software/shipyard#3090 — candidate + hidden guards."""

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
        self.total += here.weight; self.count += 1;
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

test "aggregate chain" {
    h = build_hull();
    h.add_part("keel", "Keel", 10);
    h.add_part("frame", "Frame", 5, "keel");
    h.add_part("deck", "Deck", 3, "frame");
    h.add_part("mast", "Mast", 7, "deck");
    assert h.aggregate_subtree("keel") == (25, 4);
    assert sorted(h.descendants("keel")) == ["deck", "frame", "keel", "mast"];
    assert h.ancestors("mast") == ["deck", "frame", "keel"];
}

test "unknown parent KeyError" {
    h = build_hull();
    try { h.add_part("x", parent_id="nope"); assert False; } except KeyError { assert True; }
}

test "diamond adversarial multiset" {
    h = build_hull();
    h.add_part("hull", "H", 1);
    h.add_part("port", "P", 2, "hull");
    h.add_part("stbd", "S", 2, "hull");
    h.add_part("bow", "B", 4, "port");
    p = h._find("port"); s = h._find("stbd"); b = h._find("bow");
    if p is not None and s is not None and b is not None { s +>:Contains:+> b; }
    hull = h._find("hull");
    if hull is not None and b is not None { b +>:Contains:+> hull; }
    assert sorted(h.descendants("hull")) == ["bow", "hull", "port", "stbd"];
}
