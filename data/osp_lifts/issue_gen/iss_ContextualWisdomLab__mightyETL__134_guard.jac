"""ContextualWisdomLab/mightyETL#134 — durable replay with immutable lineage."""

node Ledger {
    has label: str = "etl";
}

node Job {
    has record_id: str;
    has principal: str;
    has status: str;
    has request_digest: str;
    has replay_source_job_record_id: str | None = None;
    has replay_root_job_record_id: str | None = None;
    has replay_generation_count: int = 0;
}

edge Contains {}
edge DerivedFrom {}

obj ReplayLedger {
    has replay_keys: dict[str, str] = {};
}

walker LocateJob {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: Job | None = None;

    can step_ledger with Ledger entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("visit ledger");
        for kid in [here ->:Contains:->][?:Job] {
            visit :0: [kid];
        }
    }

    can step_job with Job entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("visit " + here.record_id);
        if here.record_id == self.wanted {
            self.found = here;
        }
        for kid in [here ->:DerivedFrom:->][?:Job] {
            visit :0: [kid];
        }
    }
}

def new_ledger() -> Ledger {
    return Ledger();
}

def new_replay_ledger() -> ReplayLedger {
    return ReplayLedger();
}

def create_job(
    record_id: str,
    principal: str,
    status: str,
    request_digest: str
) -> Job {
    return Job(
        record_id=record_id,
        principal=principal,
        status=status,
        request_digest=request_digest
    );
}

def attach_job(graph_root: Ledger, job: Job) -> None {
    graph_root +>:Contains:+> job;
}

def link_lineage(source_job: Job, replay_job_node: Job) -> None {
    source_job +>:DerivedFrom:+> replay_job_node;
}

def locate_job(graph_root: Ledger, record_id: str) -> Job | None {
    w = graph_root spawn LocateJob(wanted=record_id, claimed={});
    return w.found;
}

def validate_payload(payload: list[dict[str, str]]) -> bool {
    if len(payload) == 0 || len(payload) > 100 {
        return False;
    }
    for item in payload {
        if "id" not in item || "name" not in item {
            return False;
        }
        if item["id"] == "" || item["name"] == "" {
            return False;
        }
    }
    return True;
}

def replay_job(
    graph_root: Ledger,
    replay_state: ReplayLedger,
    source_job_record_id: str,
    principal: str,
    replay_key: str,
    payload: list[dict[str, str]],
    payload_digest: str
) -> dict[str, str] {
    result: dict[str, str] = {};

    if replay_key == "" {
        result["error"] = "etl_job_replay_key_required";
        result["http_status"] = "422";
        return result;
    }

    if !validate_payload(payload) || payload_digest == "" {
        result["error"] = "etl_job_replay_payload_mismatch";
        result["http_status"] = "422";
        return result;
    }

    source = locate_job(graph_root, source_job_record_id);
    if source == None {
        result["error"] = "etl_job_not_found";
        result["http_status"] = "404";
        return result;
    }

    source_principal: str = source.principal;
    if source_principal != principal {
        result["error"] = "etl_job_not_found";
        result["http_status"] = "404";
        return result;
    }

    source_digest: str = source.request_digest;
    if source_digest != payload_digest {
        result["error"] = "etl_job_replay_payload_mismatch";
        result["http_status"] = "422";
        return result;
    }

    source_status: str = source.status;
    if source_status == "PENDING" || source_status == "RUNNING" {
        result["error"] = "etl_job_replay_source_active";
        result["http_status"] = "409";
        return result;
    }
    if source_status == "SUCCEEDED" {
        result["error"] = "etl_job_replay_source_succeeded";
        result["http_status"] = "409";
        return result;
    }
    if source_status != "FAILED" && source_status != "CANCELLED" {
        result["error"] = "etl_job_replay_source_active";
        result["http_status"] = "409";
        return result;
    }

    semantic_key: str = principal + "|" + source_job_record_id + "|" + replay_key;
    if semantic_key in replay_state.replay_keys {
        existing_id: str = replay_state.replay_keys[semantic_key];
        existing = locate_job(graph_root, existing_id);
        if existing == None {
            result["error"] = "etl_job_replay_key_reused";
            result["http_status"] = "422";
            return result;
        }
        result["job_record_id"] = existing_id;
        result["location"] = "/api/etl/jobs/" + existing_id;
        result["status"] = "PENDING";
        result["idempotency_replayed"] = "true";
        result["http_status"] = "202";
        return result;
    }

    source_root_ref: str | None = source.replay_root_job_record_id;
    source_root_id: str = source.record_id;
    if source_root_ref != None {
        source_root_id = source_root_ref;
    }

    next_generation: int = source.replay_generation_count + 1;
    if next_generation > 100 {
        result["error"] = "etl_job_replay_generation_exhausted";
        result["http_status"] = "409";
        return result;
    }

    replay_id: str = source.record_id + "-replay-" + str(next_generation);
    replay_node = Job(
        record_id=replay_id,
        principal=principal,
        status="PENDING",
        request_digest=source_digest,
        replay_source_job_record_id=source.record_id,
        replay_root_job_record_id=source_root_id,
        replay_generation_count=next_generation
    );
    graph_root +>:Contains:+> replay_node;
    source +>:DerivedFrom:+> replay_node;
    replay_state.replay_keys[semantic_key] = replay_id;

    result["job_record_id"] = replay_id;
    result["location"] = "/api/etl/jobs/" + replay_id;
    result["status"] = "PENDING";
    result["replay_source_job_record_id"] = source.record_id;
    result["replay_root_job_record_id"] = source_root_id;
    result["replay_generation_count"] = str(next_generation);
    result["idempotency_replayed"] = "false";
    result["http_status"] = "202";
    return result;
}

test "diamond revisit remains cycle safe" {
    graph = new_ledger();
    source = create_job("source", "owner", "FAILED", "digest");
    left = create_job("left", "owner", "FAILED", "left-digest");
    right = create_job("right", "owner", "FAILED", "right-digest");
    merge = create_job("merge", "owner", "FAILED", "merge-digest");
    attach_job(graph, source);
    link_lineage(source, right);
    link_lineage(source, left);
    link_lineage(right, merge);
    link_lineage(left, merge);
    link_lineage(merge, source);
    found = locate_job(graph, "merge");
    assert (found != None);
}

test "unknown source is owner safe" {
    graph = new_ledger();
    state = new_replay_ledger();
    payload: list[dict[str, str]] = [{"id": "record_alpha", "name": "accepted"}];
    result = replay_job(graph, state, "missing", "owner", "key-1", payload, "digest");
    assert (result["error"] == "etl_job_not_found");
    assert (result["http_status"] == "404");
}

test "failed job replays with immutable lineage" {
    graph = new_ledger();
    state = new_replay_ledger();
    source = create_job("record_alpha", "owner", "FAILED", "digest-alpha");
    attach_job(graph, source);
    payload: list[dict[str, str]] = [{"id": "record_alpha", "name": "accepted"}];
    result = replay_job(graph, state, "record_alpha", "owner", "new-key", payload, "digest-alpha");
    assert (result["http_status"] == "202");
    assert (result["status"] == "PENDING");
    assert (result["replay_source_job_record_id"] == "record_alpha");
    assert (result["replay_root_job_record_id"] == "record_alpha");
    assert (result["replay_generation_count"] == "1");
    assert (source.status == "FAILED");
    assert (source.replay_root_job_record_id == None);
}

test "identical replay is idempotent" {
    graph = new_ledger();
    state = new_replay_ledger();
    source = create_job("record_alpha", "owner", "CANCELLED", "digest-alpha");
    attach_job(graph, source);
    payload: list[dict[str, str]] = [{"id": "record_alpha", "name": "accepted"}];
    first = replay_job(graph, state, "record_alpha", "owner", "same-key", payload, "digest-alpha");
    second = replay_job(graph, state, "record_alpha", "owner", "same-key", payload, "digest-alpha");
    assert (first["job_record_id"] == second["job_record_id"]);
    assert (second["idempotency_replayed"] == "true");
}

test "active and succeeded jobs are rejected" {
    graph = new_ledger();
    state = new_replay_ledger();
    active = create_job("active", "owner", "RUNNING", "active-digest");
    succeeded = create_job("done", "owner", "SUCCEEDED", "done-digest");
    attach_job(graph, active);
    attach_job(graph, succeeded);
    payload: list[dict[str, str]] = [{"id": "record_alpha", "name": "accepted"}];
    active_result = replay_job(graph, state, "active", "owner", "key-a", payload, "active-digest");
    done_result = replay_job(graph, state, "done", "owner", "key-b", payload, "done-digest");
    assert (active_result["error"] == "etl_job_replay_source_active");
    assert (done_result["error"] == "etl_job_replay_source_succeeded");
}
