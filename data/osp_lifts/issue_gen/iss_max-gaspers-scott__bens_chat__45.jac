"""Lift max-gaspers-scott/bens_chat#45 — flat subtree fetch + client treeify."""

node Message {
    has message_id: str;
    has parent_id: str = "";
    has body: str = "";
    has sent_at: str = "";
}

edge Reply {}

walker SubtreeFlat {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 2;
    has depth: int = 1;
    has rows: list[dict] = [];
    has start_parent_id: str = "";

    can anchor_hop with Message entry {
        if here.message_id != self.start_parent_id {
            disengage;
        }
        kids: list[Message] = [here ->:Reply:->][?:Message];
        if kids {
            for ch in kids {
                self.depth = 1;
                visit :0: [ch];
            }
        } else {
            disengage;
        }
    }

    can collect with Message entry {
        if here.message_id in self.claimed {
            skip;
        }
        self.claimed[here.message_id] = True;
        if self.depth > self.max_depth {
            disengage;
        }
        row: dict = {};
        row["message_id"] = here.message_id;
        row["parent_id"] = here.parent_id;
        row["body"] = here.body;
        row["sent_at"] = here.sent_at;
        row["depth"] = self.depth;
        self.rows.append(row);
        if self.depth >= self.max_depth {
            disengage;
        }
        kids: list[Message] = [here ->:Reply:->][?:Message];
        nd: int = self.depth + 1;
        for ch in kids {
            self.depth = nd;
            visit :0: [ch];
        }
    }
}

def find_message(mid: str) -> Message | None {
    stack: list[object] = [];
    stack.append(root);
    i: int = 0;
    while i < len(stack) {
        cur: object = stack[i];
        i = i + 1;
        if cur is Message {
            m: Message = cur;
            if m.message_id == mid {
                return m;
            }
        }
        chs: list[object] = [cur -->];
        for ch in chs {
            stack.append(ch);
        }
    }
    return None;
}

def sort_rows(rows: list[dict]) -> list[dict] {
    out: list[dict] = [];
    for r in rows {
        out.append(r);
    }
    n: int = len(out);
    for i in range(n) {
        for j in range(i + 1, n) {
            a: dict = out[i];
            b: dict = out[j];
            da: int = a["depth"];
            db: int = b["depth"];
            swap: bool = False;
            if db < da {
                swap = True;
            } elif db == da {
                sa: str = a["sent_at"];
                sb: str = b["sent_at"];
                if sb < sa {
                    swap = True;
                }
            }
            if swap {
                tmp: dict = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
        }
    }
    return out;
}

def connect_messages(specs: list[dict]) -> list[Message] {
    nodes: list[Message] = [];
    id_map: dict[str, Message] = {};
    for s in specs {
        pid: str = "";
        if "parent_id" in s {
            pid = s["parent_id"];
        }
        body: str = "";
        if "body" in s {
            body = s["body"];
        }
        sent: str = "";
        if "sent_at" in s {
            sent = s["sent_at"];
        }
        m = Message(
            message_id=s["message_id"],
            parent_id=pid,
            body=body,
            sent_at=sent
        );
        root ++> m;
        nodes.append(m);
        id_map[s["message_id"]] = m;
    }
    for s in specs {
        pid2: str = "";
        if "parent_id" in s {
            pid2 = s["parent_id"];
        }
        if pid2 in id_map {
            parent_n: Message = id_map[pid2];
            child_n: Message = id_map[s["message_id"]];
            parent_n +>:Reply:+> child_n;
        }
    }
    return nodes;
}

def fetch_subtree_flat(parent_id: str, max_depth: int) -> list[dict] {
    if max_depth < 1 {
        return [];
    }
    anchor: Message | None = find_message(parent_id);
    if anchor is None {
        return [];
    }
    w = anchor spawn SubtreeFlat(
        claimed={},
        max_depth=max_depth,
        depth=1,
        rows=[],
        start_parent_id=parent_id
    );
    print w.rows;
    return sort_rows(w.rows);
}

def treeify_messages(rows: list[dict]) -> list[dict] {
    by_id: dict[str, dict] = {};
    id_set: dict[str, bool] = {};
    for r in rows {
        id_set[r["message_id"]] = True;
    }
    for r in rows {
        tree_item: dict = {};
        tree_item["message_id"] = r["message_id"];
        tree_item["parent_id"] = r["parent_id"];
        tree_item["body"] = r["body"];
        tree_item["sent_at"] = r["sent_at"];
        tree_item["depth"] = r["depth"];
        tree_item["replies"] = [];
        by_id[r["message_id"]] = tree_item;
    }
    roots: list[dict] = [];
    for r in rows {
        mid: str = r["message_id"];
        pid: str = r["parent_id"];
        cur: dict = by_id[mid];
        if pid in id_set {
            parent_rec: dict = by_id[pid];
            pr: list = parent_rec["replies"] as list;
            pr.append(cur);
        } else {
            roots.append(cur);
        }
    }
    return sort_rows(roots);
}
