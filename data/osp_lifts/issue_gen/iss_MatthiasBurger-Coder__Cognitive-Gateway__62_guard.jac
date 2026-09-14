# issue_gen/iss_MatthiasBurger-Coder__Cognitive-Gateway__62.jac
"""MatthiasBurger-Coder/Cognitive-Gateway#62 — declarative delta planning."""

node DesiredCondition {
    has cid: str;
    has key: str;
    has expected: str;
    has required: bool = True;
    has evidence_required: bool = False;
    has question: bool = False;
    has mode: str = "state";
}
node Observation {
    has oid: str;
    has key: str;
    has actual: str;
    has evidence: str = "";
}
node Delta {
    has did: str;
    has kind: str;
    has condition_id: str;
    has observation_id: str = "";
    has observed_value: str = "";
    has evidence: str = "";
    has detail: str = "";
}
node CapabilityRequirement {
    has rid: str;
    has capability_id: str;
    has delta_id: str;
    has rationale: str;
}
node PlanStep {
    has sid: str;
    has delta_id: str;
    has capability_id: str;
    has depends_on: list[str] = [];
    has completion: str;
    has verification: str;
}
node Plan {
    has pid: str;
    has steps: list[PlanStep] = [];
    has template_id: str = "";
    has rationale: str = "";
    has contradiction: bool = False;
    has valid: bool = True;
}
node ComparisonRoot {
    has rid: str;
}
edge HasCondition {}
edge HasObservation {}
edge RequiresCapability {}
edge Contains {}
edge DependsOn {}

walker CompareWalker {
    has claimed: dict[str, bool] = {};
    has observations: list[Observation] = [];
    has deltas: list[Delta] = [];

    can compare with ComparisonRoot entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        for observation in [here ->:HasObservation:->][?:Observation] {
            self.observations.append(observation);
        }
        for condition in [here ->:HasCondition:->][?:DesiredCondition] {
            kind: str = "";
            observation_id: str = "";
            actual: str = "";
            evidence: str = "";
            matches: list[Observation] = [];
            if condition.question {
                kind = "unresolved_question";
            }
            if condition.question == False {
                for observation in self.observations {
                    if observation.key == condition.key {
                        matches.append(observation);
                    }
                }
                if len(matches) == 0 {
                    if condition.mode == "capability" {
                        kind = "missing_capability";
                    } elif condition.evidence_required {
                        kind = "missing_evidence";
                    } elif condition.required {
                        kind = "unmet_condition";
                    }
                } elif len(matches) > 0 {
                    observation_ids: list[str] = [];
                    for observation in matches {
                        observation_ids.append(observation.oid);
                    }
                    chosen_id: str = sorted(observation_ids)[0];
                    for observation in matches {
                        if observation.oid == chosen_id {
                            observation_id = observation.oid;
                            actual = observation.actual;
                            evidence = observation.evidence;
                        }
                    }
                    if condition.evidence_required and evidence == "" {
                        kind = "missing_evidence";
                    } elif actual != condition.expected {
                        kind = "violation";
                    }
                }
            }
            if kind != "" {
                self.deltas.append(Delta(
                    did=condition.cid + ":delta",
                    kind=kind,
                    condition_id=condition.cid,
                    observation_id=observation_id,
                    observed_value=actual,
                    evidence=evidence,
                    detail=condition.key
                ));
            }
        }
        print("delta comparison complete");
    }
}

walker PlanAudit {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];
    has cycle: bool = False;

    can audit_plan with Plan entry {
        for step in [here ->:Contains:->][?:PlanStep] {
            visit :0: [step];
        }
        print("plan audit started");
    }

    can audit_step with PlanStep entry {
        if here.sid in self.claimed {
            self.cycle = True;
            skip;
        }
        self.claimed[here.sid] = True;
        self.ids.append(here.sid);
        for dependency in [here ->:DependsOn:->][?:PlanStep] {
            visit :0: [dependency];
        }
        print("audited " + here.sid);
    }
}

def compare_state(
    conditions: list[DesiredCondition],
    observations: list[Observation]
) -> list[Delta] {
    graph_root = ComparisonRoot(rid="comparison");
    for condition in conditions {
        graph_root +>:HasCondition:+> condition;
    }
    for observation in observations {
        graph_root +>:HasObservation:+> observation;
    }
    w = graph_root spawn CompareWalker();
    return sorted(w.deltas);
}

def derive_requirements(deltas: list[Delta]) -> list[CapabilityRequirement] {
    requirements: list[CapabilityRequirement] = [];
    delta_ids: list[str] = [];
    for delta in deltas {
        delta_ids.append(delta.did);
    }
    for did in sorted(delta_ids) {
        for item in deltas {
            if item.did == did {
                capability_id: str = "cg.state.change";
                if item.kind == "missing_evidence" {
                    capability_id = "cg.evidence.collect";
                } elif item.kind == "unresolved_question" {
                    capability_id = "cg.input.request";
                } elif item.kind == "missing_capability" {
                    capability_id = "cg.capability.provide";
                } elif item.kind == "violation" {
                    capability_id = "cg.state.correct";
                }
                requirement = CapabilityRequirement(
                    rid=item.did + ":requirement",
                    capability_id=capability_id,
                    delta_id=item.did,
                    rationale="Derived from " + item.kind
                );
                requirements.append(requirement);
                item +>:RequiresCapability:+> requirement;
            }
        }
    }
    return requirements;
}

def requirement_for(
    delta_id: str,
    requirements: list[CapabilityRequirement]
) -> CapabilityRequirement | None {
    for requirement in requirements {
        if requirement.delta_id == delta_id {
            return requirement;
        }
    }
    return None;
}

def build_plan(
    deltas: list[Delta],
    requirements: list[CapabilityRequirement],
    template_id: str = ""
) -> Plan {
    plan_node = Plan(
        pid="plan",
        template_id=template_id,
        rationale="Delta-traced declarative capability plan"
    );
    delta_ids: list[str] = [];
    for delta in deltas {
        delta_ids.append(delta.did);
    }
    previous_id: str = "";
    for did in sorted(delta_ids) {
        capability_id: str = "";
        for requirement in requirements {
            if requirement.delta_id == did {
                capability_id = requirement.capability_id;
            }
        }
        step = PlanStep(
            sid="step:" + did,
            delta_id=did,
            capability_id=capability_id,
            completion="Required outcome for " + did,
            verification="Verify completion evidence for " + did
        );
        if previous_id != "" {
            step.depends_on.append(previous_id);
            for prior in plan_node.steps {
                if prior.sid == previous_id {
                    step +>:DependsOn:+> prior;
                }
            }
        }
        plan_node.steps.append(step);
        plan_node +>:Contains:+> step;
        previous_id = step.sid;
    }
    return plan_node;
}

def validate_plan(plan_node: Plan) -> bool {
    w = plan_node spawn PlanAudit();
    valid: bool = w.cycle == False and plan_node.contradiction == False;
    for step in plan_node.steps {
        if step.capability_id == "" {
            valid = False;
        } elif step.completion == "" or step.verification == "" {
            valid = False;
        }
        for dependency_id in step.depends_on {
            found: bool = False;
            for candidate in plan_node.steps {
                if candidate.sid == dependency_id {
                    found = True;
                }
            }
            if found == False {
                valid = False;
            }
        }
    }
    plan_node.valid = valid;
    return valid;
}

test "deterministic delta and plan flow" {
    c1 = DesiredCondition(cid="c1", key="status", expected="ready");
    c2 = DesiredCondition(
        cid="c2", key="approval", expected="yes", evidence_required=True
    );
    c3 = DesiredCondition(cid="c3", key="owner", expected="", question=True);
    o1 = Observation(oid="o1", key="status", actual="blocked", evidence="audit");
    o2 = Observation(oid="o2", key="approval", actual="yes");
    conditions: list[DesiredCondition] = [c3, c1, c2];
    observations: list[Observation] = [o2, o1];
    deltas = compare_state(conditions, observations);
    assert (len(deltas) == 3);
    assert (deltas[0].kind == "violation");
    assert (deltas[1].kind == "missing_evidence");
    assert (deltas[2].kind == "unresolved_question");
    requirements = derive_requirements(deltas);
    plan_node = build_plan(deltas, requirements);
    assert (validate_plan(plan_node));
}

test "diamond revisit is claimed once" {
    leaf = PlanStep(
        sid="leaf", delta_id="d4", capability_id="cg.state.change",
        completion="done", verification="checked"
    );
    left = PlanStep(
        sid="left", delta_id="d2", capability_id="cg.state.change",
        completion="done", verification="checked"
    );
    right = PlanStep(
        sid="right", delta_id="d3", capability_id="cg.state.change",
        completion="done", verification="checked"
    );
    first = PlanStep(
        sid="first", delta_id="d1", capability_id="cg.state.change",
        completion="done", verification="checked"
    );
    diamond = Plan(pid="diamond");
    diamond.steps.append(first);
    diamond.steps.append(left);
    diamond.steps.append(right);
    diamond.steps.append(leaf);
    left +>:DependsOn:+> leaf;
    right +>:DependsOn:+> leaf;
    first +>:DependsOn:+> left;
    first +>:DependsOn:+> right;
    diamond +>:Contains:+> first;
    diamond +>:Contains:+> left;
    diamond +>:Contains:+> right;
    diamond +>:Contains:+> leaf;
    w = diamond spawn PlanAudit();
    assert (len(w.ids) == 4);
}

test "unknown requirement id is tolerated" {
    condition = DesiredCondition(cid="c1", key="x", expected="y");
    observation = Observation(oid="o1", key="x", actual="z");
    conditions: list[DesiredCondition] = [condition];
    observations: list[Observation] = [observation];
    deltas = compare_state(conditions, observations);
    requirements = derive_requirements(deltas);
    assert (requirement_for("unknown", requirements) == None);
}

test "cyclic plans fail closed" {
    first = PlanStep(
        sid="first", delta_id="d1", capability_id="cg.state.change",
        completion="done", verification="checked"
    );
    second = PlanStep(
        sid="second", delta_id="d2", capability_id="cg.state.change",
        completion="done", verification="checked"
    );
    cyclic = Plan(pid="cyclic");
    cyclic.steps.append(first);
    cyclic.steps.append(second);
    cyclic +>:Contains:+> first;
    cyclic +>:Contains:+> second;
    first +>:DependsOn:+> second;
    second +>:DependsOn:+> first;
    assert (validate_plan(cyclic) == False);
}
