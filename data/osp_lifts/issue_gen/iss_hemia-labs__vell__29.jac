"""hemia-labs/vell#29 — category descendant lookup (OSP lift)."""

obj CategoryStore {
    has rows: list[tuple[str, str | None]] = [];
    def load_all(rows: list[tuple[str, str | None]]) -> None;
    def find_descendant_ids(category_id: str) -> list[str];
}

node Category {
    has cid: str;
}

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
        if cid not in mp {
            n = Category(cid=cid);
            root ++> n;
            mp[cid] = n;
        }
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
    for c in [-->][?:Category] {
        if c.cid == category_id { anchor = c; }
    }
    if anchor is None { return []; }
    w = anchor spawn DescCollect(claimed={}, found=[], origin=category_id);
    return sorted(w.found);
}
