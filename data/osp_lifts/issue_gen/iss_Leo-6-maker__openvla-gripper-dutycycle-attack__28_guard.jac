# PROGRAM iss_Leo-6-maker__openvla-gripper-dutycycle-attack__28.jac

node Handoff {
    has task: str;
    has model_fingerprint: str;
}

node Frame {
    has frame_id: str;
    has state: str;
    has absolute_step: int;
    has lambda_value: float;
    has target_token: int;
    has selected: bool = True;
}

node InputPackage {
    has frame_id: str;
    has raw_rgb_sha: str;
    has canonical_tensor_sha: str;
    has prompt_token_sha: str;
    has model_fingerprint: str;
    has clean_action: str;
    has clean_tokens: list[int];
    has arm_prefix: list[int];
    has gripper_token: int;
    has trace_sha: str;
    has action_sha: str;
    has env_sha: str;
    has obs_sha: str;
}

edge ContainsFrame {}
edge ParentOf {}
edge ChildOf {}
edge HasPackage {}

walker LocateFrame {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: Frame | None = None;

    can scan_handoff with Handoff entry {
        print("locating frames");
        for frame in [here ->:ContainsFrame:->][?:Frame] {
            visit :0: [frame];
        }
    }

    can scan_frame with Frame entry {
        if here.frame_id in self.claimed {
            skip;
        }
        self.claimed[here.frame_id] = True;
        print("checking frame");
        if here.frame_id == self.target {
            self.found = here;
        }
    }
}

walker Descendants {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can walk with Frame entry {
        if here.frame_id in self.claimed {
            skip;
        }
        self.claimed[here.frame_id] = True;
        self.ids.append(here.frame_id);
        print("walking descendants");
        for child in [here ->:ParentOf:->][?:Frame] {
            visit :0: [child];
        }
    }
}

walker Lineage {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can walk with Frame entry {
        if here.frame_id in self.claimed {
            skip;
        }
        self.claimed[here.frame_id] = True;
        self.ids.insert(0, here.frame_id);
        print("walking lineage");
        for parent in [here ->:ChildOf:->][?:Frame] {
            visit :0: [parent];
        }
    }
}

walker PackageAudit {
    has complete: bool = False;

    can inspect with Frame entry {
        print("auditing package");
        for pkg in [here ->:HasPackage:->][?:InputPackage] {
            if pkg.raw_rgb_sha != "" and
               pkg.canonical_tensor_sha != "" and
               pkg.prompt_token_sha != "" and
               pkg.model_fingerprint != "" and
               pkg.clean_action != "" and
               len(pkg.clean_tokens) == 7 and
               len(pkg.arm_prefix) > 0 and
               pkg.gripper_token >= 0 and
               pkg.trace_sha != "" and
               pkg.action_sha != "" and
               pkg.env_sha != "" and
               pkg.obs_sha != "" {
                self.complete = True;
            }
        }
    }
}

walker SelectedFrames {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can collect_handoff with Handoff entry {
        print("collecting selected frames");
        for frame in [here ->:ContainsFrame:->][?:Frame] {
            visit :0: [frame];
        }
    }

    can collect_frame with Frame entry {
        if here.frame_id in self.claimed {
            skip;
        }
        self.claimed[here.frame_id] = True;
        print("checking selection");
        if here.selected {
            self.ids.append(here.frame_id);
        }
    }
}

walker Program {
    can start with entry {
        root spawn SelectedFrames;
        print("Layer3 handoff audit started");
    }
}

def new_handoff(task: str, model_fingerprint: str) -> Handoff {
    return Handoff(task=task, model_fingerprint=model_fingerprint);
}

def add_frame(
    handoff: Handoff,
    frame_id: str,
    state: str,
    absolute_step: int,
    lambda_value: float,
    target_token: int,
    parent_id: str | None = None
) -> Frame {
    frame = Frame(
        frame_id=frame_id,
        state=state,
        absolute_step=absolute_step,
        lambda_value=lambda_value,
        target_token=target_token
    );
    handoff +>:ContainsFrame:+> frame;
    if parent_id is not None {
        locator = handoff spawn LocateFrame(target=parent_id, claimed={});
        if locator.found is not None {
            parent = locator.found;
            parent +>:ParentOf:+> frame;
            frame +>:ChildOf:+> parent;
        }
    }
    return frame;
}

def frame_lineage(handoff: Handoff, frame_id: str) -> list[str] {
    locator = handoff spawn LocateFrame(target=frame_id, claimed={});
    if locator.found is None {
        return [];
    }
    target = locator.found;
    lineage = target spawn Lineage(claimed={});
    return lineage.ids;
}

def reachable_frames(handoff: Handoff, frame_id: str) -> list[str] {
    locator = handoff spawn LocateFrame(target=frame_id, claimed={});
    if locator.found is None {
        return [];
    }
    target = locator.found;
    descendants = target spawn Descendants(claimed={});
    return sorted(descendants.ids);
}

def seal_package(
    frame: Frame,
    raw_rgb_sha: str,
    canonical_tensor_sha: str,
    prompt_token_sha: str,
    model_fingerprint: str,
    clean_action: str,
    clean_tokens: list[int],
    arm_prefix: list[int],
    gripper_token: int,
    trace_sha: str,
    action_sha: str,
    env_sha: str,
    obs_sha: str
) -> InputPackage {
    package = InputPackage(
        frame_id=frame.frame_id,
        raw_rgb_sha=raw_rgb_sha,
        canonical_tensor_sha=canonical_tensor_sha,
        prompt_token_sha=prompt_token_sha,
        model_fingerprint=model_fingerprint,
        clean_action=clean_action,
        clean_tokens=clean_tokens,
        arm_prefix=arm_prefix,
        gripper_token=gripper_token,
        trace_sha=trace_sha,
        action_sha=action_sha,
        env_sha=env_sha,
        obs_sha=obs_sha
    );
    frame +>:HasPackage:+> package;
    return package;
}

def package_complete(handoff: Handoff, frame_id: str) -> bool {
    locator = handoff spawn LocateFrame(target=frame_id, claimed={});
    if locator.found is None {
        return False;
    }
    target = locator.found;
    audit = target spawn PackageAudit;
    return audit.complete;
}

def selected_frame_ids(handoff: Handoff) -> list[str] {
    selected = handoff spawn SelectedFrames(claimed={});
    return sorted(selected.ids);
}

def expected_job_count(handoff: Handoff, jobs_per_frame: int = 2) -> int {
    ids: list[str] = selected_frame_ids(handoff);
    return len(ids) * jobs_per_frame;
}

# TESTS

test "diamond revisit is claimed once" {
    h = new_handoff("L3", "model-v4");
    r = add_frame(h, "root", "state0", 78, 2.0, 31744);
    a = add_frame(h, "a", "state0", 78, 2.0, 31744, "root");
    b = add_frame(h, "b", "state0", 78, 2.0, 31744, "root");
    d = add_frame(h, "d", "state0", 78, 2.0, 31744, "a");
    b +>:ParentOf:+> d;
    d +>:ChildOf:+> b;
    assert (reachable_frames(h, "root") == ["a", "b", "d", "root"]);
}

test "unknown frame is tolerated" {
    h = new_handoff("L3", "model-v4");
    add_frame(h, "known", "state0", 78, 2.0, 31744);
    assert (frame_lineage(h, "missing") == []);
    assert (reachable_frames(h, "missing") == []);
    assert (package_complete(h, "missing") == False);
}

test "lineage preserves parent chain" {
    h = new_handoff("L3", "model-v4");
    add_frame(h, "root", "state0", 78, 2.0, 31744);
    add_frame(h, "child", "state0", 78, 2.0, 31744, "root");
    add_frame(h, "leaf", "state0", 78, 2.0, 31744, "child");
    assert (frame_lineage(h, "leaf") == ["root", "child", "leaf"]);
}

test "complete package requires seven tokens and source hashes" {
    h = new_handoff("L3", "model-v4");
    f = add_frame(h, "frame_0001", "state0", 78, 2.0, 31744);
    tokens: list[int] = [1, 2, 3, 4, 5, 6, 7];
    prefix: list[int] = [10, 11];
    seal_package(
        f, "raw", "tensor", "prompt", "model-v4", "action",
        tokens, prefix, 99, "trace", "action-sha", "env", "obs"
    );
    assert (package_complete(h, "frame_0001") == True);
}

test "job denominator counts selected frames exactly" {
    h = new_handoff("L3", "model-v4");
    add_frame(h, "selected_a", "state0", 78, 2.0, 31744);
    add_frame(h, "selected_b", "state1", 78, 2.0, 31744);
    f = add_frame(h, "excluded", "state0", 78, 2.0, 31744);
    f.selected = False;
    assert (selected_frame_ids(h) == ["selected_a", "selected_b"]);
    assert (expected_job_count(h) == 4);
}
