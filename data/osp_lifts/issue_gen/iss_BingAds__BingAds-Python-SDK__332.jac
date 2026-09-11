"""OSP lift: bulk row dependency order — BingAds/BingAds-Python-SDK#332."""

node BulkRow {
    has rid: str;
    has payload: str;
}

edge ParentOf {}

obj BulkProcessor {
    def _find(rid: str) -> BulkRow | None {
        for r in [root-->[?:BulkRow]] {
            if r.rid == rid { return r; }
        }
        return None;
    }

    def register_row(rid: str, payload: str, parent_id: str | None = None) -> None {
        if self._find(rid) is not None { return; }
        row = root ++> BulkRow(rid=rid, payload=payload);
        if parent_id is not None {
            par = self._find(parent_id);
            if par is not None { par +>:ParentOf:+> row; }
        }
    }

    def processing_order() -> list[str] {
        w = root spawn TopoWalker();
        return w.reports[0] if w.reports else [];
    }

    def unreachable() -> list[str] {
        w = root spawn UnreachWalker();
        return w.reports[0] if w.reports else [];
    }

    def read_simulated(rid: str) -> str {
        r = self._find(rid);
        if r is None { raise KeyError(rid); }
        return r.payload;
    }
}

walker TopoWalker {
    has order: list[str] = [];
    has indeg: dict = {};
    has reports: list[list[str]] = [];

    can begin with Root entry {
        rows = [root-->[?:BulkRow]];
        for r in rows { self.indeg[r.rid] = 0; }
        for r in rows {
            for ch in [r ->:ParentOf:->] {
                self.indeg[ch.rid] = self.indeg.get(ch.rid, 0) + 1;
            }
        }
        for r in sorted(rows, key=lambda x: x.rid) {
            if self.indeg.get(r.rid, 0) == 0 { visit [r]; }
        }
    }

    can step with BulkRow entry {
        self.order.append(here.rid);
        for ch in sorted([here ->:ParentOf:->], key=lambda x: x.rid) {
            self.indeg[ch.rid] = self.indeg.get(ch.rid, 0) - 1;
            if self.indeg[ch.rid] == 0 { visit [ch]; }
        }
    }

    can finish with Root exit { report self.order; }
}

walker UnreachWalker {
    has reports: list[list[str]] = [];

    can begin with Root entry {
        w = root spawn TopoWalker();
        ordered = set(w.reports[0] if w.reports else []);
        bad = sorted([r.rid for r in [root-->[?:BulkRow]] if r.rid not in ordered]);
        report bad;
    }
}

def build_processor() -> BulkProcessor { return BulkProcessor(); }
