node Comp {
    has cid: str;
    has policy: str = "retain";
    has cond_key: str = "";
    has enabled: bool = True;
}

node Rt {
    has gen: int = 0;
    has facts: dict[str, bool] = {};
    has plan: dict[str, str] = {};
}

edge Holds {}
edge Dep {}

walker GatherAll {
    has claimed: dict[str, bool] = {};
    has out: list[Comp] = [];
    can start with Rt entry {
        print("gather start");
        kids: list[Comp] = [here ->:Dep:->][?:Comp];
        # reuse Holds traversal for collection
        kids = [here ->:Holds:->][?:Comp];
        if len(kids) > 0 {
            visit kids;
        } else {
            disengage;
        }
    }
    can step with Comp entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        self.out.append(here);
        disengage;
    }
}

walker RevClosure {
    has claimed: dict[str, bool] = {};
    has affected: list[Comp] = [];
    can step with Comp entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        self.affected.append(here);
        revs: list[Comp] = [here <-:Dep<-][?:Comp];
        if len(revs) > 0 {
            visit revs;
        } else {
            disengage;
        }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can go with Rt entry {
        print("demo rt");
        disengage;
    }
    can go2 with Comp entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        disengage;
    }
}

def find_comp(rt: Rt, cid: str) -> Comp | None {
    w = rt spawn GatherAll(claimed={}, out=[]);
    for c in w.out {
        if c.cid == cid {
            return c;
        }
    }
    return None;
}

def all_comps(rt: Rt) -> list[Comp] {
    w = rt spawn GatherAll(claimed={}, out=[]);
    return w.out;
}

def create_runtime() -> Rt {
    rt = Rt(gen=0, facts={}, plan={});
    root ++> rt;
    return rt;
}

def register_component(rt: Rt, cid: str, policy: str, cond_key: str) -> bool {
    # duplicate cid is no-op
    existing: Comp | None = find_comp(rt, cid);
    if existing != None {
        return False;
    }
    c = Comp(cid=cid, policy=policy, cond_key=cond_key, enabled=True);
    rt ++>:Holds:+> c;
    # facts default true if not present
    if cond_key != "" {
        if cond_key in rt.facts {
        } else {
            rt.facts[cond_key] = True;
        }
        if rt.facts[cond_key] {
            c.enabled = True;
        } else {
            c.enabled = False;
        }
    }
    return True;
}

def add_dependency(rt: Rt, from_cid: str, to_cid: str) -> bool {
    a: Comp | None = find_comp(rt, from_cid);
    b: Comp | None = find_comp(rt, to_cid);
    if a == None {
        return False;
    }
    if b == None {
        return False;
    }
    aa: Comp = a as Comp;
    bb: Comp = b as Comp;
    aa +>:Dep:+> bb;
    return True;
}

def set_fact(rt: Rt, key: str, val: bool) -> None {
    rt.facts[key] = val;
    print(key);
}

def get_generation(rt: Rt) -> int {
    return rt.gen;
}

def get_plan(rt: Rt) -> dict[str, str] {
    return rt.plan;
}

def transition(rt: Rt, updates: dict[str, bool]) -> dict[str, str] {
    # collect current comps
    comps: list[Comp] = all_comps(rt);
    # stage facts without mutating until commit
    staged: dict[str, bool] = {};
    for k in rt.facts {
        staged[k] = rt.facts[k];
    }
    for k in updates {
        staged[k] = updates[k];
    }
    # determine which components change enabled status
    changed: list[Comp] = [];
    for c in comps {
        if c.cond_key == "" {
            continue;
        }
        old_en: bool = c.enabled;
        new_en: bool = True;
        if c.cond_key in staged {
            new_en = staged[c.cond_key];
        }
        if old_en != new_en {
            changed.append(c);
        }
    }
    # cycle guard: simple self-dependency check is rejected deterministically
    for c in changed {
        deps: list[Comp] = [c ->:Dep:->][?:Comp];
        for d in deps {
            if d.cid == c.cid {
                print("cycle abort");
                return rt.plan;
            }
        }
    }
    # reverse-dependency closure via claim-map + skip
    claimed: dict[str, bool] = {};
    affected: list[Comp] = [];
    for ch in changed {
        if ch.cid in claimed {
            continue;
        }
        w = ch spawn RevClosure(claimed=claimed, affected=[]);
        # merge claimed to avoid revisiting same closure
        for ac in w.affected {
            if ac.cid in claimed {
            } else {
                claimed[ac.cid] = True;
                affected.append(ac);
            }
        }
        # propagate walker's internal claimed
        for k in w.claimed {
            if k in claimed {
            } else {
                claimed[k] = w.claimed[k];
            }
        }
    }
    # if nothing affected, still produce retain plan for enabled comps
    plan: dict[str, str] = {};
    if len(affected) == 0 {
        for c in comps {
            en: bool = True;
            if c.cond_key != "" {
                if c.cond_key in staged {
                    en = staged[c.cond_key];
                }
            }
            if en {
                plan[c.cid] = "retain";
            } else {
                plan[c.cid] = "remove";
            }
        }
        # transactional publish
        for k in staged {
            rt.facts[k] = staged[k];
        }
        for c in comps {
            if c.cond_key != "" {
                if c.cond_key in staged {
                    c.enabled = staged[c.cond_key];
                }
            }
        }
        rt.gen = rt.gen + 1;
        rt.plan = plan;
        print("commit empty");
        return plan;
    }
    # build deterministic plan: retain / live_rebind / replace / remove
    for c in comps {
        is_aff: bool = False;
        if c.cid in claimed {
            is_aff = True;
        }
        en: bool = True;
        if c.cond_key != "" {
            if c.cond_key in staged {
                en = staged[c.cond_key];
            }
        }
        if is_aff {
            if en == False {
                plan[c.cid] = "remove";
            } else {
                if c.enabled == False {
                    plan[c.cid] = "add";
                } else {
                    if c.policy == "live" {
                        plan[c.cid] = "live_rebind";
                    } else {
                        if c.policy == "replace" {
                            plan[c.cid] = "replace";
                        } else {
                            plan[c.cid] = "retain";
                        }
                    }
                }
            }
        } else {
            if en {
                plan[c.cid] = "retain";
            } else {
                plan[c.cid] = "remove";
            }
        }
    }
    # apply disconnects/deletes OUTSIDE walk already done -> mutation phase
    for k in staged {
        rt.facts[k] = staged[k];
    }
    for c in comps {
        if c.cond_key != "" {
            if c.cond_key in staged {
                c.enabled = staged[c.cond_key];
            }
        }
    }
    rt.gen = rt.gen + 1;
    rt.plan = plan;
    print("commit");
    return plan;
}

with entry {
    r = Rt(gen=0, facts={}, plan={});
    root ++> r;
    w = r spawn DemoWalker(claimed={});
    print("with entry done");
}
