"""openclaw/openclaw#47320 — recursive subagent listing."""

node Subagent {
    has sid: str;
    has label: str;
    has status: str;
    has runtime: str;
    has model: str;
    has parent_key: str = "";
}

edge Spawns {}

walker ListWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 1;
    has unlimited: bool = False;
    has depth_by_sid: dict[str, int] = {};
    has rows: list[dict] = [];

    can collect with Subagent entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        d: int = 0;
        if here.sid in self.depth_by_sid {
            d = self.depth_by_sid[here.sid];
        }
        if d > 0 {
            row: dict = {};
            row["label"] = here.label;
            row["status"] = here.status;
            row["runtime"] = here.runtime;
            row["model"] = here.model;
            row["parent_session_key"] = here.parent_key;
            row["depth"] = d;
            self.rows.append(row);
        }
        if self.unlimited or d < self.max_depth {
            kids: list[Subagent] = [here ->:Spawns:->][?:Subagent];
            for kid in kids {
                self.depth_by_sid[kid.sid] = d + 1;
                visit :0: [kid];
            }
        }
        print("list", here.sid, d);
    }
}

walker FindWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has hit: Subagent | None = None;

    can seek with Subagent entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid == self.target {
            self.hit = here;
            disengage;
        }
        kids: list[Subagent] = [here ->:Spawns:->][?:Subagent];
        for kid in kids {
            visit :0: [kid];
        } else {
            disengage;
        }
        print("find", here.sid);
    }
}

def sort_rows(rows: list[dict]) -> list[dict] {
    keys: list[str] = [];
    for r in rows {
        keys.append(str(r["depth"]) + "|" + (r["label"] as str));
    }
    out: list[dict] = [];
    used: dict[str, bool] = {};
    i: int = 0;
    while i < len(rows) {
        best: int = -1;
        best_k: str = "";
        t: int = 0;
        while t < len(rows) {
            k: str = keys[t];
            if not (k in used) {
                if best < 0 or k < best_k {
                    best = t;
                    best_k = k;
                }
            }
            t += 1;
        }
        used[best_k] = True;
        out.append(rows[best]);
        i += 1;
    }
    return out;
}

def make_agent(sid: str, label: str, status: str, runtime: str, model: str) -> Subagent {
    ag = Subagent(sid=sid, label=label, status=status, runtime=runtime, model=model);
    return ag;
}

def connect_child(parent: Subagent, child: Subagent) -> None {
    child.parent_key = parent.sid;
    parent +>:Spawns:+> child;
}

def list_subagents(graph_root: Subagent, depth: int | None = None, recursive: bool = False) -> list[dict] {
    lim: int = 1;
    unlim: bool = False;
    if recursive {
        unlim = True;
    } else {
        if depth != None {
            lim = depth;
        }
    }
    lw = graph_root spawn ListWalker(max_depth=lim, unlimited=unlim);
    return sort_rows(lw.rows);
}

def find_subagent(graph_root: Subagent, sid: str) -> Subagent | None {
    fw = graph_root spawn FindWalker(target=sid);
    return fw.hit;
}
