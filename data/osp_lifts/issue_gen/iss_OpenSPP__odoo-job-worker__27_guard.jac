"""OpenSPP/odoo-job-worker#27 — raw-SQL parent cascade is single-level."""

glob TERMINAL = frozenset({"done", "failed", "cancelled"});

node Job {
    has jid: str;
}

edge ChildOf {}

obj JobRegistry {
    has jobs: dict[str, dict[str, str | None]] = {};
    has nodes: dict[str, Job] = {};
}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    has origin: str = "";

    can step with Job entry {
        if here.jid in self.claimed {
            if here.jid == self.origin {
                already = False;
                for x in self.out { if x == here.jid { already = True; } }
                if not already { self.out.append(here.jid); }
            }
            skip;
        }
        self.claimed[here.jid] = True;
        if here.jid != self.origin { self.out.append(here.jid); }
        children = [here ->:ChildOf:->][?:Job];
        nms: list[str] = [];
        for ch in children { nms.append(ch.jid); }
        for nm in sorted(nms) {
            for ch in children {
                if ch.jid == nm { visit ch; }
            }
        }
    }
}

walker OrmCascadeWalk {
    has registry: JobRegistry;
    has changed: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Job entry {
        if here.jid in self.claimed { skip; }
        self.claimed[here.jid] = True;
        children = [here ->:ChildOf:->][?:Job];
        nms: list[str] = [];
        for ch in children { nms.append(ch.jid); }
        for nm in sorted(nms) {
            for ch in children {
                if ch.jid == nm {
                    if self.registry.jobs[ch.jid]["status"] == "waiting" {
                        self.registry.jobs[ch.jid]["status"] = "failed";
                        self.changed.append(ch.jid);
                        ch spawn OrmCascadeWalk(
                            registry=self.registry,
                            changed=self.changed,
                            claimed=self.claimed,
                        );
                    }
                }
            }
        }
    }
}

def build_job_registry(rows: list[dict]) -> JobRegistry {
    reg = JobRegistry();
    for row in rows {
        jid = row["id"];
        reg.jobs[jid] = {
            "parent_id": row.get("parent_id", None),
            "status": row.get("status", "waiting"),
        };
        nd = Job(jid=jid);
        root ++> nd;
        reg.nodes[jid] = nd;
    }
    for jid in sorted(reg.jobs) {
        pid = reg.jobs[jid]["parent_id"];
        if pid is not None and pid in reg.nodes {
            reg.nodes[pid] +>:ChildOf:+> reg.nodes[jid];
        }
    }
    return reg;
}

def direct_children(registry: JobRegistry, parent_id: str) -> list[str] {
    if not (parent_id in registry.jobs) { return []; }
    parent = registry.nodes.get(parent_id, None);
    if parent is None { return []; }
    children = [parent ->:ChildOf:->][?:Job];
    out: list[str] = [];
    for ch in children { out.append(ch.jid); }
    return sorted(out);
}

def descendant_job_ids(registry: JobRegistry, `root: str) -> list[str] {
    if not (`root in registry.jobs) { return []; }
    nd = registry.nodes.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DescWalk(claimed={}, out=[], origin=`root);
    return sorted(w.out);
}

def raw_sql_parent_cascade(registry: JobRegistry, failed_parent_id: str) -> list[str] {
    if not (failed_parent_id in registry.jobs) { return []; }
    parent = registry.nodes.get(failed_parent_id, None);
    if parent is None { return []; }
    changed: list[str] = [];
    children = [parent ->:ChildOf:->][?:Job];
    nms: list[str] = [];
    for ch in children { nms.append(ch.jid); }
    for nm in sorted(nms) {
        for ch in children {
            if ch.jid == nm {
                if registry.jobs[ch.jid]["status"] == "waiting" {
                    registry.jobs[ch.jid]["status"] = "failed";
                    changed.append(ch.jid);
                }
            }
        }
    }
    return sorted(changed);
}

def orm_cascade_children_on_parent_failure(
    registry: JobRegistry, failed_parent_id: str
) -> list[str] {
    if not (failed_parent_id in registry.jobs) { return []; }
    nd = registry.nodes.get(failed_parent_id, None);
    if nd is None { return []; }
    w = nd spawn OrmCascadeWalk(registry=registry, changed=[], claimed={});
    return sorted(w.changed);
}

def reclaim_exhausted_cascade(registry: JobRegistry, job_id: str) -> dict[str, list[str]] {
    if not (job_id in registry.jobs) { return {"failed": [], "cascaded": []}; }
    registry.jobs[job_id]["status"] = "failed";
    cascaded = raw_sql_parent_cascade(registry, job_id);
    return {"failed": [job_id], "cascaded": cascaded};
}

def gc_collectible_ids(registry: JobRegistry) -> list[str] {
    out: list[str] = [];
    for jid in registry.jobs {
        if registry.jobs[jid]["status"] in TERMINAL { out.append(jid); }
    }
    return sorted(out);
}

def stuck_waiting_jobs(registry: JobRegistry) -> list[str] {
    stuck: list[str] = [];
    for jid in registry.jobs {
        meta = registry.jobs[jid];
        if meta["status"] != "waiting" { continue; }
        cur = meta["parent_id"];
        seen: dict[str, bool] = {};
        while cur is not None {
            if cur in seen { break; }
            seen[cur] = True;
            parent_meta = registry.jobs.get(cur, None);
            if parent_meta is None { break; }
            if parent_meta["status"] == "failed" {
                stuck.append(jid);
                break;
            }
            cur = parent_meta["parent_id"];
        }
    }
    return sorted(stuck);
}

test "raw sql cascade single level only deep chain" {
    reg = build_job_registry([
        {"id": "r", "parent_id": None, "status": "failed"},
        {"id": "c1", "parent_id": "r", "status": "waiting"},
        {"id": "c2", "parent_id": "c1", "status": "waiting"},
        {"id": "c3", "parent_id": "c2", "status": "waiting"},
    ]);
    assert raw_sql_parent_cascade(reg, "r") == ["c1"];;
    assert reg.jobs["c2"]["status"] == "waiting";;
    assert reg.jobs["c3"]["status"] == "waiting";;
    assert stuck_waiting_jobs(reg) == ["c2", "c3"];;
}

test "orm cascade walks full waiting depth" {
    reg = build_job_registry([
        {"id": "r", "parent_id": None, "status": "failed"},
        {"id": "c1", "parent_id": "r", "status": "waiting"},
        {"id": "c2", "parent_id": "c1", "status": "waiting"},
        {"id": "c3", "parent_id": "c2", "status": "waiting"},
    ]);
    assert orm_cascade_children_on_parent_failure(reg, "r") == ["c1", "c2", "c3"];;
    assert stuck_waiting_jobs(reg) == [];;
    assert gc_collectible_ids(reg) == ["c1", "c2", "c3", "r"];;
}

test "orm cascade abc chain fresh fixture" {
    reg = build_job_registry([
        {"id": "A", "parent_id": None, "status": "failed"},
        {"id": "B", "parent_id": "A", "status": "waiting"},
        {"id": "C", "parent_id": "B", "status": "waiting"},
    ]);
    assert orm_cascade_children_on_parent_failure(reg, "A") == ["B", "C"];;
    assert stuck_waiting_jobs(reg) == [];;
}

test "cycle descendant revisit claim skip sibling closure" {
    reg = build_job_registry([
        {"id": "A", "parent_id": "C", "status": "waiting"},
        {"id": "B", "parent_id": "A", "status": "waiting"},
        {"id": "C", "parent_id": "B", "status": "waiting"},
        {"id": "D", "parent_id": "B", "status": "waiting"},
    ]);
    assert descendant_job_ids(reg, "A") == ["A", "B", "C", "D"];;
}

test "orm cascade skips subtree behind already failed child" {
    reg = build_job_registry([
        {"id": "A", "parent_id": None, "status": "failed"},
        {"id": "B", "parent_id": "A", "status": "failed"},
        {"id": "C", "parent_id": "B", "status": "waiting"},
    ]);
    assert orm_cascade_children_on_parent_failure(reg, "A") == [];;
    assert reg.jobs["C"]["status"] == "waiting";;
    assert stuck_waiting_jobs(reg) == ["C"];;
}

test "unknown id tolerance across cascade and reclaim" {
    reg = build_job_registry([{"id": "solo", "parent_id": None, "status": "waiting"}]);
    assert direct_children(reg, "ghost") == [];;
    assert descendant_job_ids(reg, "ghost") == [];;
    assert raw_sql_parent_cascade(reg, "ghost") == [];;
    assert orm_cascade_children_on_parent_failure(reg, "ghost") == [];;
    assert reclaim_exhausted_cascade(reg, "ghost") == {"failed": [], "cascaded": []};;
    assert reg.jobs["solo"]["status"] == "waiting";;
}

test "cascade ignores non waiting direct children" {
    reg = build_job_registry([
        {"id": "p", "parent_id": None, "status": "failed"},
        {"id": "w", "parent_id": "p", "status": "waiting"},
        {"id": "run", "parent_id": "p", "status": "running"},
        {"id": "done", "parent_id": "p", "status": "done"},
    ]);
    assert raw_sql_parent_cascade(reg, "p") == ["w"];;
    reg2 = build_job_registry([
        {"id": "p", "parent_id": None, "status": "failed"},
        {"id": "w", "parent_id": "p", "status": "waiting"},
        {"id": "run", "parent_id": "p", "status": "running"},
        {"id": "done", "parent_id": "p", "status": "done"},
    ]);
    assert orm_cascade_children_on_parent_failure(reg2, "p") == ["w"];;
    assert reg.jobs["run"]["status"] == "running";;
    assert reg.jobs["done"]["status"] == "done";;
}

test "fan raw sql single level leaves deep waiting stuck" {
    reg = build_job_registry([
        {"id": "hub", "parent_id": None, "status": "failed"},
        {"id": "z", "parent_id": "hub", "status": "waiting"},
        {"id": "a", "parent_id": "hub", "status": "waiting"},
        {"id": "a1", "parent_id": "a", "status": "waiting"},
    ]);
    assert descendant_job_ids(reg, "hub") == ["a", "a1", "z"];;
    assert raw_sql_parent_cascade(reg, "hub") == ["a", "z"];;
    assert stuck_waiting_jobs(reg) == ["a1"];;
    assert gc_collectible_ids(reg) == ["a", "hub", "z"];;
}
