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
