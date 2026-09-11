"""Guard: hemia-labs/vell#29."""

obj CategoryStore {
    has rows: list[tuple[str, str | None]] = [];
    def load_all(rows: list[tuple[str, str | None]]) -> None;
    def find_descendant_ids(category_id: str) -> list[str];
}

node Category { has cid: str; }
edge ChildOf {}

walker DescCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.origin { self.found.append(here.cid); }
        visit [<-:ChildOf:<-];
    }
}

impl CategoryStore.load_all(rows: list[tuple[str, str | None]]) -> None {
    self.rows = rows;
    mp: dict[str, Category] = {};
    for (cid, _par) in rows {
        if cid not in mp { root ++> (mp[cid] := Category(cid=cid)); }
    }
    for (cid, par) in rows {
        if par is not None and par in mp and cid in mp {
            mp[cid] +>:ChildOf:+> mp[par];
        }
    }
}

impl CategoryStore.find_descendant_ids(category_id: str) -> list[str] {
    if not any(r[0] == category_id for r in self.rows) { return []; }
    anchor: Category | None = None;
    for c in [-->][?:Category] { if c.cid == category_id { anchor = c; } }
    if anchor is None { return []; }
    w = anchor spawn DescCollect(claimed={}, found=[], origin=category_id);
    return sorted(w.found);
}

test "linear descendants" {
    s = CategoryStore();
    s.load_all([("root", None), ("a", "root"), ("b", "a")]);
    assert s.find_descendant_ids("root") == ["a", "b"];
    assert s.find_descendant_ids("a") == ["b"];
    assert s.find_descendant_ids("missing") == [];
}

test "diamond adversarial order" {
    s = CategoryStore();
    s.load_all([("hub", None), ("left", "hub"), ("right", "hub"), ("cap", "left"), ("cap2", "right")]);
    got = s.find_descendant_ids("hub");
    assert sorted(got) == ["cap", "cap2", "left", "right"];
}

test "unknown id tolerance" {
    s = CategoryStore();
    s.load_all([("only", None)]);
    assert s.find_descendant_ids("nope") == [];
}
