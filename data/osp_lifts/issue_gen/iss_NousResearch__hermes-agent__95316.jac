"""NousResearch/hermes-agent#95316 — compression chain tip resolution without N+1 re-walks."""

node Session {
    has id: str;
    has end_reason: str = "";
    has last_active: int = 0;
}

edge CompressLink {}

node SessionGraph {
    has nodes: dict[str, Session] = {};
}

walker TipWalker {
    has claimed: dict[str, bool] = {};
    has tip_id: str = "";
    can step with Session entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        print(here.id);
        if here.end_reason != "compression" {
            self.tip_id = here.id;
            disengage;
        }
        kids: list[Session] = [];
        for ch in [here ->:CompressLink:->][?:Session] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            self.tip_id = here.id;
            disengage;
        }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can tour with Session entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        print(here.id);
        kids: list[Session] = [];
        for ch in [here ->:CompressLink:->][?:Session] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        }
    }
}

def make_store() -> SessionGraph {
    return SessionGraph(nodes={});
}

def add_session_record(g: SessionGraph, sid: str, end_reason: str, last_active: int) -> Session {
    s = Session(id=sid, end_reason=end_reason, last_active=last_active);
    g.nodes[sid] = s;
    root ++> s;
    return s;
}

def add_compress_link(parent: Session, child: Session) -> None {
    parent +>:CompressLink:+> child;
}

def get_compression_tip(g: SessionGraph, session_id: str) -> str {
    if session_id not in g.nodes {
        return session_id;
    }
    s = g.nodes[session_id] as Session;
    w = s spawn TipWalker(claimed={});
    return w.tip_id;
}

def copy_row(row: dict) -> dict {
    out: dict = {};
    for k in row {
        out[k] = row[k];
    }
    return out;
}

def sort_sessions_by_last_active(rows: list[dict]) -> list[dict] {
    n = len(rows);
    i = 0;
    while i < n {
        j = i + 1;
        while j < n {
            ai = rows[i]["last_active"] as int;
            aj = rows[j]["last_active"] as int;
            if aj > ai {
                tmp = rows[i];
                rows[i] = rows[j];
                rows[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return rows;
}

def resolve_compression_tips(g: SessionGraph, sessions: list[dict]) -> dict[str, str] {
    tips: dict[str, str] = {};
    for row in sessions {
        if row["end_reason"] != "compression" {
            continue;
        }
        sid = row["id"] as str;
        tip = get_compression_tip(g, sid);
        if tip != sid {
            tips[sid] = tip;
        }
    }
    return tips;
}

def list_sessions_rich(
    g: SessionGraph,
    sessions: list[dict],
    project_compression_tips: bool,
    include_children: bool,
    order_by_last_active: bool
) -> list[dict] {
    rows: list[dict] = [];
    for row in sessions {
        rows.append(copy_row(row));
    }
    if order_by_last_active {
        rows = sort_sessions_by_last_active(rows);
    }
    if project_compression_tips and not include_children {
        tip_map = resolve_compression_tips(g, rows);
        projected: list[dict] = [];
        for row in rows {
            out = copy_row(row);
            rid = row["id"] as str;
            if rid in tip_map {
                out["tip_id"] = tip_map[rid];
            }
            projected.append(out);
        }
        return projected;
    }
    return rows;
}

with entry {
    g = make_store();
    a = add_session_record(g, "demo_a", "compression", 1);
    b = add_session_record(g, "demo_b", "complete", 2);
    add_compress_link(a, b);
    root spawn DemoWalker(claimed={});
}
