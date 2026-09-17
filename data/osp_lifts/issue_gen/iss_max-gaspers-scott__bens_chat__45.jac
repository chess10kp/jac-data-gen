"""Message subtree fetch and client retreeify — max-gaspers-scott/bens_chat#45."""

node Message {
    has message_id: str;
    has parent_id: str = "";
    has body: str = "";
    has sent_at: int = 0;
}

edge Reply {}

node MsgRoot {
    has by_id: dict[str, Message] = {};
}

walker SubtreeWalker {
    has max_depth: int;
    has depth: int;
    has claimed: dict[str, bool] = {};
    has out_rows: list[dict] = {};

    can walk with Message entry {
        if here.message_id in self.claimed {
            skip;
        }
        self.claimed[here.message_id] = True;
        if self.depth > 0 {
            row: dict = {};
            row["message_id"] = here.message_id;
            row["parent_id"] = here.parent_id;
            row["body"] = here.body;
            row["sent_at"] = here.sent_at;
            row["depth"] = self.depth;
            self.out_rows.append(row);
            print(here.message_id + " " + str(self.depth));
        }
        if self.depth >= self.max_depth {
            disengage;
        }
        kids: list[Message] = [];
        for ch in [here ->:Reply:->][?:Message] {
            kids.append(ch);
        }
        kids = sort_messages_by_sent_at(kids);
        ki: int = 0;
        while ki < len(kids) {
            ch: Message = kids[ki];
            ch spawn SubtreeWalker(
                max_depth=self.max_depth,
                depth=self.depth + 1,
                claimed=self.claimed,
                out_rows=self.out_rows
            );
            ki += 1;
        }
        disengage;
    }
}

def sort_messages_by_sent_at(nodes: list[Message]) -> list[Message] {
    out: list[Message] = [];
    i: int = 0;
    while i < len(nodes) {
        out.append(nodes[i]);
        i += 1;
    }
    j: int = 1;
    while j < len(out) {
        k: int = j;
        while k > 0 {
            a: Message = out[k];
            b: Message = out[k - 1];
            if a.sent_at >= b.sent_at {
                break;
            }
            out[k] = b;
            out[k - 1] = a;
            k -= 1;
        }
        j += 1;
    }
    return out;
}

def sort_subtree_rows(rows: list[dict]) -> list[dict] {
    out: list[dict] = [];
    i: int = 0;
    while i < len(rows) {
        out.append(rows[i]);
        i += 1;
    }
    j: int = 1;
    while j < len(out) {
        k: int = j;
        while k > 0 {
            a: dict = out[k] as dict;
            b: dict = out[k - 1] as dict;
            ad: int = a["depth"] as int;
            bd: int = b["depth"] as int;
            as_: int = a["sent_at"] as int;
            bs: int = b["sent_at"] as int;
            if ad < bd or (ad == bd and as_ < bs) {
                break;
            }
            out[k] = b;
            out[k - 1] = a;
            k -= 1;
        }
        j += 1;
    }
    return out;
}

def build_store(rows: list[dict]) -> MsgRoot {
    store = MsgRoot();
    ri: int = 0;
    while ri < len(rows) {
        row: dict = rows[ri] as dict;
        mid: str = row["message_id"] as str;
        pid: str = row["parent_id"] as str;
        nd = Message(
            message_id=mid,
            parent_id=pid,
            body=row["body"] as str,
            sent_at=row["sent_at"] as int
        );
        store.by_id[mid] = nd;
        root ++> nd;
        ri += 1;
    }
    ri = 0;
    while ri < len(rows) {
        row = rows[ri] as dict;
        pid = row["parent_id"] as str;
        mid = row["message_id"] as str;
        if pid != "" and pid in store.by_id and mid in store.by_id {
            par: Message = store.by_id[pid] as Message;
            kid: Message = store.by_id[mid] as Message;
            par +>:Reply:+> kid;
        }
        ri += 1;
    }
    return store;
}

def subtree_flat(store: MsgRoot, parent_id: str, max_depth: int) -> list[dict] {
    if parent_id not in store.by_id {
        return [];
    }
    parent_nd: Message = store.by_id[parent_id] as Message;
    w = parent_nd spawn SubtreeWalker(max_depth=max_depth, depth=0);
    return sort_subtree_rows(w.out_rows);
}

def flat_to_tree(rows: list[dict]) -> dict[str, any] | None {
    if len(rows) == 0 {
        return None;
    }
    by_id: dict[str, dict] = {};
    i: int = 0;
    while i < len(rows) {
        row: dict = rows[i] as dict;
        nid: str = row["message_id"] as str;
        node_d: dict = {};
        node_d["message_id"] = nid;
        node_d["parent_id"] = row["parent_id"] as str;
        node_d["body"] = row["body"] as str;
        node_d["sent_at"] = row["sent_at"] as int;
        node_d["depth"] = row["depth"] as int;
        node_d["children"] = [];
        by_id[nid] = node_d;
        i += 1;
    }
    roots: list[dict] = [];
    for nid in by_id {
        nd: dict = by_id[nid] as dict;
        pid: str = nd["parent_id"] as str;
        if pid == "" or pid not in by_id {
            roots.append(nd);
        } else {
            par: dict = by_id[pid] as dict;
            chs: list[dict] = par["children"] as list[dict];
            chs.append(nd);
        }
    }
    if len(roots) != 1 {
        return None;
    }
    return roots[0];
}
