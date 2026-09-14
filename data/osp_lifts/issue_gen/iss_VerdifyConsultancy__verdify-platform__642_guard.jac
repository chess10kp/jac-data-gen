# iss_VerdifyConsultancy__verdify-platform__642.jac

node LaunchState {
    has experiment_id: str;
    has generation: int = 0;
    has phase: str = "draft";
    has component_enabled: bool = False;
    has proof_passed: bool = False;
    has freezer_ready: bool = False;
    has active_attempt: str = "";
    has baseline_epochs: int = 0;
    has aggressive_epochs: int = 0;
}

node ProofAttempt {
    has attempt_id: str;
    has generation: int;
    has baseline_count: int = 0;
    has aggressive_count: int = 0;
    has sealed: bool = False;
    has receipt_id: str = "";
}

node ProofEpoch {
    has epoch_id: str;
    has kind: str;
    has generation: int;
    has complete: bool = False;
}

node Assignment {
    has assignment_id: str;
    has selector_choice: str = "";
    has fallback_choice: str = "";
    has frozen_identity: str = "";
    has randomized: bool = False;
    has finalized: bool = False;
}

node Work {
    has work_id: str;
    has exclusive_writer: str;
    has completed: bool = False;
}

node Exposure {
    has exposure_id: str;
    has receipt_id: str;
    has assignment_id: str;
    has work_id: str;
    has is_open: bool = True;
}

edge HasAttempt {}
edge HasEpoch {}
edge HasAssignment {}
edge HasWork {}
edge HasExposure {}

walker LineageWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can scan_state with LaunchState entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scan launch state");
        self.found.append("state:" + here.experiment_id);
        for attempt in [here ->:HasAttempt:->][?:ProofAttempt] {
            visit :0: [attempt];
        }
        for epoch in [here ->:HasEpoch:->][?:ProofEpoch] {
            visit :0: [epoch];
        }
        for assignment in [here ->:HasAssignment:->][?:Assignment] {
            visit :0: [assignment];
        }
        for exposure in [here ->:HasExposure:->][?:Exposure] {
            visit :0: [exposure];
        }
    }

    can scan_attempt with ProofAttempt entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scan proof attempt");
        self.found.append("attempt:" + here.attempt_id);
        for epoch in [here ->:HasEpoch:->][?:ProofEpoch] {
            visit :0: [epoch];
        }
    }

    can scan_epoch with ProofEpoch entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scan proof epoch");
        self.found.append("epoch:" + here.epoch_id);
    }

    can scan_assignment with Assignment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scan assignment");
        self.found.append("assignment:" + here.assignment_id);
        for work in [here ->:HasWork:->][?:Work] {
            visit :0: [work];
        }
        for exposure in [here ->:HasExposure:->][?:Exposure] {
            visit :0: [exposure];
        }
    }

    can scan_work with Work entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scan physical work");
        self.found.append("work:" + here.work_id);
        for exposure in [here ->:HasExposure:->][?:Exposure] {
            visit :0: [exposure];
        }
    }

    can scan_exposure with Exposure entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scan exposure");
        self.found.append("exposure:" + here.exposure_id);
    }
}

walker ExposureFinder {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: Exposure | None = None;

    can find_state with LaunchState entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("find exposures from state");
        for exposure in [here ->:HasExposure:->][?:Exposure] {
            visit :0: [exposure];
        }
        for assignment in [here ->:HasAssignment:->][?:Assignment] {
            visit :0: [assignment];
        }
    }

    can find_assignment with Assignment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("find exposures from assignment");
        for exposure in [here ->:HasExposure:->][?:Exposure] {
            visit :0: [exposure];
        }
    }

    can find_exposure with Exposure entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("inspect exposure");
        if self.found == None and here.exposure_id == self.wanted {
            self.found = here;
        }
    }
}

def create_launch(experiment_id: str, generation: int) -> LaunchState {
    return LaunchState(experiment_id=experiment_id, generation=generation);
}

def record_attempt(state: LaunchState, attempt_id: str, generation: int) -> ProofAttempt {
    attempt = ProofAttempt(attempt_id=attempt_id, generation=generation);
    state +>:HasAttempt:+> attempt;
    state.active_attempt = attempt_id;
    return attempt;
}

def record_epoch(
    state: LaunchState,
    attempt: ProofAttempt,
    epoch_id: str,
    kind: str,
    generation: int,
    complete: bool
) -> ProofEpoch {
    epoch = ProofEpoch(
        epoch_id=epoch_id,
        kind=kind,
        generation=generation,
        complete=complete
    );
    state +>:HasEpoch:+> epoch;
    attempt +>:HasEpoch:+> epoch;
    if complete and kind == "baseline" {
        attempt.baseline_count += 1;
        state.baseline_epochs += 1;
    }
    if complete and kind == "aggressive" {
        attempt.aggressive_count += 1;
        state.aggressive_epochs += 1;
    }
    return epoch;
}

def seal_attempt(
    state: LaunchState,
    attempt: ProofAttempt,
    receipt_id: str
) -> bool {
    if attempt.generation != state.generation { return False; }
    if state.active_attempt != attempt.attempt_id { return False; }
    if attempt.baseline_count < 2 { return False; }
    if attempt.aggressive_count < 1 { return False; }
    attempt.sealed = True;
    attempt.receipt_id = receipt_id;
    state.proof_passed = True;
    state.phase = "proof_passed";
    return True;
}

def select_assignment(
    state: LaunchState,
    assignment_id: str,
    selector_choice: str,
    fallback_choice: str
) -> Assignment {
    assignment = Assignment(
        assignment_id=assignment_id,
        selector_choice=selector_choice,
        fallback_choice=fallback_choice,
        frozen_identity=state.experiment_id + ":" + assignment_id,
        randomized=selector_choice != ""
    );
    state +>:HasAssignment:+> assignment;
    return assignment;
}

def finalize_assignment(state: LaunchState, assignment: Assignment) -> bool {
    if not state.proof_passed { return False; }
    if assignment.selector_choice == "" and assignment.fallback_choice == "" {
        return False;
    }
    assignment.finalized = True;
    state.phase = "assignment_ready";
    return True;
}

def bind_work(assignment: Assignment, work_id: str, writer: str) -> Work {
    work = Work(work_id=work_id, exclusive_writer=writer);
    assignment +>:HasWork:+> work;
    return work;
}

def complete_work(work: Work) -> bool {
    if work.completed { return False; }
    work.completed = True;
    return True;
}

def open_exposure(
    state: LaunchState,
    assignment: Assignment,
    work: Work,
    exposure_id: str,
    receipt_id: str
) -> bool {
    if not state.proof_passed { return False; }
    if not assignment.finalized { return False; }
    if not work.completed { return False; }
    exposure = Exposure(
        exposure_id=exposure_id,
        receipt_id=receipt_id,
        assignment_id=assignment.assignment_id,
        work_id=work.work_id
    );
    state +>:HasExposure:+> exposure;
    assignment +>:HasExposure:+> exposure;
    work +>:HasExposure:+> exposure;
    state.phase = "open";
    return True;
}

def close_exposure(state: LaunchState, exposure: Exposure) -> bool {
    if not exposure.is_open { return False; }
    exposure.is_open = False;
    state.freezer_ready = True;
    state.phase = "freezer_ready";
    return True;
}

def close_exposure_id(state: LaunchState, exposure_id: str) -> bool {
    w = state spawn ExposureFinder(wanted=exposure_id, claimed={});
    if w.found == None { return False; }
    return close_exposure(state, w.found);
}

def advance_freezer(state: LaunchState) -> bool {
    if not state.freezer_ready { return False; }
    if state.phase == "frozen" { return False; }
    state.phase = "frozen";
    return True;
}

def lineage(state: LaunchState) -> list[str] {
    w = state spawn LineageWalker(claimed={});
    return w.found;
}

test "diamond_revisit_is_claimed_once" {
    state = create_launch("exp-diamond", 7);
    first = record_attempt(state, "attempt-a", 7);
    second = record_attempt(state, "attempt-b", 7);
    shared = ProofEpoch(
        epoch_id="shared",
        kind="baseline",
        generation=7,
        complete=True
    );
    state +>:HasEpoch:+> shared;
    first +>:HasEpoch:+> shared;
    second +>:HasEpoch:+> shared;
    paths = lineage(state);
    assert (len(paths) == 4);
}

test "unknown_exposure_is_tolerated" {
    state = create_launch("exp-unknown", 1);
    assert (not close_exposure_id(state, "missing"));
    assert (not advance_freezer(state));
}

test "proof_requires_one_attempt_and_two_baselines" {
    state = create_launch("exp-proof", 3);
    attempt = record_attempt(state, "attempt-1", 3);
    record_epoch(state, attempt, "b1", "baseline", 3, True);
    record_epoch(state, attempt, "a1", "aggressive", 3, True);
    assert (not seal_attempt(state, attempt, "receipt-too-early"));
    record_epoch(state, attempt, "b2", "baseline", 3, True);
    assert (seal_attempt(state, attempt, "receipt-1"));
    assert (state.proof_passed);
}

test "randomized_assignment_closes_before_freezer" {
    state = create_launch("exp-day-one", 9);
    attempt = record_attempt(state, "attempt-1", 9);
    record_epoch(state, attempt, "b1", "baseline", 9, True);
    record_epoch(state, attempt, "a1", "aggressive", 9, True);
    record_epoch(state, attempt, "b2", "baseline", 9, True);
    assert (seal_attempt(state, attempt, "proof-1"));
    assignment = select_assignment(state, "assign-1", "treatment", "control");
    assert (finalize_assignment(state, assignment));
    work = bind_work(assignment, "work-1", "exclusive-writer");
    assert (complete_work(work));
    assert (open_exposure(state, assignment, work, "exposure-1", "receipt-1"));
    assert (close_exposure_id(state, "exposure-1"));
    assert (state.freezer_ready);
    assert (advance_freezer(state));
    assert (state.phase == "frozen");
}
