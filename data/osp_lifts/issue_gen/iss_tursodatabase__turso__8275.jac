node CteQueue {
    has qid: str;
    has queue_order: str = "";
    has seq_next: int = 0;
    has kind: str = "";
}
node QueueRow {
    has rid: int;
    has seq: int = 0;
    has payload: int = 0;
    has alive: bool = True;
}
edge Handles {}
edge Holds {}
edge Next {}

walker CollectPayloads {
    has claimed: dict[str, bool] = {};
    has out: list[int] = [];
    can start with CteQueue entry {
        if str(here.qid) in self.claimed { skip; }
        self.claimed[str(here.qid)] = True;
        print("queue " + here.qid);
        for r in [here ->:Holds:->][?:QueueRow] {
            if r.alive { visit :0: [r]; }
        }
    }
    can step with QueueRow entry {
        if str(here.rid) in self.claimed { skip; }
        self.claimed[str(here.rid)] = True;
        print(str(here.payload));
        if here.alive { self.out.append(here.payload); }
        for nxt in [here ->:Next:->][?:QueueRow] {
            visit :0: [nxt];
        }
    }
}

with entry {
    dq: CteQueue = CteQueue(qid="demo", queue_order="", seq_next=0, kind="table");
    root +>:Handles:+> dq;
    w: CollectPayloads = dq spawn CollectPayloads();
    print("ready " + str(len(w.out)));
}

def make_queue(qid: str, queue_order: str) -> CteQueue {
    kind: str = "table";
    if queue_order != "" { kind = "index"; }
    q: CteQueue = CteQueue(qid=qid, queue_order=queue_order, seq_next=0, kind=kind);
    root +>:Handles:+> q;
    return q;
}
def queue_kind(q: CteQueue) -> str { return q.kind; }
def enqueue(q: CteQueue, payload: int) -> QueueRow {
    q.seq_next = q.seq_next + 1;
    row: QueueRow = QueueRow(rid=q.seq_next, seq=q.seq_next, payload=payload, alive=True);
    q +>:Holds:+> row;
    return row;
}
def dequeue(q: CteQueue) -> int | None {
    rows: list[QueueRow] = [q ->:Holds:->][?:QueueRow];
    best: QueueRow | None = None;
    for r in rows {
        if r.alive {
            if best == None { best = r; }
            else {
                b: QueueRow = best as QueueRow;
                if r.seq < b.seq { best = r; }
            }
        }
    }
    if best == None { return None; }
    br: QueueRow = best as QueueRow;
    br.alive = False;
    return br.payload;
}
def list_queue(q: CteQueue) -> list[int] {
    w: CollectPayloads = q spawn CollectPayloads();
    return w.out;
}
def queue_size(q: CteQueue) -> int {
    rows: list[QueueRow] = [q ->:Holds:->][?:QueueRow];
    cnt: int = 0;
    for r in rows { if r.alive { cnt = cnt + 1; } }
    return cnt;
}
def find_queue(qid: str) -> CteQueue | None {
    cand: list[CteQueue] = [root ->:Handles:->][?:CteQueue];
    for c in cand { if c.qid == qid { return c; } }
    return None;
}
