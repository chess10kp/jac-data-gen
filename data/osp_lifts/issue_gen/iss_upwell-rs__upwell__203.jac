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
