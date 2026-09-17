# larryboiNEUQ/pi-auto-review#21
# Spec: narrow reviewer intent to the exact action; scope = blast radius
# of the exact action in the dossier, not the surrounding task's width.

node Action {
    has aid: str;
    has kind: str;                 # read | inspect | delete | eval | commit | export
    has targets: int = 1;          # how many targets this step touches
    has unbounded: bool = False;   # wildcard / recursive / unresolved destination
    has bundled: bool = False;     # bundles unrelated side effects
}

edge DEP;                          # payload step depends-on / chains-to step

node Session {
    has sid: str;
    has task_width: str = "narrow";   # task narrative, NOT action scope
    has user_auth: str = "high";
}

walker classify {
    has claimed: dict[str, bool] = {};
    has total_targets: int = 0;
    has any_unbounded: bool = False;
    has any_bundled: bool = False;
    has leaves: list[str] = [];

    can step with Action entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        self.total_targets += here.targets;
        if here.unbounded { self.any_unbounded = True; }
        if here.bundled { self.any_bundled = True; }
        kids: list[Action] = [here ->:DEP:->][?:Action];
        if len(kids) == 0 { self.leaves.append(here.aid); }
        visit kids;
    }
}

def _classify_payload(start: Action) -> dict {
    wk = start spawn classify(claimed={});
    # blast radius of the EXACT payload only
    if wk.any_unbounded or wk.any_bundled {
        scope = "broad";
    } elif wk.total_targets > 1 {
        scope = "broad";
    } else {
        scope = "narrow";
    }
    high_risk: bool = False;
    if scope == "broad" and wk.any_unbounded { high_risk = True; }
    risk = "low";
    if high_risk { risk = "high"; }
    return {"scope": scope, "riskLevel": risk,
            "targets": wk.total_targets, "leaves": sorted(wk.leaves)};
}

def review_action(start: Action) -> dict {
    return _classify_payload(start);
}

def guard_decision(start: Action, session: Session) -> str {
    v = _classify_payload(start);
    # code floor: high risk requires narrow scope, regardless of authorization
    if v["riskLevel"] == "high" and v["scope"] != "narrow" {
        return "deny";
    }
    # task narrative may inform authorization but never sets scope or risk
    if session.user_auth == "high" {
        return "allow";
    }
    return "deny";
}

def register_session(sid: str, width: str, auth: str) -> Session {
    s = Session(sid=sid, task_width=width, user_auth=auth);
    return s;
}
