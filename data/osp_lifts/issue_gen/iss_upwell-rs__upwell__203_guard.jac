node Component {
    has cid: str;
    has trait_name: str;
    has config_key: str;
    has live_rebindable: bool;
    has enabled: bool = True;
}
node ConfigFact {
    has key: str;
    has val: bool;
}
node Runtime {
    has generation: int = 0;
    has committed: bool = False;
}
edge Depends {}
edge ConfigLink {}
edge RuntimeLink {}

walker CollectEligible {
    has claimed: dict[str, bool] = {};
    has snapshot: dict[str, bool] = {};
    has eligible: list[str] = [];
    can start with Runtime entry {
        print("start runtime " + str(here.generation));
        for comp in [here ->][?:Component] {
            visit :0: [comp];
        }
        if len([here ->][?:Component]) == 0 {
            disengage;
        }
    }
    can step with Component entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        is_eligible: bool = True;
        if here.config_key != "" {
            if here.config_key in self.snapshot {
                if self.snapshot[here.config_key] == False {
                    is_eligible = False;
                }
            } else {
                is_eligible = False;
            }
        }
        if is_eligible {
            self.eligible.append(here.cid);
        }
        print("eval " + here.cid);
        for nxt in [here ->:Depends:->][?:Component] {
            visit :0: [nxt];
        }
        if len([here ->:Depends:->][?:Component]) == 0 {
            disengage;
        }
    }
}

def add_component(graph_root: Runtime, cid: str, trait_name: str, config_key: str, live_rebindable: bool) -> Component {
    comp: Component = Component(cid=cid, trait_name=trait_name, config_key=config_key, live_rebindable=live_rebindable, enabled=True);
    graph_root ++> comp;
    return comp;
}
def set_config_fact(graph_root: Runtime, key: str, val: bool) -> ConfigFact {
    cf: ConfigFact = ConfigFact(key=key, val=val);
    graph_root ++> cf;
    return cf;
}
def add_dependency(src: Component, dst: Component) {
    # src depends on dst
    src +>:Depends:+> dst;
    print("dep " + src.cid + " -> " + dst.cid);
}
def evaluate_eligible(graph_root: Runtime, snapshot: dict[str, bool]) -> list[str] {
    w: CollectEligible = CollectEligible(snapshot=snapshot);
    rt_w: CollectEligible = graph_root spawn w;
    return sorted(rt_w.eligible);
}
def plan_transition(old_ids: list[str], new_ids: list[str], live_map: dict[str, bool] | None = None) -> dict[str, str] {
    live: dict[str, bool] = {};
    if live_map is None {
        live = {};
    } else {
        live = live_map;
    }
    old_set: dict[str, bool] = {};
    new_set: dict[str, bool] = {};
    for o in old_ids {
        old_set[o] = True;
    }
    for n in new_ids {
        new_set[n] = True;
    }
    plan: dict[str, str] = {};
    for o in old_ids {
        if o in new_set {
            is_live: bool = False;
            if o in live {
                if live[o] == True {
                    is_live = True;
                }
            }
            if is_live {
                plan[o] = "live_rebind";
            } else {
                if "_fixed" in o {
                    plan[o] = "replace";
                } else {
                    plan[o] = "retain";
                }
            }
        } else {
            plan[o] = "remove";
        }
    }
    for n in new_ids {
        if n not in old_set {
            plan[n] = "add";
        }
    }
    print("plan done");
    return plan;
}
def get_generation(graph_root: Runtime) -> int {
    return graph_root.generation;
}
def commit_generation(graph_root: Runtime, plan: dict[str, str]) -> int {
    known: dict[str, bool] = {};
    for comp in [graph_root ->][?:Component] {
        known[comp.cid] = True;
    }
    for k in plan {
        if k not in known {
            if plan[k] != "add" {
                print("abort unknown " + k);
                return graph_root.generation;
            }
        }
        if plan[k] == "fail" {
            print("abort hook fail");
            return graph_root.generation;
        }
    }
    graph_root.generation = graph_root.generation + 1;
    graph_root.committed = True;
    print("commit gen " + str(graph_root.generation));
    return graph_root.generation;
}

with entry {
    rt: Runtime = Runtime(generation=0, committed=False);
    root ++> rt;
    w: CollectEligible = rt spawn CollectEligible(snapshot={});
    print("demo eligible " + str(len(w.eligible)));
}

test "diamond revisit adversarial order" {
    rt: Runtime = Runtime(generation=0, committed=False);
    root ++> rt;
    a: Component = add_component(rt, "auth", "Authenticator", "", True);
    b: Component = add_component(rt, "provider_default", "Authenticator", "", True);
    c: Component = add_component(rt, "provider_custom", "Authenticator", "auth.custom.enabled", False);
    d: Component = add_component(rt, "consumer_fixed", "Consumer", "", False);
    add_dependency(a, b);
    add_dependency(a, c);
    add_dependency(b, d);
    add_dependency(c, d);
    snap: dict[str, bool] = {"auth.custom.enabled": True};
    res: list[str] = evaluate_eligible(rt, snap);
    assert (len(res) == 4);
    assert (res[0] == "auth");
    assert (res[1] == "consumer_fixed");
    assert (res[2] == "provider_custom");
    assert (res[3] == "provider_default");
    snap2: dict[str, bool] = {"auth.custom.enabled": False};
    res2: list[str] = evaluate_eligible(rt, snap2);
    assert ("provider_custom" not in res2);
    assert ("provider_default" in res2);
}

test "unknown id tolerance" {
    rt: Runtime = Runtime(generation=5, committed=False);
    root ++> rt;
    x: Component = add_component(rt, "known", "Svc", "", True);
    snap: dict[str, bool] = {};
    res: list[str] = evaluate_eligible(rt, snap);
    assert ("known" in res);
    assert (len(evaluate_eligible(rt, {"missing.key": True})) == 1);
    old_ids: list[str] = ["known"];
    new_ids: list[str] = ["known", "ghost"];
    live: dict[str, bool] = {"known": True};
    p: dict[str, str] = plan_transition(old_ids, new_ids, live);
    assert (p["known"] == "live_rebind");
    assert (p["ghost"] == "add");
    p2: dict[str, str] = {"unknown_id": "retain"};
    g: int = commit_generation(rt, p2);
    assert (g == 5);
    assert (get_generation(rt) == 5);
}

test "live rebind vs replace vs retain classification" {
    old_ids: list[str] = ["svc_a", "svc_b_fixed", "svc_c"];
    new_ids: list[str] = ["svc_a", "svc_b_fixed", "svc_c"];
    live: dict[str, bool] = {"svc_a": True, "svc_b_fixed": False};
    p: dict[str, str] = plan_transition(old_ids, new_ids, live);
    assert (p["svc_a"] == "live_rebind");
    assert (p["svc_b_fixed"] == "replace");
    assert (p["svc_c"] == "retain");
    old2: list[str] = ["a", "b"];
    new2: list[str] = ["b", "c"];
    p2: dict[str, str] = plan_transition(old2, new2, {});
    assert (p2["a"] == "remove");
    assert (p2["b"] == "retain");
    assert (p2["c"] == "add");
}

test "transaction abort preserves generation" {
    rt: Runtime = Runtime(generation=10, committed=False);
    root ++> rt;
    comp: Component = add_component(rt, "svc", "Svc", "", True);
    plan_ok: dict[str, str] = {"svc": "retain"};
    g1: int = commit_generation(rt, plan_ok);
    assert (g1 == 11);
    assert (get_generation(rt) == 11);
    plan_fail: dict[str, str] = {"svc": "fail"};
    g2: int = commit_generation(rt, plan_fail);
    assert (g2 == 11);
    assert (get_generation(rt) == 11);
    empty_plan: dict[str, str] = {};
    g3: int = commit_generation(rt, empty_plan);
    assert (g3 == 12);
}

test "cycle with claim map does not hang" {
    rt: Runtime = Runtime(generation=0, committed=False);
    root ++> rt;
    n1: Component = add_component(rt, "n1", "Svc", "", True);
    n2: Component = add_component(rt, "n2", "Svc", "", True);
    n3: Component = add_component(rt, "n3", "Svc", "", True);
    add_dependency(n1, n2);
    add_dependency(n2, n3);
    add_dependency(n3, n1);
    snap: dict[str, bool] = {};
    res: list[str] = evaluate_eligible(rt, snap);
    assert (len(res) == 3);
    assert ("n1" in res);
    assert ("n2" in res);
    assert ("n3" in res);
}
