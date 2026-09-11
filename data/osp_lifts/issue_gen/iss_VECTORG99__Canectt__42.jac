"""Schedule invariants, lifted to OSP.

Blocks become nodes chained by typed NestedIn edges (parent
+>:NestedIn:+> child); the DFS parent-chain cycle check and the stack
sweep over children become claim-map walkers. The plain invariant checks
(day range, timezone, byDay, duplicate ids) are domain validation, not
traversal, and stay as loops. Cycle policy: a revisit on the parent chain
is the reported cycle (the renderer hang was an unguarded parent loop).
Ref: VECTORG99/Canectt#42
"""
node Block {
    has bid: str;
    has start: str;
    has end: str;
}

"""parent +>:NestedIn:+> child."""
edge NestedIn {}

glob KNOWN_TZ: set[str] = {"America/Santiago", "UTC", "Europe/Berlin", "Asia/Tokyo"};

obj Schedule {
    has timezone: str = "UTC";
    has day_range: list[str] = [];
    has by_day: list[str] = [];
    has blocks: list[dict] = [];
    has by_id: dict[str, Block] = {};

    def resolve(bid: str) -> Block | None {
        return self.by_id.get(bid);
    }
}

def load_schedule(doc: dict) -> Schedule {
    sched = Schedule();
    sched.timezone = str(doc.get("timezone"));
    sched.day_range = list(doc.get("dayRange"));
    recur = doc.get("recurrence");
    if recur is None {
        sched.by_day = [];
    } else {
        sched.by_day = [str(d) for d in list(recur.get("byDay"))];
    }
    raw_blocks: list[dict] = [];
    for rb in list(doc.get("blocks")) {
        raw_blocks.append(rb);
    }
    sched.blocks = raw_blocks;
    for b in raw_blocks {
        bid = str(b.get("id"));
        if sched.by_id.get(bid) is None {
            blk = Block(bid=bid, start=str(b.get("startTime")), end=str(b.get("endTime")));
            root ++> blk;
            sched.by_id[bid] = blk;
        }
    }
    for b in raw_blocks {
        raw_pid = b.get("parentId");
        if raw_pid is not None {
            pid = str(raw_pid);
            p = sched.by_id.get(pid);
            if p is not None {
                p +>:NestedIn:+> sched.by_id[str(b.get("id"))];
            }
        }
    }
    return sched;
}

walker ParentChain {
    """Ascent the parent chain; a revisit is the cycle (first repeat wins)."""
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};
    has revisit: str = "";

    can step with Block entry {
        if here.bid in self.claimed {
            self.revisit = here.bid;
            disengage;
        }
        self.claimed[here.bid] = True;
        self.chain.append(here.bid);
        visit [here <-:NestedIn:<-] else { disengage; }
    }
}

walker SubtreeWalk {
    """Downward nesting closure, once-only per block (claim map)."""
    has seen: set[str] = set();

    can step with Block entry {
        if here.bid in self.seen {
            skip;
        }
        self.seen.add(here.bid);
        visit [->:NestedIn:->] else { skip; }
    }
}

"""Sorted list of invariant violations (empty when valid)."""
def validate(sched: Schedule) -> list[str] {
    errors: list[str] = [];
    ids: list[str] = [];
    for b in sched.blocks {
        ids.append(str(b.get("id")));
    }
    seen_ids: set[str] = set();
    for i in ids {
        if i in seen_ids {
            errors.append("duplicate id: " + i);
        }
        seen_ids.add(i);
    }
    errors = sorted(errors);

    for b in sorted(sched.blocks, key=by_id_key) {
        raw_pid2 = b.get("parentId");
        if raw_pid2 is not None and sched.resolve(str(raw_pid2)) is None {
            errors.append("unknown parent: " + str(b.get("id")) + " -> " + str(raw_pid2));
        }
    }

    # Cycle check: deterministic sorted start order; first cycle reported.
    for bid in sorted(sched.by_id.keys()) {
        w = sched.by_id[bid] spawn ParentChain();
        if w.revisit != "" {
            start = w.chain.index(w.revisit);
            cyc = w.chain[start:] + [w.revisit];
            errors.append("cycle: " + " -> ".join(cyc));
            break;
        }
    }

    for b in sorted(sched.blocks, key=by_id_key) {
        if not (sched.day_range[0] <= str(b.get("startTime")) and str(b.get("endTime")) <= sched.day_range[1]) {
            errors.append("block outside dayRange: " + str(b.get("id")));
        }
    }

    seen_days: set[str] = set();
    for day in sched.by_day {
        if day in seen_days {
            errors.append("duplicate byDay: " + day);
        }
        seen_days.add(day);
    }

    if sched.timezone not in KNOWN_TZ {
        errors.append("invalid timezone: " + sched.timezone);
    }
    return sorted(errors);
}

"""Sort key helper for raw block dicts."""
def by_id_key(b: dict) -> str {
    return str(b.get("id"));
}

"""Sorted ids of the nesting subtree rooted at ``bid`` (inclusive)."""
def subtree(sched: Schedule, bid: str) -> list[str] {
    b = sched.resolve(bid);
    if b is None {
        return [];
    }
    w = b spawn SubtreeWalk();
    return sorted(w.seen);
}

"""Deepest nesting chain below ``bid`` (-1 unknown); level-ringed walk."""
def nesting_depth(sched: Schedule, bid: str) -> int {
    b = sched.resolve(bid);
    if b is None {
        return -1;
    }
    depth = 0;
    ring: list[Block] = [b];
    done: set[str] = set();
    while len(ring) > 0 {
        nxt: list[Block] = [];
        for n in ring {
            for kid in [n ->:NestedIn:->] {
                if kid.bid not in done {
                    done.add(kid.bid);
                    nxt.append(kid);
                }
            }
        }
        if len(nxt) == 0 {
            break;
        }
        depth += 1;
        ring = nxt;
    }
    return depth;
}
