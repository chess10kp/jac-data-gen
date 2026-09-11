"""AtyaLibraries/Messaging.Outbox#5 — relay dependency claim, backoff, and lineage audit."""

node OutboxMessage {
    has mid: str;
    has contract: str;
    has schema: int;
    has status: str;
    has next_attempt: int = 0;
    has attempt: int = 0;
    has diag: str = "";
}

edge Requires {}

obj OutboxStore {
    has messages: dict[str, OutboxMessage] = {};
    has claims: dict[str, str] = {};
}

walker PrereqCloseWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with OutboxMessage entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        if here.mid != self.origin { self.hits.append(here.mid); }
        prereqs = [here ->:Requires:->][?:OutboxMessage];
        nms: list[str] = [];
        for n in prereqs { nms.append(n.mid); }
        for nm in sorted(nms) {
            for n in prereqs {
                if n.mid == nm {
                    n spawn PrereqCloseWalk(
                        claimed=self.claimed,
                        hits=self.hits,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

walker DepPathWalk {
    has trail: list[str] = [];
    has on_path: dict[str, bool] = {};
    has paths: list[list[str]] = [];
    has target: str = "";
    has max_depth: int = 8;

    can step with OutboxMessage entry {
        if here.mid in self.on_path { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.mid);
        nop: dict[str, bool] = {**self.on_path, here.mid: True};
        if here.mid == self.target {
            if len(nt) > 1 {
                row: list[str] = [];
                for x in nt { row.append(x); }
                self.paths.append(row);
            }
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        prereqs = [here ->:Requires:->][?:OutboxMessage];
        nms: list[str] = [];
        for n in prereqs { nms.append(n.mid); }
        for nm in sorted(nms) {
            for n in prereqs {
                if n.mid == nm {
                    n spawn DepPathWalk(
                        trail=nt,
                        on_path=nop,
                        paths=self.paths,
                        target=self.target,
                        max_depth=self.max_depth,
                    );
                }
            }
        }
    }
}

def load_outbox_store(
    messages: list[tuple[str, str, int, str]],
    depends: list[tuple[str, str]],
    next_attempt: dict[str, int] | None = None,
) -> OutboxStore {
    store = OutboxStore();
    sched = next_attempt;
    if sched is None { sched = {}; }
    for (mid, contract, schema, status) in messages {
        na = 0;
        if mid in sched { na = sched[mid]; }
        nd = OutboxMessage(
            mid=mid,
            contract=contract,
            schema=schema,
            status=status,
            next_attempt=na,
            attempt=0,
            diag="",
        );
        root ++> nd;
        store.messages[mid] = nd;
    }
    for (msg, prereq) in depends {
        if msg in store.messages and prereq in store.messages {
            m = store.messages[msg];
            p = store.messages[prereq];
            seen = False;
            for ex in [m ->:Requires:->][?:OutboxMessage] {
                if ex.mid == prereq { seen = True; }
            }
            if not seen { m +>:Requires:+> p; }
        }
    }
    return store;
}

def prerequisite_closure(store: OutboxStore, message_id: str) -> list[str] {
    if message_id not in store.messages { return []; }
    nd = store.messages[message_id];
    w = nd spawn PrereqCloseWalk(claimed={}, hits=[], origin=message_id);
    return sorted(w.hits);
}

def dependency_paths(
    store: OutboxStore,
    source: str,
    target: str,
    max_depth: int = 8,
) -> list[list[str]] {
    if source not in store.messages or target not in store.messages { return []; }
    nd = store.messages[source];
    w = nd spawn DepPathWalk(
        trail=[], on_path={}, paths=[], target=target, max_depth=max_depth
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def blocked_by(store: OutboxStore, message_id: str) -> list[str] {
    if message_id not in store.messages { return []; }
    nd = store.messages[message_id];
    out: list[str] = [];
    prereqs = [nd ->:Requires:->][?:OutboxMessage];
    nms: list[str] = [];
    for n in prereqs { nms.append(n.mid); }
    for nm in sorted(nms) {
        for n in prereqs {
            if n.mid == nm and n.status != "published" {
                out.append(nm);
            }
        }
    }
    return out;
}

def stable_identity(store: OutboxStore, message_id: str) -> tuple[str, int] {
    nd = store.messages.get(message_id, None);
    if nd is None { return ("", 0); }
    return (nd.contract, nd.schema);
}

def claimable_ids(
    store: OutboxStore,
    owner: str,
    tick: int,
    limit: int = 10,
) -> list[str] {
    out: list[str] = [];
    keys: list[str] = [];
    for k in store.messages.keys() { keys.append(k); }
    for mid in sorted(keys) {
        nd = store.messages[mid];
        if nd.status != "pending" { continue; }
        if nd.next_attempt > tick { continue; }
        holder = store.claims.get(mid, None);
        if holder is not None { continue; }
        if len(blocked_by(store, mid)) > 0 { continue; }
        out.append(mid);
        if len(out) >= limit { break; }
    }
    return out;
}

def claim_batch(
    store: OutboxStore,
    owner: str,
    message_ids: list[str],
    tick: int,
) -> list[str] {
    claimed: list[str] = [];
    ids: list[str] = [];
    for x in message_ids { ids.append(x); }
    for mid in sorted(ids) {
        if mid not in store.messages { continue; }
        nd = store.messages[mid];
        if nd.status != "pending" or nd.next_attempt > tick { continue; }
        holder = store.claims.get(mid, None);
        if holder is not None { continue; }
        if len(blocked_by(store, mid)) > 0 { continue; }
        store.claims[mid] = owner;
        claimed.append(mid);
    }
    return claimed;
}

def record_failure(
    store: OutboxStore,
    message_id: str,
    tick: int,
    diag: str,
) -> int {
    nd = store.messages.get(message_id, None);
    if nd is None { return -1; }
    nd.attempt += 1;
    delay = int(min(2 ** nd.attempt, 64));
    nd.next_attempt = tick + delay;
    nd.status = "failed";
    clipped = diag;
    if len(clipped) > 120 { clipped = clipped[:120]; }
    nd.diag = clipped;
    store.claims.pop(message_id, None);
    return nd.next_attempt;
}

test "diamond prerequisite closure dedupes shared base" {
    store = load_outbox_store(
        [
            ("top", "c1", 1, "pending"),
            ("left", "c2", 2, "published"),
            ("right", "c3", 3, "published"),
            ("base", "c4", 4, "published"),
        ],
        [("top", "left"), ("top", "right"), ("left", "base"), ("right", "base")],
    );
    assert prerequisite_closure(store, "top") == ["base", "left", "right"];;
    assert prerequisite_closure(store, "base") == [];;
}

test "unknown id tolerance across lineage and claim queries" {
    store = load_outbox_store(
        [("only", "svc", 7, "pending")],
        [("only", "ghost"), ("ghost", "only")],
    );
    assert prerequisite_closure(store, "ghost") == [];;
    assert dependency_paths(store, "only", "ghost") == [];;
    assert dependency_paths(store, "ghost", "only") == [];;
    assert blocked_by(store, "ghost") == [];;
    assert stable_identity(store, "ghost") == ("", 0);;
    assert record_failure(store, "ghost", 9, "nope") == -1;;
    assert prerequisite_closure(store, "only") == [];;
    assert claim_batch(store, "w1", ["ghost", "only"], 0) == ["only"];;
}

test "cycle prerequisite closure skips revisit via claim map" {
    store = load_outbox_store(
        [
            ("a", "c", 1, "pending"),
            ("b", "c", 1, "pending"),
            ("c", "c", 1, "pending"),
        ],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert prerequisite_closure(store, "a") == ["b", "c"];;
}

test "dependency paths diamond fanout and max depth boundary" {
    store = load_outbox_store(
        [
            ("a", "c", 1, "published"),
            ("b", "c", 1, "published"),
            ("c", "c", 1, "published"),
            ("d", "c", 1, "published"),
        ],
        [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
    );
    assert dependency_paths(store, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]];;
    assert dependency_paths(store, "a", "d", max_depth=2) == [];;
    assert dependency_paths(store, "d", "a") == [];;
    assert dependency_paths(store, "a", "a") == [];;
}

test "claim batch blocks ownership next attempt and failure backoff" {
    store = load_outbox_store(
        [
            ("base", "c", 1, "pending"),
            ("top", "c", 2, "pending"),
            ("free", "c", 3, "pending"),
        ],
        [("top", "base")],
        {"top": 5},
    );
    assert blocked_by(store, "top") == ["base"];;
    assert "base" in claimable_ids(store, "r1", 0, 10);;
    assert "free" in claimable_ids(store, "r1", 0, 10);;
    assert claim_batch(store, "r1", ["free", "top"], 0) == ["free"];;
    assert claim_batch(store, "r2", ["free"], 0) == [];;
    # same owner reclaim blocked when already claimed
    assert claim_batch(store, "r1", ["free"], 0) == [];;
    store.messages["base"].status = "published";
    assert "top" not in claimable_ids(store, "r1", 4, 10);;
    assert "top" in claimable_ids(store, "r1", 5, 10);;
    long_diag = "";
    for i in range(121) { long_diag = long_diag + "z"; }
    assert record_failure(store, "base", 10, long_diag) == 12;;
    assert len(store.messages["base"].diag) == 120;;
    assert store.claims.get("base", None) is None;;
    for i in range(6) {
        record_failure(store, "base", 0, "e");
    }
    assert record_failure(store, "base", 0, "e") == 64;;
}
