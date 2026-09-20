"""
CI lockfile-keyed cache planner on workflow DAG.
nexoraorg/chenaikit#323
"""

node Job {
    has jid: str;
    has toolchain: str;
    has lock_ids: list[str] = [];
}

edge Depends {}

walker FindJobWalker {
    has target: str;
    has hit: Job | None = None;
    can seek with Job entry {
        if here.jid == self.target {
            self.hit = here;
            disengage;
        }
        kids: list[Job] = [here ->:Depends:->][?:Job];
        if kids {
            visit kids;
        } else {
            disengage;
        }
        print {"seek": here.jid};
    }
}

walker LockCollectWalker {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];
    can collect with Job entry {
        if here.jid in self.claimed { skip; }
        self.claimed[here.jid] = True;
        for lk in here.lock_ids {
            self.acc.append(lk);
        }
        kids: list[Job] = [here ->:Depends:->][?:Job];
        visit kids;
        print {"collect": here.jid};
    }
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];
    can close with Job entry {
        if here.jid in self.claimed { skip; }
        self.claimed[here.jid] = True;
        self.acc.append(here.jid);
        kids: list[Job] = [here ->:Depends:->][?:Job];
        visit kids;
        print {"close": here.jid};
    }
}

def find_job_node(graph_root: Job, jid: str) -> Job | None {
    w = graph_root spawn FindJobWalker(target=jid);
    return w.hit;
}

def find_job_id(graph_root: Job, jid: str) -> str | None {
    node = find_job_node(graph_root, jid);
    if node is None {
        return None;
    }
    return node.jid;
}

def _dedupe_sort(keys: list[str]) -> list[str] {
    seen: dict[str, bool] = {};
    out: list[str] = [];
    for k in keys {
        if k not in seen {
            seen[k] = True;
            out.append(k);
        }
    }
    return sorted(out);
}

def reachable_lock_ids(graph_root: Job, jid: str) -> list[str] {
    node = find_job_node(graph_root, jid);
    if node is None {
        return [];
    }
    w = node spawn LockCollectWalker(claimed={});
    return _dedupe_sort(w.acc);
}

def dependency_closure_ids(graph_root: Job, jid: str) -> list[str] {
    node = find_job_node(graph_root, jid);
    if node is None {
        return [];
    }
    w = node spawn ClosureWalker(claimed={});
    return sorted(w.acc);
}

def cache_key_for_job(graph_root: Job, jid: str) -> str {
    node = find_job_node(graph_root, jid);
    if node is None {
        return "";
    }
    locks = reachable_lock_ids(graph_root, jid);
    parts: list[str] = [];
    if node.toolchain {
        parts.append(node.toolchain);
    }
    for lk in locks {
        parts.append(lk);
    }
    return ":".join(parts);
}

def should_invalidate_cache(graph_root: Job, jid: str, changed_lock: str) -> bool {
    locks = reachable_lock_ids(graph_root, jid);
    for lk in locks {
        if lk == changed_lock {
            return True;
        }
    }
    return False;
}

def build_ci_workflow -> Job {
    graph_root = Job(jid="ci_root", toolchain="", lock_ids=[]);
    fe: Job = Job(jid="frontend", toolchain="npm", lock_ids=["package-lock.json"]);
    be: Job = Job(jid="backend", toolchain="pnpm", lock_ids=["pnpm-lock.yaml"]);
    co: Job = Job(jid="contracts", toolchain="cargo", lock_ids=["Cargo.lock"]);
    sh: Job = Job(jid="shared_packages", toolchain="pnpm", lock_ids=["pnpm-lock.yaml"]);
    graph_root +>:Depends:+> fe;
    graph_root +>:Depends:+> be;
    graph_root +>:Depends:+> co;
    be +>:Depends:+> sh;
    return graph_root;
}

def build_diamond_workflow -> Job {
    graph_root = Job(jid="ci_root", toolchain="", lock_ids=[]);
    st: Job = Job(jid="start", toolchain="x", lock_ids=["L0"]);
    la: Job = Job(jid="leg_a", toolchain="y", lock_ids=["La"]);
    lb: Job = Job(jid="leg_b", toolchain="y", lock_ids=["Lb"]);
    jn: Job = Job(jid="join", toolchain="z", lock_ids=["Ljoin"]);
    graph_root +>:Depends:+> st;
    jn +>:Depends:+> la;
    jn +>:Depends:+> lb;
    la +>:Depends:+> st;
    lb +>:Depends:+> st;
    graph_root +>:Depends:+> jn;
    return graph_root;
}
