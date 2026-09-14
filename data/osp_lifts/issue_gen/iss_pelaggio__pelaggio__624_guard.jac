"""pelaggio/pelaggio#624 — recursive architectural reconciliation."""

edge Rel {}

node Intent {
    has cid: str;
    has text: str;
}

node Proposition {
    has cid: str;
    has text: str;
}

node Decision {
    has cid: str;
    has text: str;
    has superseded: bool = False;
}

node Assumption {
    has cid: str;
    has text: str;
    has challenged: bool = False;
}

node Constraint {
    has cid: str;
    has text: str;
    has active: bool = True;
}

node Realization {
    has cid: str;
    has text: str;
    has consequential: bool = False;
    has explained: bool = True;
    has stale: bool = False;
    has duplicated: bool = False;
    has policy_embedded: bool = False;
    has worker_owned: bool = False;
    has independent: bool = False;
    has challenges_intent: bool = False;
    has important_unexplained: bool = False;
    has disposition: str = "uncertain";
}

def _is_mismatch(item: Realization) -> bool {
    if not item.consequential { return False; }
    if not item.explained { return True; }
    if item.stale { return True; }
    if item.duplicated { return True; }
    if item.policy_embedded { return True; }
    if item.worker_owned { return True; }
    if item.independent { return True; }
    if item.challenges_intent { return True; }
    if item.important_unexplained { return True; }
    return False;
}

walker ReconcileWalker {
    has claimed: dict[str, bool] = {};
    has findings: list[str] = [];
    has only_uncertain: bool = False;
    has lookup_mode: bool = False;
    has target: str = "";
    has found: Realization | None = None;

    can scan_intent with Intent entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for kid in [here ->:Rel:->][?:Proposition] { visit :0: [kid]; }
        for kid in [here ->:Rel:->][?:Decision] { visit :0: [kid]; }
        for kid in [here ->:Rel:->][?:Assumption] { visit :0: [kid]; }
        for kid in [here ->:Rel:->][?:Constraint] { visit :0: [kid]; }
        for kid in [here ->:Rel:->][?:Realization] { visit :0: [kid]; }
    }

    can scan_proposition with Proposition entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for kid in [here ->:Rel:->][?:Realization] { visit :0: [kid]; }
    }

    can scan_decision with Decision entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for kid in [here ->:Rel:->][?:Realization] { visit :0: [kid]; }
    }

    can scan_assumption with Assumption entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for kid in [here ->:Rel:->][?:Realization] { visit :0: [kid]; }
    }

    can scan_constraint with Constraint entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for kid in [here ->:Rel:->][?:Realization] { visit :0: [kid]; }
    }

    can scan_realization with Realization entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        if self.lookup_mode {
            if here.cid == self.target { self.found = here; }
        } else {
            if _is_mismatch(here) {
                if not self.only_uncertain {
                    self.findings.append(here.cid);
                } else {
                    if here.disposition == "uncertain" {
                        self.findings.append(here.cid);
                    }
                }
            }
        }
        for kid in [here ->:Rel:->][?:Realization] { visit :0: [kid]; }
    }
}

def candidate_discrepancies(root_node: Intent) -> list[str] {
    w: ReconcileWalker = root_node spawn ReconcileWalker(
        claimed={}, only_uncertain=False, lookup_mode=False
    );
    return sorted(w.findings);
}

def reconcile(root_node: Intent) -> list[str] {
    w: ReconcileWalker = root_node spawn ReconcileWalker(
        claimed={}, only_uncertain=True, lookup_mode=False
    );
    return sorted(w.findings);
}

def lookup_realization(
    root_node: Intent, realization_id: str
) -> Realization | None {
    w: ReconcileWalker = root_node spawn ReconcileWalker(
        claimed={}, lookup_mode=True, target=realization_id
    );
    return w.found;
}

test "diamond revisit is claimed once" {
    root_node = Intent(cid="root", text="architecture");
    proposition = Proposition(cid="prop", text="one responsibility");
    decision = Decision(cid="decision", text="use workers");
    shared = Realization(
        cid="shared", text="shared mechanism",
        consequential=True, duplicated=True
    );
    deep = Realization(
        cid="deep", text="unexplained mechanism",
        consequential=True, explained=False
    );
    root_node +>:Rel:+> proposition;
    root_node +>:Rel:+> decision;
    proposition +>:Rel:+> shared;
    proposition +>:Rel:+> deep;
    decision +>:Rel:+> shared;
    assert (candidate_discrepancies(root_node) == ["deep", "shared"]);
}

test "unknown realization is tolerated" {
    root_node = Intent(cid="root", text="architecture");
    known = Realization(cid="known", text="implemented");
    root_node +>:Rel:+> known;
    assert (lookup_realization(root_node, "known") != None);
    assert (lookup_realization(root_node, "missing") == None);
}

test "only consequential evidence becomes a candidate" {
    root_node = Intent(cid="root", text="architecture");
    quiet = Realization(
        cid="quiet", text="topology difference",
        consequential=False, duplicated=True
    );
    clear = Realization(
        cid="clear", text="acceptable mechanism",
        consequential=True
    );
    root_node +>:Rel:+> quiet;
    root_node +>:Rel:+> clear;
    assert (candidate_discrepancies(root_node) == []);
    assert (reconcile(root_node) == []);
}

test "adjudicated evidence leaves residual uncertainty" {
    root_node = Intent(cid="root", text="architecture");
    accepted = Realization(
        cid="accepted", text="known mismatch",
        consequential=True, stale=True, disposition="acceptable"
    );
    unresolved = Realization(
        cid="unresolved", text="needs investigation",
        consequential=True, important_unexplained=True
    );
    root_node +>:Rel:+> accepted;
    root_node +>:Rel:+> unresolved;
    assert (candidate_discrepancies(root_node) == ["accepted", "unresolved"]);
    assert (reconcile(root_node) == ["unresolved"]);
}
