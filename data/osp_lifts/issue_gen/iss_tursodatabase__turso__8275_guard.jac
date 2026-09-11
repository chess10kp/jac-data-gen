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

test "queue kind table vs index" {
    q1 = make_queue("k1", "");
    assert(queue_kind(q1) == "table");
    q2 = make_queue("k2", "priority");
    assert(queue_kind(q2) == "index");
}
test "fifo order and size" {
    q = make_queue("fifo", "");
    enqueue(q, 10);
    enqueue(q, 20);
    enqueue(q, 30);
    assert(queue_size(q) == 3);
    out: list[int] = list_queue(q);
    assert(sorted(out) == [10, 20, 30]);
    v = dequeue(q);
    assert(v == 10);
    assert(queue_size(q) == 2);
    out2: list[int] = list_queue(q);
    assert(sorted(out2) == [20, 30]);
}
test "diamond revisit deduped" {
    q = make_queue("diamond", "");
    r1 = enqueue(q, 1);
    r2: QueueRow = QueueRow(rid=100, seq=100, payload=2, alive=True);
    r3: QueueRow = QueueRow(rid=101, seq=101, payload=3, alive=True);
    r4: QueueRow = QueueRow(rid=102, seq=102, payload=4, alive=True);
    r1 +>:Next:+> r2;
    r1 +>:Next:+> r3;
    r2 +>:Next:+> r4;
    r3 +>:Next:+> r4;
    out: list[int] = list_queue(q);
    assert(len(out) == 4);
    assert(sorted(out) == [1, 2, 3, 4]);
    out2: list[int] = list_queue(q);
    assert(sorted(out2) == [1, 2, 3, 4]);
}
test "unknown queue tolerance" {
    got = find_queue("no_such_qid_999");
    assert(got == None);
    q = make_queue("known", "");
    got2 = find_queue("known");
    assert(got2 != None);
    gg: CteQueue = got2 as CteQueue;
    assert(gg.qid == "known");
}
test "empty queue edge cases" {
    q = make_queue("empty", "");
    assert(queue_size(q) == 0);
    assert(list_queue(q) == []);
    v = dequeue(q);
    assert(v == None);
    enqueue(q, 42);
    assert(queue_size(q) == 1);
    assert(dequeue(q) == 42);
    assert(queue_size(q) == 0);
}
