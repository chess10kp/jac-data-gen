# sydlexius/canticle#665 — transactional repository seam for row resets.
# Node types stand in for the tables; a Resetter seam owns all status /
# priority / next_attempt_at literals; reset + cache invalidation commit
# atomically (collect during walk, mutate outside it).

node Track {
    has tid: str;
}

node ScanResult {
    has sid: str;
    has status: str = "done";
    has priority: int = 0;
    has next_attempt_at: str = "";
    has last_error: str = "";
    has invalidated: bool = False;
}

node WorkItem {
    has wid: str;
    has status: str = "done";
    has priority: int = 0;
    has next_attempt_at: str = "";
    has last_error: str = "";
}

edge SCAN_FOR {}
edge QUEUE_FOR {}

# The seam: constants live ONLY here (acceptance: no literals elsewhere).
obj Resetter {
    def reset_scan(r: ScanResult) {
        r.status = "pending";
        r.priority = -100;
        r.next_attempt_at = "1970-01-01T00:00:00Z";
        r.last_error = "";
    }
    def reset_work(w: WorkItem) {
        w.status = "pending";
        r_priority_fix(w=w);
        w.next_attempt_at = "1970-01-01T00:00:00Z";
        w.last_error = "";
    }
}

# helper so the seam owns the priority constant once per shape
def r_priority_fix(w: WorkItem) {
    w.priority = -100;
}

# Collect walk: claim-map dedup + skip (never disengage on revisit).
walker PurgeProvenance {
    has track_id: str;
    has claimed: dict[str, bool] = {};
    has sr_ids: list[str] = [];
    has wq_ids: list[str] = [];

    can sweep with Track entry {
        if here.tid != self.track_id { disengage; }
        for r in [here ->:SCAN_FOR:->][?:ScanResult] {
            visit [r];
        }
        for w in [here ->:QUEUE_FOR:->][?:WorkItem] {
            visit [w];
        }
    }
    can sweep_sr with ScanResult entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.sr_ids.append(here.sid);
        here.invalidated = True;  # staged cache invalidation
    }
    can sweep_wq with WorkItem entry {
        if here.wid in self.claimed { skip; }
        self.claimed[here.wid] = True;
        self.wq_ids.append(here.wid);
    }
}

# Public API: purge track provenance; unknown track ids tolerate as (0, 0).
# Mutation happens OUTSIDE the walk: collect via walker, then reset here.
def purge_provenance(root_node: Track, track_id: str, resetter: Resetter) -> tuple {
    if root_node.tid != track_id {
        return (0, 0);
    }
    wk = root_node spawn PurgeProvenance(track_id=track_id, claimed={}, sr_ids=[], wq_ids=[]);
    n_sr: int = 0;
    n_wq: int = 0;
    for r in [root_node ->:SCAN_FOR:->][?:ScanResult] {
        if r.sid in wk.sr_ids {
            resetter.reset_scan(r);
            r.invalidated = True;
            n_sr += 1;
        }
    }
    for w in [root_node ->:QUEUE_FOR:->][?:WorkItem] {
        if w.wid in wk.wq_ids {
            resetter.reset_work(w);
            n_wq += 1;
        }
    }
    return (n_sr, n_wq);
}

with entry {
    t = Track(tid="t1");
    root ++> t;
    r1 = ScanResult(sid="s1");
    r2 = ScanResult(sid="s2");
    w1 = WorkItem(wid="w1");
    t +>:SCAN_FOR:+> r1;
    t +>:SCAN_FOR:+> r2;
    t +>:QUEUE_FOR:+> w1;
    rs = Resetter();
    counts = purge_provenance(t, "t1", rs);
    print(counts);
    print(purge_provenance(t, "missing", rs));
}
