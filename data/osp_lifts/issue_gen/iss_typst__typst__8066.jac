"""typst/typst#8066 — recursive matrix show rule expansion with cycle guard."""

node Anchor {}

node Mat {
    has cid: str;
}

edge RowRef {}

node MatStore {
    has by_cid: dict[str, Mat] = {};
}

def build_mat_store(entries: list[tuple[str, list[str]]]) -> MatStore {
    st = MatStore(by_cid={});
    root ++> st;
    mat_index: dict[str, Mat] = {};
    for ent in entries {
        cid = ent[0];
        row_cids = ent[1];
        nd = Mat(cid=cid);
        st ++> nd;
        mat_index[cid] = nd;
    }
    for ent in entries {
        cid = ent[0];
        row_cids = ent[1];
        parent = mat_index[cid];
        for rc in row_cids {
            if rc in mat_index {
                ch = mat_index[rc];
                parent +>:RowRef:+> ch;
            }
        }
    }
    st.by_cid = mat_index;
    return st;
}

walker ShowWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has blocked: list[str] = [];
    has expansions: int = 0;

    can expand with Mat entry {
        if here.cid in self.claimed {
            self.blocked.append(here.cid);
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        self.expansions += 1;
        kids: list[Mat] = [];
        for ch in [here ->:RowRef:->][?:Mat] {
            kids.append(ch);
        }
        visit :0: kids;
        print({"show": here.cid, "exp": self.expansions});
    }
}

def apply_show_rule(store: MatStore, start_id: str) -> dict[str, any] {
    out: dict[str, any] = {};
    out["order"] = [];
    out["blocked"] = [];
    out["expansions"] = 0;
    out["ok"] = False;
    if start_id not in store.by_cid {
        return out;
    }
    start_nd = store.by_cid[start_id];
    w = start_nd spawn ShowWalker(
        claimed={},
        order=[],
        blocked=[],
        expansions=0,
    );
    out["order"] = w.order;
    blocked_sorted: list[str] = [];
    for b in sorted(w.blocked) {
        blocked_sorted.append(b);
    }
    out["blocked"] = blocked_sorted;
    out["expansions"] = w.expansions;
    out["ok"] = True;
    return out;
}
