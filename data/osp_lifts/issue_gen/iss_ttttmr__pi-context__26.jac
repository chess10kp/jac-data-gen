# ttttmr/pi-context#26 — DCP-style ranged context compaction
# A - B - [C - D] - E - F becomes A - B - summary - E - F on the
# model-facing projection while the original chain stays intact.

node Msg { has mid: str; has role: str; has text: str; }
node Summary { has mid: str; has text: str; has covers: list[str] = []; }
edge Next;

obj Session {
    has head: Msg | None = None;
    has tail: Msg | None = None;
    has by_id: dict[str, Msg] = {};
    has order: list[str] = [];
    has sums: list[str] = [];
}

def find(store: Session, mid: str) -> Msg | None {
    if mid in store.by_id { return store.by_id[mid]; }
    return None;
}

def build(store: Session, ids: list[str]) {
    for i in ids {
        m = Msg(mid=i, role="user", text="body " + i);
        if store.head is None { store.head = m; } else { store.tail ++> m; }
        store.tail = m;
        store.by_id[i] = m;
        store.order.append(i);
    }
}

# ranged compaction: validate all ranges first (atomic reject), then splice
def context_compact_range(store: Session, starts: list[str], ends: list[str], texts: list[str]) -> list[str] {
    pos: dict[str, int] = {};
    for i in range(len(store.order)) { pos[store.order[i]] = i; }
    for k in range(len(starts)) {
        if starts[k] not in pos or ends[k] not in pos { raise ValueError("unknown range id"); }
        if pos[starts[k]] >= pos[ends[k]] { raise ValueError("stale range"); }
        if pos[starts[k]] == 0 { raise ValueError("cannot compact head"); }
    }
    for a in range(len(starts)) {
        for b in range(a + 1, len(starts)) {
            if pos[starts[b]] <= pos[ends[a]] and pos[ends[b]] >= pos[starts[a]] {
                raise ValueError("overlapping ranges");
            }
        }
    }
    made: list[str] = [];
    for k in range(len(starts)) {
        si = pos[starts[k]];
        ei = pos[ends[k]];
        prev = find(store, store.order[si - 1]);
        after = None;
        if ei + 1 < len(store.order) { after = find(store, store.order[ei + 1]); }
        cov: list[str] = [];
        for j in range(si, ei + 1) { cov.append(store.order[j]); }
        sm = Summary(mid="summary_" + str(k), text=texts[k], covers=cov);
        if prev is not None { prev ++> sm; }
        if after is not None { sm ++> after; }
        store.sums.append(sm.mid);
        made.append(sm.mid);
    }
    return made;
}

walker Project {
    has seen: dict[str, bool] = {};
    has covered: dict[str, bool] = {};
    has out: list[str] = [];
    can step_m with Msg entry {
        if here.mid in self.seen { skip; }
        self.seen[here.mid] = True;
        if here.mid not in self.covered { self.out.append(here.mid); }
        for ch in [here ->:Next:->] { visit ch; }
        disengage;
    }
    can step_s with Summary entry {
        if here.mid in self.seen { skip; }
        self.seen[here.mid] = True;
        self.out.append(here.mid);
        for c in here.covers { self.covered[c] = True; }
        for ch in [here ->:Next:->] { visit ch; }
        disengage;
    }
}

walker Decompress {
    has seen: dict[str, bool] = {};
    has out: list[str] = [];
    can step_d with Msg entry {
        if here.mid in self.seen { skip; }
        self.seen[here.mid] = True;
        self.out.append(here.mid);
        for ch in [here ->:Next:->] { visit ch; }
        disengage;
    }
}

def context_inspect(store: Session) -> list[str] {
    return sorted(store.sums);
}

def context_decompress(store: Session) -> list[str] {
    w = store.head spawn Decompress();
    return w.out;
}

def context_project(store: Session) -> list[str] {
    w = store.head spawn Project();
    return w.out;
}
