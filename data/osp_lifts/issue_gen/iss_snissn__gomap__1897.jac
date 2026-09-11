"""snissn/gomap#1897 — aligned fixed-width TreeDB row spans (OSP lift)."""

obj RowStore {
    has spans: dict[str, dict[str, int]] = {};
    has parent_of: dict[str, str] = {};
    has depends: dict[str, list[str]] = {};
    has align: int = 8;
}

node Span { has sid: str; has offset: int; has width: int; }
edge Child {}
edge Needs {}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";

    can step with Span entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.origin { self.reached.append(here.sid); }
        visit [->:Child:->] else { disengage; };
    }
}

walker DepReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";

    can step with Span entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.origin { self.reached.append(here.sid); }
        visit [->:Needs:->] else { disengage; };
    }
}

def _find(sid: str) -> Span | None {
    for n in [-->][?:Span] { if n.sid == sid { return n; } }
    return None;
}

def _offset_key(g: RowStore, sid: str) -> int {
    sp = g.spans.get(sid, {});
    return sp.get("offset", 0);
}

def load_rows(
    spans: dict[str, dict[str, int]],
    parent_of: dict[str, str],
    depends: dict[str, list[str]],
    align: int = 8,
) -> RowStore {
    mp: dict[str, Span] = {};
    for sid in spans {
        fresh = Span(
            sid=sid,
            offset=spans[sid].get("offset", 0),
            width=spans[sid].get("width", 0),
        );
        root ++> fresh;
        mp[sid] = fresh;
    }
    for (child, parent) in parent_of.items() {
        c = mp.get(child, None);
        p = mp.get(parent, None);
        if c is not None and p is not None { p +>:Child():+> c; }
    }
    for (src, tgts) in depends.items() {
        a = mp.get(src, None);
        if a is None { continue; }
        for tgt in tgts {
            b = mp.get(tgt, None);
            if b is not None { a +>:Needs():+> b; }
        }
    }
    return RowStore(spans=spans, parent_of=parent_of, depends=depends, align=align);
}

def is_aligned(g: RowStore, span_id: str) -> bool {
    sp = g.spans.get(span_id, None);
    if sp is None { return False; }
    return sp.get("offset", 0) % g.align == 0 and sp.get("width", 0) % g.align == 0;
}

def padding_bytes(g: RowStore, span_id: str) -> int {
    sp = g.spans.get(span_id, None);
    if sp is None { return 0; }
    rem = sp.get("offset", 0) % g.align;
    if rem == 0 { return 0; }
    return g.align - rem;
}

def lineage_closure(g: RowStore, root_id: str) -> list[str] {
    if root_id not in g.spans { return []; }
    anchor = _find(root_id);
    if anchor is None { return []; }
    w = anchor spawn LineageWalk(claimed={}, reached=[], origin=root_id);
    out = list(w.reached);
    out.sort(key=lambda (s) { _offset_key(g, s); });
    return out;
}

def dependency_reach(g: RowStore, span_id: str) -> list[str] {
    if span_id not in g.spans { return []; }
    anchor = _find(span_id);
    if anchor is None { return []; }
    w = anchor spawn DepReachWalk(claimed={}, reached=[], origin=span_id);
    return sorted(w.reached);
}
