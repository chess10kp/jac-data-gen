node Runtime { has rid: str = "rt"; }
node Evidence { has eid: str; }
node Assertion { has aid: str; has rule_ver: str = ""; }
node TaskNode { has tid: str; }
node EventNode { has eid: str; has provider: str = ""; }

edge Prov {}
edge Parent {}
edge Ref {}

walker ProvWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step_assert with Assertion entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        print(here.aid);
        kids: list[Assertion] = [];
        for ch in [here ->:Prov:->][?:Assertion] { kids.append(ch); }
        evs: list[Evidence] = [];
        for ev in [here ->:Prov:->][?:Evidence] { evs.append(ev); }
        for ev in evs {
            if ev.eid in self.claimed { continue; }
            self.claimed[ev.eid] = True;
            self.found.append(ev.eid);
            print(ev.eid);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with TaskNode entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        print(here.tid);
        pars: list[TaskNode] = [];
        for p in [here ->:Parent:->][?:TaskNode] { pars.append(p); }
        if len(pars) > 0 {
            visit :0: pars;
        } else {
            disengage;
        }
    }
}

walker HealthWalk {
    has claimed: dict[str, bool] = {};
    can check with Runtime entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print(here.rid);
        disengage;
    }
}

def make_runtime() -> Runtime {
    rt: Runtime = Runtime();
    root ++> rt;
    return rt;
}

def add_evidence(rt: Runtime, eid: str) -> Evidence {
    for ev in [rt ->:Ref:->][?:Evidence] { if ev.eid == eid { return ev; } }
    ev: Evidence = Evidence(eid=eid);
    rt +>:Ref:+> ev;
    return ev;
}

def add_assertion(rt: Runtime, aid: str, rule_ver: str) -> Assertion {
    for a in [rt ->:Ref:->][?:Assertion] { if a.aid == aid { return a; } }
    a: Assertion = Assertion(aid=aid, rule_ver=rule_ver);
    rt +>:Ref:+> a;
    return a;
}

def add_task(rt: Runtime, tid: str) -> TaskNode {
    for t in [rt ->:Ref:->][?:TaskNode] { if t.tid == tid { return t; } }
    t: TaskNode = TaskNode(tid=tid);
    rt +>:Ref:+> t;
    return t;
}

def link_prov_evidence(rt: Runtime, aid: str, eid: str) -> bool {
    src: Assertion | None = None;
    dst: Evidence | None = None;
    for a in [rt ->:Ref:->][?:Assertion] { if a.aid == aid { src = a; } }
    for e in [rt ->:Ref:->][?:Evidence] { if e.eid == eid { dst = e; } }
    if src is None { return False; }
    if dst is None { return False; }
    s = src as Assertion;
    d = dst as Evidence;
    s +>:Prov:+> d;
    return True;
}

def link_prov_assertion(rt: Runtime, src_aid: str, dst_aid: str) -> bool {
    src: Assertion | None = None;
    dst: Assertion | None = None;
    for a in [rt ->:Ref:->][?:Assertion] { if a.aid == src_aid { src = a; } }
    for a in [rt ->:Ref:->][?:Assertion] { if a.aid == dst_aid { dst = a; } }
    if src is None { return False; }
    if dst is None { return False; }
    s = src as Assertion;
    d = dst as Assertion;
    s +>:Prov:+> d;
    return True;
}

def link_parent(rt: Runtime, child: str, parent: str) -> bool {
    c: TaskNode | None = None;
    p: TaskNode | None = None;
    for t in [rt ->:Ref:->][?:TaskNode] { if t.tid == child { c = t; } }
    for t in [rt ->:Ref:->][?:TaskNode] { if t.tid == parent { p = t; } }
    if c is None { return False; }
    if p is None { return False; }
    cn = c as TaskNode;
    pn = p as TaskNode;
    cn +>:Parent:+> pn;
    return True;
}

def get_provenance(rt: Runtime, aid: str) -> list[str] {
    target: Assertion | None = None;
    for a in [rt ->:Ref:->][?:Assertion] { if a.aid == aid { target = a; } }
    if target is None { return []; }
    t = target as Assertion;
    w = t spawn ProvWalk(claimed={}, found=[]);
    return w.found;
}

def get_lineage(rt: Runtime, tid: str) -> list[str] {
    target: TaskNode | None = None;
    for t in [rt ->:Ref:->][?:TaskNode] { if t.tid == tid { target = t; } }
    if target is None { return []; }
    n = target as TaskNode;
    w = n spawn LineageWalk(claimed={}, found=[]);
    res: list[str] = [];
    for x in w.found { if x != tid { res.append(x); } }
    return res;
}

def observe_user_message(rt: Runtime, eid: str, provider: str) -> bool {
    for e in [rt ->:Ref:->][?:EventNode] { if e.eid == eid { return False; } }
    ev: EventNode = EventNode(eid=eid, provider=provider);
    rt +>:Ref:+> ev;
    return True;
}

def observe_request(rt: Runtime, eid: str, provider: str) -> bool { return observe_user_message(rt, eid, provider); }
def observe_response(rt: Runtime, eid: str, provider: str) -> bool { return observe_user_message(rt, eid, provider); }
def observe_usage(rt: Runtime, eid: str, provider: str) -> bool { return observe_user_message(rt, eid, provider); }
def query_classification(rt: Runtime, aid: str) -> list[str] { return get_provenance(rt, aid); }
def query_task(rt: Runtime, tid: str) -> list[str] { return get_lineage(rt, tid); }
def query_outcome(rt: Runtime, aid: str) -> list[str] { return get_provenance(rt, aid); }
def query_rewrite(rt: Runtime, aid: str) -> list[str] { return get_provenance(rt, aid); }

def health(rt: Runtime) -> dict[str, bool] {
    w = rt spawn HealthWalk(claimed={});
    print(w.claimed);
    res: dict[str, bool] = {};
    res["ok"] = True;
    return res;
}

with entry {
    rt: Runtime = make_runtime();
    print("expert runtime ready");
    w = rt spawn HealthWalk(claimed={});
    print(w.claimed);
    r = root spawn HealthWalk(claimed={});
    print(r.claimed);
}

test "provenance_diamond_and_unknown_id" {
    rt: Runtime = make_runtime();
    add_evidence(rt, "e1");
    add_evidence(rt, "e2");
    add_evidence(rt, "e3");
    add_assertion(rt, "a2", "v1");
    add_assertion(rt, "a3", "v1");
    add_assertion(rt, "a1", "v1");
    link_prov_assertion(rt, "a1", "a3");
    link_prov_assertion(rt, "a1", "a2");
    link_prov_evidence(rt, "a2", "e1");
    link_prov_evidence(rt, "a2", "e2");
    link_prov_evidence(rt, "a3", "e1");
    link_prov_evidence(rt, "a3", "e3");
    prov = get_provenance(rt, "a1");
    assert(sorted(prov) == ["e1", "e2", "e3"]);
    assert(get_provenance(rt, "unknown") == []);
    assert(query_classification(rt, "unknown") == []);
    assert(query_outcome(rt, "a1") == prov);
}

test "lineage_cycle_and_unknown_id" {
    rt: Runtime = make_runtime();
    add_task(rt, "t1");
    add_task(rt, "t2");
    add_task(rt, "t3");
    link_parent(rt, "t2", "t1");
    link_parent(rt, "t3", "t2");
    link_parent(rt, "t1", "t3");
    lin = get_lineage(rt, "t3");
    assert(sorted(lin) == ["t1", "t2"]);
    assert(get_lineage(rt, "t1") == sorted(get_lineage(rt, "t1")));
    assert(get_lineage(rt, "nope") == []);
    assert(query_task(rt, "nope") == []);
}

test "ingest_idempotent_and_health" {
    rt: Runtime = make_runtime();
    assert(observe_user_message(rt, "e10", "openai") == True);
    assert(observe_user_message(rt, "e10", "openai") == False);
    assert(observe_request(rt, "e11", "anthropic") == True);
    assert(observe_request(rt, "e11", "anthropic") == False);
    assert(observe_response(rt, "e12", "openai") == True);
    assert(observe_usage(rt, "e13", "openai") == True);
    h = health(rt);
    assert(h["ok"] == True);
}

test "query_rewrite_and_cycle_provenance" {
    rt: Runtime = make_runtime();
    add_evidence(rt, "e20");
    add_evidence(rt, "e21");
    add_assertion(rt, "a10", "v2");
    add_assertion(rt, "a11", "v2");
    link_prov_assertion(rt, "a10", "a11");
    link_prov_assertion(rt, "a11", "a10");
    link_prov_evidence(rt, "a10", "e20");
    link_prov_evidence(rt, "a11", "e21");
    prov = get_provenance(rt, "a10");
    assert(sorted(prov) == ["e20", "e21"]);
    assert(query_rewrite(rt, "a10") == prov);
    assert(query_rewrite(rt, "missing") == []);
}
