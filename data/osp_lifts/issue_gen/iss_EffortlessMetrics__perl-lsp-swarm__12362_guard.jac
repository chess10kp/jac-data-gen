"""EffortlessMetrics/perl-lsp-swarm#12362
Typed, versioned external-substrate dependency declarations for editor claims.
"""

node Claim {
    has claim_id: str;
    has claim_version: str;
    has semantic_identity: str;
    has subject: str;
    has checked: bool = False;
    has ceiling: int = 100;
}

node Dependency {
    has dependency_id: str = "";
    has dependency_version: str = "";
    has semantic_identity: str = "";
    has owner_claim_id: str = "";
    has owner_claim_version: str = "";
    has claim_subject: str = "";
    has source_family: str = "";
    has source_schema: str = "";
    has validator_identity: str = "";
    has profile_id: str = "";
    has profile_version: str = "";
    has profile_semantic_identity: str = "";
    has required_row_id: str = "";
    has disposition: str = "";
    has external_subject: str = "";
    has relation: str = "";
    has stage_relation: str = "";
    has currentness_inputs: str = "";
    has invalidation_inputs: str = "";
    has allowed_result_states: str = "";
    has limitation_law: str = "";
    has blocker_law: str = "";
    has wake_event: str = "";
    has ceiling_rule: str = "";
    has history_relation: str = "";
    has ceiling: int = 100;
}

node ExternalRow {
    has row_id: str;
    has subject: str;
    has result_state: str;
    has currentness: str;
}

edge Child {}
edge DependsOn {}
edge Requires {}

walker ContractWalk {
    has claimed: dict[str, bool] = {};
    has errors: list[str] = [];
    has projected: list[str] = [];
    has eligible: dict[str, bool] = {};
    has claim_ceiling: dict[str, int] = {};
    has expected_subject: dict[str, str] = {};

    can inspect_claim with Claim entry {
        claim_key: str = "claim:" + here.claim_id;
        if claim_key in self.claimed { skip; }
        self.claimed[claim_key] = True;
        self.eligible[here.claim_id] = here.checked;
        self.claim_ceiling[here.claim_id] = here.ceiling;
        print("claim " + here.claim_id);
        for dep in [here ->:DependsOn:->][?:Dependency] {
            if !here.checked {
                self.errors.append("unchecked claim " + here.claim_id);
            }
            visit :0: [dep];
        }
        for kid in [here ->:Child:->][?:Claim] {
            visit :0: [kid];
        }
    }

    can inspect_dependency with Dependency entry {
        dep_key: str = "dependency:" + here.dependency_id;
        if dep_key in self.claimed { skip; }
        self.claimed[dep_key] = True;
        print("dependency " + here.dependency_id);
        if !(here.disposition == "required" || here.disposition == "conditional" ||
             here.disposition == "optional" || here.disposition == "unsupported" ||
             here.disposition == "not-applicable") {
            self.errors.append("invalid disposition " + here.dependency_id);
        }
        if here.disposition == "conditional" && here.external_subject == "" {
            self.errors.append("missing selector " + here.dependency_id);
        }
        if here.owner_claim_id == "" || here.claim_subject == "" ||
           here.source_schema == "" || here.validator_identity == "" ||
           here.profile_id == "" || here.required_row_id == "" ||
           here.relation == "" || here.stage_relation == "" ||
           here.currentness_inputs == "" || here.invalidation_inputs == "" ||
           here.allowed_result_states == "" || here.limitation_law == "" ||
           here.blocker_law == "" || here.wake_event == "" ||
           here.ceiling_rule == "" || here.history_relation == "" {
            self.errors.append("incomplete dependency " + here.dependency_id);
        }
        if here.owner_claim_id in self.eligible && self.eligible[here.owner_claim_id] {
            effective: int = here.ceiling;
            if here.owner_claim_id in self.claim_ceiling &&
               self.claim_ceiling[here.owner_claim_id] < effective {
                effective = self.claim_ceiling[here.owner_claim_id];
            }
            self.projected.append(here.owner_claim_id + "|" + here.dependency_id +
                "|" + here.required_row_id + "|" + here.disposition + "|" +
                str(effective));
        }
        if here.required_row_id in self.expected_subject &&
           self.expected_subject[here.required_row_id] != here.external_subject {
            self.errors.append("subject conflict " + here.required_row_id);
        }
        self.expected_subject[here.required_row_id] = here.external_subject;
        for row in [here ->:Requires:->][?:ExternalRow] {
            visit :0: [row];
        }
    }

    can inspect_row with ExternalRow entry {
        row_key: str = "row:" + here.row_id;
        if row_key in self.claimed { skip; }
        self.claimed[row_key] = True;
        print("external row " + here.row_id);
        if here.currentness != "current" {
            self.errors.append("non-current row " + here.row_id);
        }
        if !(here.result_state == "pass" || here.result_state == "limited" ||
             here.result_state == "blocked" || here.result_state == "absent" ||
             here.result_state == "conflicting") {
            self.errors.append("invalid result " + here.row_id);
        }
    }
}

walker FindClaim {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: Claim | None = None;

    can search with Claim entry {
        if self.found != None { skip; }
        claim_key: str = "claim:" + here.claim_id;
        if claim_key in self.claimed { skip; }
        self.claimed[claim_key] = True;
        print("search " + here.claim_id);
        if here.claim_id == self.wanted {
            self.found = here;
        }
        for kid in [here ->:Child:->][?:Claim] {
            visit :0: [kid];
        }
    }
}

def new_claim(claim_id: str, subject: str, checked: bool = False,
              ceiling: int = 100) -> Claim {
    return Claim(claim_id=claim_id, claim_version="v1",
        semantic_identity=claim_id + "@v1", subject=subject,
        checked=checked, ceiling=ceiling);
}

def declare_dependency(claim: Claim, dependency_id: str,
    required_row_id: str, disposition: str, external_subject: str,
    relation: str, dependency_version: str = "v1",
    source_family: str = "external-status",
    source_schema: str = "external_status.v1",
    profile_id: str = "external-profile",
    profile_version: str = "v1", ceiling: int = 100) -> Dependency {
    dep = Dependency(dependency_id=dependency_id,
        dependency_version=dependency_version,
        semantic_identity=dependency_id + "@" + dependency_version,
        owner_claim_id=claim.claim_id,
        owner_claim_version=claim.claim_version,
        claim_subject=claim.subject, source_family=source_family,
        source_schema=source_schema, validator_identity="checked-contract-v1",
        profile_id=profile_id, profile_version=profile_version,
        profile_semantic_identity=profile_id + "@" + profile_version,
        required_row_id=required_row_id, disposition=disposition,
        external_subject=external_subject, relation=relation,
        stage_relation="source-package-process-client",
        currentness_inputs="source-currentness",
        invalidation_inputs="supersession-or-conflict",
        allowed_result_states="pass|limited|blocked|absent|conflicting",
        limitation_law="propagate-limitations",
        blocker_law="dependency-blocks-claim",
        wake_event="external-status-update",
        ceiling_rule="minimum", history_relation="supersedes",
        ceiling=ceiling);
    claim +>:DependsOn:+> dep;
    return dep;
}

def validate_contract(graph_root: Claim) -> list[str] {
    w = graph_root spawn ContractWalk(claimed={});
    return sorted(w.errors);
}

def project_contract(graph_root: Claim) -> list[str] {
    w = graph_root spawn ContractWalk(claimed={});
    return sorted(w.projected);
}

def find_claim(graph_root: Claim, claim_id: str) -> Claim | None {
    w = graph_root spawn FindClaim(wanted=claim_id, claimed={});
    return w.found;
}

test "diamond revisit remains complete" {
    graph_root = new_claim("root", "repo:root", True, 90);
    left = new_claim("left", "repo:left", True, 80);
    right = new_claim("right", "repo:right", True, 80);
    shared = new_claim("shared", "repo:shared", True, 70);
    graph_root +>:Child:+> left;
    graph_root +>:Child:+> right;
    left +>:Child:+> shared;
    right +>:Child:+> shared;
    dep = declare_dependency(shared, "dep-1", "row-1", "required",
        "repo:shared", "same-source", "v1", "external-status",
        "external_status.v1", "compiler-profile", "v1", 60);
    row = ExternalRow(row_id="row-1", subject="repo:shared",
        result_state="pass", currentness="current");
    dep +>:Requires:+> row;
    assert (validate_contract(graph_root) == []);
    assert (project_contract(graph_root) == ["shared|dep-1|row-1|required|60"]);
}

test "unknown claim id is tolerated" {
    graph_root = new_claim("known", "repo:known", True);
    assert (find_claim(graph_root, "missing") == None);
}

test "conditional selector and unchecked claim are rejected" {
    graph_root = new_claim("unchecked", "repo:u", False);
    dep = declare_dependency(graph_root, "dep-2", "row-2", "conditional",
        "", "same-source");
    row = ExternalRow(row_id="row-2", subject="",
        result_state="pass", currentness="current");
    dep +>:Requires:+> row;
    errors = validate_contract(graph_root);
    assert (len(errors) >= 2);
}

test "limitation uses the combined ceiling" {
    graph_root = new_claim("claim", "repo:claim", True, 75);
    dep = declare_dependency(graph_root, "dep-3", "row-3", "optional",
        "repo:claim", "same-project-root-config", "v1", "external-status",
        "external_status.v1", "profile-3", "v2", 50);
    row = ExternalRow(row_id="row-3", subject="repo:claim",
        result_state="limited", currentness="current");
    dep +>:Requires:+> row;
    assert (project_contract(graph_root) == ["claim|dep-3|row-3|optional|50"]);
}
