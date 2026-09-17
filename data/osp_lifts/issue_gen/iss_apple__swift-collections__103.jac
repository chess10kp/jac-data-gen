"""Stable ordered slots with stable ids for adjacency — apple/swift-collections#103."""

node SHead {}

node Slot {
    has sid: int;
    has payload: str;
    has alive: bool = True;
}

edge SeqNext {}

node GHead {}

node Vtx {
    has vid: int;
    has label: str;
    has alive: bool = True;
}

edge Adj {}

obj seq_state {
    has head: SHead | None = None;
    has tail: Slot | None = None;
    has sid_gen: int = 0;
    has by_id: dict[int, Slot] = {};
}

obj graph_state {
    has head: GHead | None = None;
    has vid_gen: int = 0;
    has by_id: dict[int, Vtx] = {};
}

walker OrderCollect {
    has claimed: dict[int, bool] = {};
    has vals: list[str] = {};
    can step_head with SHead entry {
        root spawn OrderCollect(self.claimed, self.vals);
        print ["order:root"];
        nxt: list[Slot] = [];
        for ch in [here ->:SeqNext:->][?:Slot] {
            nxt.append(ch);
        }
        if nxt != [] {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
    can step_slot with Slot entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        if here.alive {
            self.vals.append(here.payload);
        }
        nxt: list[Slot] = [];
        for ch in [here ->:SeqNext:->][?:Slot] {
            nxt.append(ch);
        }
        if nxt != [] {
            visit :0: nxt;
        } else {
            disengage;
        }
        print ["order:slot", here.sid];
    }
}

walker IndexFind {
    has claimed: dict[int, bool] = {};
    has target: str;
    has found: int | None = None;
    can step_head with SHead entry {
        root spawn IndexFind(self.claimed, self.target, self.found);
        print ["find:root"];
        if self.found is not None {
            disengage;
        }
        nxt: list[Slot] = [];
        for ch in [here ->:SeqNext:->][?:Slot] {
            nxt.append(ch);
        }
        if nxt != [] {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
    can step_slot with Slot entry {
        if self.found is not None {
            disengage;
        }
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        if here.alive and here.payload == self.target {
            self.found = here.sid;
            disengage;
        }
        nxt: list[Slot] = [];
        for ch in [here ->:SeqNext:->][?:Slot] {
            nxt.append(ch);
        }
        if nxt != [] {
            visit :0: nxt;
        } else {
            disengage;
        }
        print ["find:slot", here.sid];
    }
}

walker NeighborCollect {
    has claimed: dict[int, bool] = {};
    has nids: list[int] = {};
    can step_vtx with Vtx entry {
        root spawn NeighborCollect(self.claimed, self.nids);
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        nbrs: list[Vtx] = [];
        for ch in [here ->:Adj:->][?:Vtx] {
            if ch.alive {
                nbrs.append(ch);
            }
        }
        for nb in nbrs {
            hit = False;
            for existing in self.nids {
                if existing == nb.vid {
                    hit = True;
                    break;
                }
            }
            if not hit {
                self.nids.append(nb.vid);
            }
        }
        print ["nbr:src", here.vid];
        disengage;
    }
}

walker ReachCollect {
    has claimed: dict[int, bool] = {};
    has reached: list[int] = {};
    can step_vtx with Vtx entry {
        root spawn ReachCollect(self.claimed, self.reached);
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        if here.alive {
            self.reached.append(here.vid);
        }
        nxt: list[Vtx] = [];
        for ch in [here ->:Adj:->][?:Vtx] {
            if ch.alive {
                nxt.append(ch);
            }
        }
        if nxt != [] {
            visit :0: nxt;
        } else {
            disengage;
        }
        print ["reach", here.vid];
    }
}

def make_store -> seq_state {
    hd = SHead;
    root ++> hd;
    st = seq_state(head=hd, tail=None, sid_gen=0, by_id={});
    return st;
}

def append_val(st: seq_state, value: str) -> int {
    sid = st.sid_gen;
    st.sid_gen = sid + 1;
    sl = Slot(sid=sid, payload=value, alive=True);
    st.by_id[sid] = sl;
    if st.tail is None {
        if st.head is not None {
            st.head +>:SeqNext:+> sl;
        }
    } else {
        st.tail +>:SeqNext:+> sl;
    }
    st.tail = sl;
    return sid;
}

def get_val(st: seq_state, sid: int) -> str | None {
    if sid not in st.by_id {
        return None;
    }
    sl = st.by_id[sid] as Slot;
    if not sl.alive {
        return None;
    }
    return sl.payload;
}

def remove_val(st: seq_state, sid: int) -> bool {
    if sid not in st.by_id {
        return False;
    }
    sl = st.by_id[sid] as Slot;
    if not sl.alive {
        return False;
    }
    sl.alive = False;
    return True;
}

def ordered_values(st: seq_state) -> list[str] {
    if st.head is None {
        return [];
    }
    wk = st.head spawn OrderCollect(claimed={}, vals=[]);
    return wk.vals;
}

def first_index(st: seq_state, value: str) -> int | None {
    if st.head is None {
        return None;
    }
    wk = st.head spawn IndexFind(claimed={}, target=value, found=None);
    return wk.found;
}

def make_graph -> graph_state {
    gh = GHead;
    root ++> gh;
    g = graph_state(head=gh, vid_gen=0, by_id={});
    return g;
}

def add_vertex(g: graph_state, label: str) -> int {
    vid = g.vid_gen;
    g.vid_gen = vid + 1;
    vx = Vtx(vid=vid, label=label, alive=True);
    g.by_id[vid] = vx;
    if g.head is not None {
        g.head +>:Adj:+> vx;
    }
    return vid;
}

def add_edge(g: graph_state, src: int, dst: int) -> None {
    if src not in g.by_id {
        return;
    }
    if dst not in g.by_id {
        return;
    }
    sv = g.by_id[src] as Vtx;
    dv = g.by_id[dst] as Vtx;
    if not sv.alive {
        return;
    }
    if not dv.alive {
        return;
    }
    sv +>:Adj:+> dv;
}

def get_label(g: graph_state, vid: int) -> str | None {
    if vid not in g.by_id {
        return None;
    }
    vx = g.by_id[vid] as Vtx;
    if not vx.alive {
        return None;
    }
    return vx.label;
}

def remove_vertex(g: graph_state, vid: int) -> bool {
    if vid not in g.by_id {
        return False;
    }
    vx = g.by_id[vid] as Vtx;
    if not vx.alive {
        return False;
    }
    vx.alive = False;
    return True;
}

def neighbors(g: graph_state, vid: int) -> list[int] {
    if vid not in g.by_id {
        return [];
    }
    vx = g.by_id[vid] as Vtx;
    if not vx.alive {
        return [];
    }
    wk = vx spawn NeighborCollect(claimed={}, nids=[]);
    out: list[int] = [];
    for nid in wk.nids {
        out.append(nid);
    }
    out.sort();
    return out;
}

def reachable(g: graph_state, start: int) -> list[int] {
    if start not in g.by_id {
        return [];
    }
    vx = g.by_id[start] as Vtx;
    if not vx.alive {
        return [];
    }
    wk = vx spawn ReachCollect(claimed={}, reached=[]);
    out: list[int] = [];
    for rid in wk.reached {
        out.append(rid);
    }
    out.sort();
    return out;
}
