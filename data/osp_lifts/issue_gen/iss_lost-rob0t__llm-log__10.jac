node Runtime {
    has kb_rev: int = 0;
    has prolog_alive: bool = True;
}
node Event {
    has eid: str;
    has provider: str;
    has model_name: str;
    has transport: str;
    has ts: str;
    has req_hash: str;
    has resp_hash: str;
}
node Task {
    has tid: str;
}
node Assertion {
    has aid: str;
    has rule_version: str;
}

edge Stores {}
edge HoldsTask {}
edge HoldsAssertion {}
edge TaskRequest {}
edge Asserts {}
edge ChildParent {}

walker FindEvent {
    has target_eid: str;
    has found_event: Event | None = None;
    has claimed: dict[str, bool] = {};
    can seek_runtime with Runtime entry {
        if "rt" in self.claimed { skip; }
        self.claimed["rt"] = True;
        for ev in [here ->:Stores:->][?:Event] {
            visit :0: [ev];
        }
        for tk in [here ->:HoldsTask:->][?:Task] {
            visit :0: [tk];
        }
        for ass in [here ->:HoldsAssertion:->][?:Assertion] {
            visit :0: [ass];
        }
        print("FindEvent runtime");
    }
    can seek_event with Event entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.eid == self.target_eid {
            self.found_event = here;
        }
        print("FindEvent event " + here.eid);
    }
    can seek_task with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        for nxt in [here ->:ChildParent:->][?:Task] {
            visit :0: [nxt];
        }
        for ev in [here ->:TaskRequest:->][?:Event] {
            visit :0: [ev];
        }
        print("FindEvent task " + here.tid);
    }
    can seek_assertion with Assertion entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        for ev in [here ->:Asserts:->][?:Event] {
            visit :0: [ev];
        }
        print("FindEvent assertion " + here.aid);
    }
}

walker FindTask {
    has target_tid: str;
    has found_task: Task | None = None;
    has claimed: dict[str, bool] = {};
    can ft_runtime with Runtime entry {
        if "rt" in self.claimed { skip; }
        self.claimed["rt"] = True;
        for tk in [here ->:HoldsTask:->][?:Task] {
            visit :0: [tk];
        }
        for ev in [here ->:Stores:->][?:Event] {
            visit :0: [ev];
        }
        print("FindTask runtime");
    }
    can ft_task with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid == self.target_tid {
            self.found_task = here;
        }
        for nxt in [here ->:ChildParent:->][?:Task] {
            visit :0: [nxt];
        }
        print("FindTask task " + here.tid);
    }
    can ft_event with Event entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print("FindTask event " + here.eid);
    }
}

walker FindAssertion {
    has target_aid: str;
    has found_assertion: Assertion | None = None;
    has claimed: dict[str, bool] = {};
    can fa_runtime with Runtime entry {
        if "rt" in self.claimed { skip; }
        self.claimed["rt"] = True;
        for ass in [here ->:HoldsAssertion:->][?:Assertion] {
            visit :0: [ass];
        }
        print("FindAssertion runtime");
    }
    can fa_assertion with Assertion entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        if here.aid == self.target_aid {
            self.found_assertion = here;
        }
        print("FindAssertion assertion " + here.aid);
    }
}

walker CollectEvidence {
    has target_aid: str;
    has evidence: list[str] = [];
    has claimed: dict[str, bool] = {};
    can ce_runtime with Runtime entry {
        if "rt" in self.claimed { skip; }
        self.claimed["rt"] = True;
        for ass in [here ->:HoldsAssertion:->][?:Assertion] {
            visit :0: [ass];
        }
        print("CollectEvidence runtime");
    }
    can ce_assertion with Assertion entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        if here.aid == self.target_aid {
            for ev in [here ->:Asserts:->][?:Event] {
                self.evidence.append(ev.eid);
                visit :0: [ev];
            }
        }
        print("CollectEvidence assertion " + here.aid);
    }
    can ce_event with Event entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print("CollectEvidence event " + here.eid);
    }
}

def create_runtime() -> Runtime {
    rt = Runtime(kb_rev=0, prolog_alive=True);
    return rt;
}

def ingest_event(rt: Runtime, eid: str, provider: str, model_name: str, transport: str, ts: str, req_hash: str, resp_hash: str) -> str {
    w = rt spawn FindEvent(target_eid=eid);
    found = w.found_event;
    if found is not None {
        ev = found as Event;
        if ev.provider == provider and ev.model_name == model_name and ev.transport == transport and ev.ts == ts and ev.req_hash == req_hash and ev.resp_hash == resp_hash {
            return "ok";
        } else {
            return "conflict";
        }
    }
    ev2 = Event(eid=eid, provider=provider, model_name=model_name, transport=transport, ts=ts, req_hash=req_hash, resp_hash=resp_hash);
    rt +>:Stores:+> ev2;
    rt.kb_rev = rt.kb_rev + 1;
    return "ok";
}

def add_task(rt: Runtime, tid: str, eid: str) -> str {
    w = rt spawn FindEvent(target_eid=eid);
    if w.found_event is None {
        return "not_found";
    }
    ev = w.found_event as Event;
    wt = rt spawn FindTask(target_tid=tid);
    if wt.found_task is not None {
        return tid;
    }
    tk = Task(tid=tid);
    rt +>:HoldsTask:+> tk;
    tk +>:TaskRequest:+> ev;
    rt.kb_rev = rt.kb_rev + 1;
    return tid;
}

def link_child_parent(rt: Runtime, child_tid: str, parent_tid: str) -> str {
    wc = rt spawn FindTask(target_tid=child_tid);
    wp = rt spawn FindTask(target_tid=parent_tid);
    if wc.found_task is None {
        return "not_found";
    }
    if wp.found_task is None {
        return "not_found";
    }
    child = wc.found_task as Task;
    parent = wp.found_task as Task;
    child +>:ChildParent:+> parent;
    return "ok";
}

def add_assertion(rt: Runtime, aid: str, eid: str, rule_version: str) -> str {
    w = rt spawn FindEvent(target_eid=eid);
    if w.found_event is None {
        return "not_found";
    }
    ev = w.found_event as Event;
    wa = rt spawn FindAssertion(target_aid=aid);
    if wa.found_assertion is not None {
        return aid;
    }
    ass = Assertion(aid=aid, rule_version=rule_version);
    rt +>:HoldsAssertion:+> ass;
    ass +>:Asserts:+> ev;
    rt.kb_rev = rt.kb_rev + 1;
    return aid;
}

def get_evidence_for_assertion(rt: Runtime, aid: str) -> list[str] {
    w = rt spawn CollectEvidence(target_aid=aid);
    res: list[str] = [];
    for e in w.evidence {
        res.append(e);
    }
    return res;
}

def query_expert(rt: Runtime, op: str, eid: str) -> dict[str, str] {
    allowed: list[str] = [];
    allowed.append("observe_user_message");
    allowed.append("observe_request");
    allowed.append("observe_response");
    allowed.append("observe_usage");
    allowed.append("query_classification");
    allowed.append("query_task");
    allowed.append("query_outcome");
    allowed.append("query_rewrite");
    allowed.append("health");
    is_allowed = False;
    for a in allowed {
        if a == op {
            is_allowed = True;
        }
    }
    if not is_allowed {
        err: dict[str, str] = {};
        err["status"] = "error";
        err["error"] = "unknown_operation";
        return err;
    }
    w = rt spawn FindEvent(target_eid=eid);
    if w.found_event is None {
        err2: dict[str, str] = {};
        err2["status"] = "error";
        err2["error"] = "not_found";
        return err2;
    }
    ev = w.found_event as Event;
    out: dict[str, str] = {};
    out["status"] = "ok";
    out["op"] = op;
    out["eid"] = ev.eid;
    out["provider"] = ev.provider;
    out["kb_rev"] = rt.kb_rev.__str__();
    out["expert"] = "tek9_prolog";
    return out;
}

def health(rt: Runtime) -> dict[str, str] {
    h: dict[str, str] = {};
    if rt.prolog_alive {
        h["prolog"] = "alive";
    } else {
        h["prolog"] = "dead";
    }
    h["kb_rev"] = rt.kb_rev.__str__();
    h["status"] = "ok";
    return h;
}

with entry {
    rt = create_runtime();
    root ++> rt;
    tmp = root spawn FindEvent(target_eid="demo");
    print("entry demo " + tmp.target_eid);
    res = ingest_event(rt, "e1", "openai", "gpt-4", "http", "t1", "h1", "h2");
    print(res);
}
