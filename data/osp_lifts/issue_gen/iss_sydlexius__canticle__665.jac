"""Transactional purge-provenance reset seam — sydlexius/canticle#665."""

node Track {
    has tid: str;
}

node ScanResult {
    has rid: int;
    has status: str = "done";
    has last_error: str = "stale";
}

node WorkItem {
    has wid: int;
    has status: str = "done";
    has priority: int = 10;
    has next_attempt_at: str = "1970-01-01T00:00:00Z";
    has last_error: str = "stale";
}

node CacheSlot {
    has key: str;
    has hit: bool = True;
}

node Bridge {
    has bid: str;
}

edge Owns {}
edge Via {}

glob SCAN_STATUS_RESET: str = "pending";
glob WORK_STATUS_RESET: str = "queued";
glob WORK_PRIORITY_RESET: int = -100;
glob WORK_NEXT_ATTEMPT_FMT: str = "now";

walker ResetCollect {
    has want_scan: list[int] = [];
    has want_work: list[int] = [];
    has scans: list[ScanResult] = [];
    has works: list[WorkItem] = [];
    has claimed: dict[str, bool] = {};

    can step_track with Track entry {
        tag: str = "T:" + here.tid;
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        kids: list[ScanResult | WorkItem | Bridge | CacheSlot] = [];
        for ch in [here ->:Owns:->][?:ScanResult] {
            kids.append(ch);
        }
        for ch in [here ->:Owns:->][?:WorkItem] {
            kids.append(ch);
        }
        for ch in [here ->:Owns:->][?:Bridge] {
            kids.append(ch);
        }
        for ch in [here ->:Owns:->][?:CacheSlot] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
        print({"reset_collect_track": here.tid});
    }

    can step_bridge with Bridge entry {
        tag: str = "B:" + here.bid;
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        kids: list[ScanResult | WorkItem] = [];
        for ch in [here ->:Via:->][?:ScanResult] {
            kids.append(ch);
        }
        for ch in [here ->:Via:->][?:WorkItem] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
        print({"reset_collect_bridge": here.bid});
    }

    can step_scan with ScanResult entry {
        tag: str = "S:" + str(here.rid);
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        hit: bool = False;
        for sid in self.want_scan {
            if sid == here.rid {
                hit = True;
            }
        }
        if hit {
            self.scans.append(here);
        }
        print({"reset_collect_scan": here.rid});
    }

    can step_work with WorkItem entry {
        tag: str = "W:" + str(here.wid);
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        hit: bool = False;
        for wid in self.want_work {
            if wid == here.wid {
                hit = True;
            }
        }
        if hit {
            self.works.append(here);
        }
        print({"reset_collect_work": here.wid});
    }
}

walker PurgeCollect {
    has target_tid: str;
    has scans: list[ScanResult] = [];
    has works: list[WorkItem] = [];
    has caches: list[CacheSlot] = [];
    has claimed: dict[str, bool] = {};

    can step_track with Track entry {
        if here.tid != self.target_tid {
            disengage;
        }
        tag: str = "T:" + here.tid;
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        kids: list[ScanResult | WorkItem | Bridge | CacheSlot] = [];
        for ch in [here ->:Owns:->][?:ScanResult] {
            kids.append(ch);
        }
        for ch in [here ->:Owns:->][?:WorkItem] {
            kids.append(ch);
        }
        for ch in [here ->:Owns:->][?:Bridge] {
            kids.append(ch);
        }
        for ch in [here ->:Owns:->][?:CacheSlot] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
        print({"purge_collect_track": here.tid});
    }

    can step_bridge with Bridge entry {
        tag: str = "B:" + here.bid;
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        kids: list[ScanResult | WorkItem] = [];
        for ch in [here ->:Via:->][?:ScanResult] {
            kids.append(ch);
        }
        for ch in [here ->:Via:->][?:WorkItem] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
        print({"purge_collect_bridge": here.bid});
    }

    can step_scan with ScanResult entry {
        tag: str = "S:" + str(here.rid);
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        self.scans.append(here);
        print({"purge_collect_scan": here.rid});
    }

    can step_work with WorkItem entry {
        tag: str = "W:" + str(here.wid);
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        self.works.append(here);
        print({"purge_collect_work": here.wid});
    }

    can step_cache with CacheSlot entry {
        tag: str = "C:" + here.key;
        if tag in self.claimed {
            skip;
        }
        self.claimed[tag] = True;
        self.caches.append(here);
        print({"purge_collect_cache": here.key});
    }
}

def reset_for_refetch(
    graph_root: Track,
    scan_result_ids: list[int],
    work_item_ids: list[int]
) -> list[int] {
    w = graph_root spawn ResetCollect(
        want_scan=scan_result_ids,
        want_work=work_item_ids,
        claimed={}
    );
    sr_n: int = 0;
    for sr in w.scans {
        sr.status = SCAN_STATUS_RESET;
        sr.last_error = "";
        sr_n += 1;
    }
    wq_n: int = 0;
    for wi in w.works {
        wi.status = WORK_STATUS_RESET;
        wi.priority = WORK_PRIORITY_RESET;
        wi.next_attempt_at = WORK_NEXT_ATTEMPT_FMT;
        wi.last_error = "";
        wq_n += 1;
    }
    return [sr_n, wq_n];
}

def purge_track(
    graph_root: Track,
    track_id: str,
    fail_after_reset: bool = False
) -> dict[str, int] {
    out: dict[str, int] = {};
    w = graph_root spawn PurgeCollect(target_tid=track_id, claimed={});
    if fail_after_reset {
        raise ValueError("purge failed after reset");
    }
    sr_n: int = 0;
    for sr in w.scans {
        sr.status = SCAN_STATUS_RESET;
        sr.last_error = "";
        sr_n += 1;
    }
    wi_n: int = 0;
    for wi in w.works {
        wi.status = WORK_STATUS_RESET;
        wi.priority = WORK_PRIORITY_RESET;
        wi.next_attempt_at = WORK_NEXT_ATTEMPT_FMT;
        wi.last_error = "";
        wi_n += 1;
    }
    cs_n: int = 0;
    for cs in w.caches {
        cs.hit = False;
        cs_n += 1;
    }
    out["scans"] = sr_n;
    out["works"] = wi_n;
    out["caches"] = cs_n;
    return out;
}
