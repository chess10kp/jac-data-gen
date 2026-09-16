# iss_ttttmr__pi-context__26.jac
# DCP-style ranged context compaction for ttttmr/pi-context#26.
# Non-destructive: the original chain is never rewritten; Sum blocks are
# attached by Covers ancestry edges and projected in via the context walker.

node M { has mid: str; has role: str; has content: str; has compacted: bool = False; }
node Sum { has mid: str; has content: str; }
edge Next;
edge Covers;

obj Store {
    has byid: dict[str, M] = {};
    has head: M | None = None;
    has tail: M | None = None;
    has ranges: list = [];
    has counter: int = 0;
}

# public API ---------------------------------------------------------------

def new_store() -> Store { return Store(); }

def add_message(st: Store, mid: str, role: str, content: str) -> bool {
    if mid in st.byid { return False; }
    m = M(mid=mid, role=role, content=content);
    t: M | None = st.tail;
    if t is None {
        st.head = m;
    } else {
        t +>: Next:+> m;
    }
    st.tail = m;
    st.byid[mid] = m;
    return True;
}

def compact_range(st: Store, start: str, end: str, summary: str) -> bool {
    # phase 1: validate (unknown ids, overlap, staleness)
    if start not in st.byid { return False; }
    if end not in st.byid { return False; }
    for r in st.ranges {
        if start <= r[1] and end >= r[0] { return False; }
    }
    span: list[M] = [];
    cur: M | None = st.byid[start];
    found: bool = False;
    while cur is not None {
        c: M = cur;
        span.append(c);
        if c.mid == end { found = True; break; }
        nx: list[M] = ([c ->:Next:->])[?:M];
        if len(nx) == 0 { cur = None; } else { cur = nx[0]; }
    }
    if not found { return False; }
    # phase 2: mutate outside any walk
    st.counter += 1;
    sm: Sum = Sum(mid="sum" + str(st.counter), content=summary);
    first: M = span[0];
    sm +>: Covers:+> first;
    for m in span {
        m.compacted = True;
    }
    st.ranges.append([start, end]);
    return True;
}

def get_context(st: Store) -> list[str] {
    h: M | None = st.head;
    if h is None { return []; }
    w = h spawn Ctx();
    return w.seen;
}

def decompress(st: Store) -> list[str] {
    h: M | None = st.head;
    if h is None { return []; }
    w = h spawn Dcp();
    out: list[str] = [];
    for x in w.seen { out.append(x); }
    return sorted(out);
}

def drop_message(st: Store, mid: str) -> bool {
    if mid not in st.byid { return False; }
    m: M = st.byid[mid];
    if m.compacted { return False; }
    p: M | None = st.head;
    if p is None { return False; }
    if p.mid == mid {
        nx: list[M] = ([p ->:Next:->])[?:M];
        if len(nx) > 0 { st.head = nx[0]; } else { st.head = None; st.tail = None; }
    } else {
        while p is not None {
            nx2: list[M] = ([p ->:Next:->])[?:M];
            if len(nx2) == 0 { p = None; break; }
            if nx2[0].mid == mid {
                rest: list[M] = ([nx2[0] ->:Next:->])[?:M];
                if len(rest) > 0 { p +>: Next:+> rest[0]; } else { st.tail = p; }
                break;
            }
            p = nx2[0];
        }
    }
    nb: dict[str, M] = {};
    for k in st.byid {
        if k != mid { nb[k] = st.byid[k]; }
    }
    st.byid = nb;
    return True;
}

# walkers ------------------------------------------------------------------

walker Ctx {
    has seen: list[str] = [];
    has claimed: dict[str, bool] = {};
    has sum_done: str = "";
    can step_m with M entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        if here.compacted {
            if self.sum_done == "" {
                ss: list[Sum] = ([here <-:Covers:-])[?:Sum];
                if len(ss) > 0 {
                    self.seen.append(ss[0].mid);
                    self.sum_done = ss[0].mid;
                    print(self.sum_done);
                }
            }
        } else {
            self.seen.append(here.mid);
            print(here.mid);
        }
        visit [here ->:Next:->];
    }
}

walker Dcp {
    has seen: list[str] = [];
    has claimed: dict[str, bool] = {};
    can dc_m with M entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.seen.append(here.mid);
        print(here.mid);
        visit [here ->:Next:->];
        visit ([here <-:Covers:-])[?:Sum];
    }
    can dc_s with Sum entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.seen.append(here.mid);
        print(here.mid);
        visit ([here ->:Covers:->])[?:M];
    }
}
