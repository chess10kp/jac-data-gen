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
