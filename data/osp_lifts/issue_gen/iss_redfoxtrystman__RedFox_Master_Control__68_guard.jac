"""JOB-09 order-of-operations and boundary lift — redfoxtrystman/RedFox_Master_Control#68."""

node job {
    has job_id: str;
    has label: str = "";
}

node capability {
    has cap_id: str;
    has label: str = "";
}

edge owns {}
edge depends {}

obj graph_store {
    has by_id: dict[str, job] = {};
}

walker reach_caps {
    has claimed: dict[str, bool] = {};
    has caps: list[str] = [];
    has start_job: str = "";

    can collect with job entry {
        if here.job_id in self.claimed {
            skip;
        }
        self.claimed[here.job_id] = True;
        owned: list[capability] = [here ->:owns:->][?:capability];
        for oc in owned {
            self.caps.append(oc.cap_id);
        }
        deps: list[job] = [here ->:depends:->][?:job];
        for nx in deps {
            visit nx;
        }
        print("reach", here.job_id, len(self.caps));
    }
}

def recovery_sequence -> list[str] {
    steps: list[str] = [];
    steps.append("stabilize_job09_backend");
    steps.append("remove_old_tow_web");
    steps.append("preserve_weui_master_settings");
    steps.append("prove_ugly_native_read");
    steps.append("verify_raw_counts");
    steps.append("rebuild_tow_ui");
    steps.append("publish_tow_contract");
    steps.append("handoff_foxnet_to_job04");
    return steps;
}

def forbidden_for_job09 -> list[str] {
    xs: list[str] = [];
    xs.append("foxnet_host");
    xs.append("pc_phone_route");
    xs.append("wrecking_yard_logic");
    xs.append("auction_logic");
    return xs;
}

def build_job_graph -> graph_store {
    gs = graph_store();
    j09 = job(job_id="JOB-09", label="tow");
    j04 = job(job_id="JOB-04", label="foxnet");
    j13 = job(job_id="JOB-13", label="auction");
    jhub = job(job_id="JOB-HUB", label="shared_hub");
    c_tow = capability(cap_id="tow_dispatch", label="dispatch");
    c_fox = capability(cap_id="foxnet_host", label="foxnet");
    c_auct = capability(cap_id="auction_logic", label="auction");
    c_read = capability(cap_id="shared_read", label="read");
    root ++> j09;
    root ++> j04;
    root ++> j13;
    root ++> jhub;
    j09 +>:owns:+> c_tow;
    j04 +>:owns:+> c_fox;
    j13 +>:owns:+> c_auct;
    jhub +>:owns:+> c_read;
    j09 +>:depends:+> j13;
    j09 +>:depends:+> j04;
    j13 +>:depends:+> jhub;
    j04 +>:depends:+> jhub;
    gs.by_id["JOB-09"] = j09;
    gs.by_id["JOB-04"] = j04;
    gs.by_id["JOB-13"] = j13;
    gs.by_id["JOB-HUB"] = jhub;
    return gs;
}

def boundary_violation(actor: str, capability: str) -> bool {
    if actor != "JOB-09" {
        return False;
    }
    banned: list[str] = forbidden_for_job09();
    for b in banned {
        if capability == b {
            return True;
        }
    }
    return False;
}

def validate_step_order(performed: list[str]) -> bool {
    canon: list[str] = recovery_sequence();
    idx: int = 0;
    for step in performed {
        if idx >= len(canon) {
            return False;
        }
        if step != canon[idx] {
            return False;
        }
        idx += 1;
    }
    return True;
}

def reachable_capabilities(job_id: str) -> list[str] {
    store = build_job_graph();
    if not (job_id in store.by_id) {
        return [];
    }
    target = store.by_id[job_id];
    w = target spawn reach_caps(claimed={}, start_job=job_id);
    out: list[str] = sorted(w.caps);
    return out;
}

def incident_classification(performed_steps: list[str], cross_job_actions: list[str]) -> str {
    if not validate_step_order(performed_steps) {
        return "failed_order_of_operations";
    }
    for cap in cross_job_actions {
        if boundary_violation("JOB-09", cap) {
            return "boundary_violation";
        }
    }
    return "ok";
}

test "diamond_revisit_unique" {
    caps = reachable_capabilities("JOB-09");
    assert caps == ["auction_logic", "foxnet_host", "shared_read", "tow_dispatch"];;
}

test "unknown_job_empty" {
    assert reachable_capabilities("JOB-99") == [];;
}

test "boundary_violation_job09_foxnet" {
    assert boundary_violation("JOB-09", "foxnet_host") == True;;
    assert boundary_violation("JOB-04", "foxnet_host") == False;;
}

test "validate_step_order_rejects_skip" {
    skipped: list[str] = [];
    skipped.append("stabilize_job09_backend");
    skipped.append("rebuild_tow_ui");
    assert validate_step_order(skipped) == False;;
    canon: list[str] = recovery_sequence();
    assert validate_step_order(canon) == True;;
}

test "incident_classifies_boundary_zip" {
    good_prefix: list[str] = [];
    good_prefix.append("stabilize_job09_backend");
    good_prefix.append("remove_old_tow_web");
    good_prefix.append("preserve_weui_master_settings");
    good_prefix.append("prove_ugly_native_read");
    cross: list[str] = [];
    cross.append("pc_phone_route");
    assert incident_classification(good_prefix, cross) == "boundary_violation";;
}
