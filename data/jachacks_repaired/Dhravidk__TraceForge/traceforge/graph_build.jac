import from datetime { datetime }
import from pathlib { Path }
import from traceforge.schema {
    Batch,
    Cluster,
    ErrorEvent,
    FailureClass,
    FailureHypothesis,
    FileArtifact,
    HasBatch,
    HasRun,
    HasStep,
    InCluster,
    NextStep,
    Patch,
    PatchesFile,
    ProducesPatch,
    RaisesError,
    MemoryPatch,
    Run,
    RunStatus,
    RunsTest,
    Severity,
    SimilarRun,
    Step,
    StepKind,
    SuggestsPatch,
    SupportsHypothesis,
    TestEvent,
    TouchesFile
}
import from traceforge.ingest { batch_files, batch_summary }
import from traceforge.parser {
    ParsedRun,
    extract_file_tokens,
    hash_text,
    parse_run,
    truncate_text
}
import from traceforge.features {
    build_run_digest,
    compute_run_fingerprint,
    dominant_failure_label,
    fingerprint_to_dict
}
import from traceforge.clustering { build_clusters, failure_class_label }
import from traceforge.critical { localize_critical_step }

glob GENERATED_PATCH_REGISTRY: dict[str, list[str]] = {};

def current_timestamp() -> str {
    return datetime.utcnow().isoformat();
}

def remembered_cluster_patch_ids(cluster_id: str) -> list[str] {
    return GENERATED_PATCH_REGISTRY.get(cluster_id, []);
}

def failure_class_to_enum(label: str) -> FailureClass {
    match label {
        case "PREMATURE_COMPLETION": return FailureClass.PREMATURE_COMPLETION;
        case "INVALID_PATCH": return FailureClass.INVALID_PATCH;
        case "WRONG_FILE_FOCUS": return FailureClass.WRONG_FILE_FOCUS;
        case "OSCILLATION_LOOP": return FailureClass.OSCILLATION_LOOP;
        case "TOOL_MISUSE": return FailureClass.TOOL_MISUSE;
        case "STALE_CONTEXT_OR_BAD_PLAN": return FailureClass.STALE_CONTEXT_OR_BAD_PLAN;
        case "REQUIREMENT_DRIFT": return FailureClass.REQUIREMENT_DRIFT;
        case _: return FailureClass.UNKNOWN;
    }
}

def failure_class_name(value: FailureClass) -> str {
    match value {
        case FailureClass.PREMATURE_COMPLETION: return "PREMATURE_COMPLETION";
        case FailureClass.INVALID_PATCH: return "INVALID_PATCH";
        case FailureClass.WRONG_FILE_FOCUS: return "WRONG_FILE_FOCUS";
        case FailureClass.OSCILLATION_LOOP: return "OSCILLATION_LOOP";
        case FailureClass.TOOL_MISUSE: return "TOOL_MISUSE";
        case FailureClass.STALE_CONTEXT_OR_BAD_PLAN: return "STALE_CONTEXT_OR_BAD_PLAN";
        case FailureClass.REQUIREMENT_DRIFT: return "REQUIREMENT_DRIFT";
        case _: return "UNKNOWN";
    }
}

def step_kind_to_enum(label: str) -> StepKind {
    match label {
        case "SYSTEM": return StepKind.SYSTEM;
        case "USER": return StepKind.USER;
        case "ASSISTANT": return StepKind.ASSISTANT;
        case "TOOL": return StepKind.TOOL;
        case "COMMAND": return StepKind.COMMAND;
        case "EDIT": return StepKind.EDIT;
        case "TEST": return StepKind.TEST;
        case "SUBMIT": return StepKind.SUBMIT;
        case "ERROR": return StepKind.ERROR;
        case _: return StepKind.OTHER;
    }
}

def step_kind_name(value: StepKind) -> str {
    match value {
        case StepKind.SYSTEM: return "SYSTEM";
        case StepKind.USER: return "USER";
        case StepKind.ASSISTANT: return "ASSISTANT";
        case StepKind.TOOL: return "TOOL";
        case StepKind.COMMAND: return "COMMAND";
        case StepKind.EDIT: return "EDIT";
        case StepKind.TEST: return "TEST";
        case StepKind.SUBMIT: return "SUBMIT";
        case StepKind.ERROR: return "ERROR";
        case _: return "OTHER";
    }
}

def run_status_from_text(status_text: str) -> RunStatus {
    lower = status_text.lower();
    if lower in {"resolved", "passed", "success", "succeeded"} {
        return RunStatus.RESOLVED;
    }
    if lower in {"submitted"} {
        return RunStatus.SUBMITTED;
    }
    if lower in {"interrupted"} {
        return RunStatus.INTERRUPTED;
    }
    if "limit" in lower {
        return RunStatus.LIMITS_EXCEEDED;
    }
    if lower in {"failed", "error", "error_exit"} {
        return RunStatus.ERROR_EXIT;
    }
    if "error" in lower or "exception" in lower or "retry" in lower or "traceback" in lower or "process" in lower {
        return RunStatus.ERROR_EXIT;
    }
    return RunStatus.UNKNOWN;
}

def _int_metadata_value(metadata: dict[str, any], key: str, fallback: int = 0) -> int {
    value = metadata.get(key);
    if value is None {
        return fallback;
    }
    if isinstance(value, int) {
        return value;
    }
    try {
        return int(float(str(value)));
    } except Exception {
        return fallback;
    }
}

def _float_metadata_value(metadata: dict[str, any], key: str, fallback: float = 0.0) -> float {
    value = metadata.get(key);
    if value is None {
        return fallback;
    }
    if isinstance(value, float) {
        return value;
    }
    if isinstance(value, int) {
        return float(value);
    }
    try {
        return float(str(value));
    } except Exception {
        return fallback;
    }
}

def run_status_name(value: RunStatus) -> str {
    match value {
        case RunStatus.RESOLVED: return "resolved";
        case RunStatus.SUBMITTED: return "submitted";
        case RunStatus.INTERRUPTED: return "interrupted";
        case RunStatus.LIMITS_EXCEEDED: return "limits_exceeded";
        case RunStatus.ERROR_EXIT: return "error_exit";
        case _: return "unknown";
    }
}

def error_type_from_text(text: str) -> str {
    lower = text.lower();
    if "syntaxerror" in lower or "invalid syntax" in lower {
        return "SyntaxError";
    }
    if "importerror" in lower or "module not found" in lower {
        return "ImportError";
    }
    if "traceback" in lower {
        return "Traceback";
    }
    if "failed" in lower {
        return "TestFailure";
    }
    return "ErrorSignal";
}

def test_status_from_text(text: str) -> str {
    lower = text.lower();
    if " passed" in lower or lower.startswith("passed") or "1 passed" in lower {
        return "passed";
    }
    if "failed" in lower or "error" in lower or "traceback" in lower {
        return "failed";
    }
    return "unknown";
}

def patch_stats(text: str) -> dict[str, any] {
    adds = 0;
    dels = 0;
    for line in text.split("\n") {
        if line.startswith("+++") or line.startswith("---") {
            continue;
        }
        if line.startswith("+") {
            adds += 1;
        } elif line.startswith("-") {
            dels += 1;
        }
    }
    return {"adds": adds, "dels": dels};
}

def list_batch_runs(batch: Batch) -> list[Run] {
    return sorted(
        [batch ->:HasRun:->][?:Run],
        key=lambda (item: any) -> any { item.run_id },
    );
}

def list_run_steps(run_node: Run) -> list[Step] {
    return sorted(
        [run_node ->:HasStep:->][?:Step],
        key=lambda (item: any) -> any { item.idx },
    );
}

def list_step_files(step_node: Step) -> list[FileArtifact] {
    return sorted(
        [step_node ->:TouchesFile:->][?:FileArtifact],
        key=lambda (item: any) -> any { item.path },
    );
}

def list_step_patches(step_node: Step) -> list[Patch] {
    return [step_node ->:ProducesPatch:->][?:Patch];
}

def list_step_tests(step_node: Step) -> list[TestEvent] {
    return [step_node ->:RunsTest:->][?:TestEvent];
}

def list_step_errors(step_node: Step) -> list[ErrorEvent] {
    return [step_node ->:RaisesError:->][?:ErrorEvent];
}

def list_run_hypotheses(run_node: Run) -> list[FailureHypothesis] {
    return [run_node ->:SupportsHypothesis:->][?:FailureHypothesis];
}

def list_run_clusters(run_node: Run) -> list[Cluster] {
    return [run_node ->:InCluster:->][?:Cluster];
}

def list_batch_clusters(batch: Batch) -> list[Cluster] {
    clusters: list[Cluster] = [];
    seen: set[str] = set();
    for run_node in list_batch_runs(batch) {
        for cluster_node in list_run_clusters(run_node) {
            if cluster_node.cluster_id in seen {
                continue;
            }
            seen.add(cluster_node.cluster_id);
            clusters.append(cluster_node);
        }
    }
    return sorted(clusters, key=lambda (item: any) -> any { item.cluster_id });
}

def list_cluster_patches(cluster_node: Cluster) -> list[MemoryPatch] {
    return sorted(
        [cluster_node ->:SuggestsPatch:->][?:MemoryPatch],
        key=lambda (item: any) -> any { item.patch_id },
    );
}

def run_batch_id_value(run_node: Run, fallback: str = "") -> str {
    metadata_batch_id = str(run_node.metadata.get("batch_id") or "");
    if metadata_batch_id {
        return metadata_batch_id;
    }
    if hasattr(run_node, "batch_id") and str(run_node.batch_id or "") {
        return str(run_node.batch_id);
    }
    return fallback;
}

def find_batch_node(root_node: any, target_batch_id: str) -> any {
    batches = [root_node ->:HasBatch:->][?:Batch, batch_id == target_batch_id];
    if batches {
        return batches[0];
    }
    return None;
}

def find_run_node(root_node: any, target_run_id: str, target_batch_id: str = "") -> any {
    if target_batch_id {
        batch = find_batch_node(root_node, target_batch_id);
        if batch is None {
            return None;
        }
        runs = [batch ->:HasRun:->][?:Run, run_id == target_run_id];
        if runs {
            return runs[0];
        }
        return None;
    }

    matches: list[Run] = [];
    for batch in [root_node ->:HasBatch:->][?:Batch] {
        runs = [batch ->:HasRun:->][?:Run, run_id == target_run_id];
        if runs {
            matches.extend(runs);
        }
    }
    if len(matches) == 1 {
        return matches[0];
    }
    return None;
}

def find_batch_for_run(root_node: any, target_run_id: str, target_batch_id: str = "") -> any {
    if target_batch_id {
        batch = find_batch_node(root_node, target_batch_id);
        if batch is None {
            return None;
        }
        runs = [batch ->:HasRun:->][?:Run, run_id == target_run_id];
        if runs {
            return batch;
        }
        return None;
    }
    matches: list[Batch] = [];
    for batch in [root_node ->:HasBatch:->][?:Batch] {
        runs = [batch ->:HasRun:->][?:Run, run_id == target_run_id];
        if runs {
            matches.append(batch);
        }
    }
    if len(matches) == 1 {
        return matches[0];
    }
    return None;
}

def find_cluster_node(batch: Batch, target_cluster_id: str) -> any {
    for cluster_node in list_batch_clusters(batch) {
        if cluster_node.cluster_id == target_cluster_id {
            return cluster_node;
        }
    }
    return None;
}

def upsert_cluster_patch(cluster_node: Cluster, patch_data: dict[str, any]) -> dict[str, any] {
    stable_patch_id = str(patch_data.get("patch_id") or (cluster_node.cluster_id + ":memory_patch"));
    existing: MemoryPatch | None = None;
    for patch_node in list_cluster_patches(cluster_node) {
        if patch_node.patch_id == stable_patch_id {
            existing = patch_node;
            break;
        }
    }

    if existing is None {
        cluster_node +>: SuggestsPatch(weight=float(patch_data.get("confidence") or 0.0)) :+> (
            patch_node := MemoryPatch(
                patch_id=stable_patch_id,
                scope=str(patch_data.get("scope") or "cluster"),
                title=str(patch_data.get("title") or cluster_node.label),
                diff_text=str(patch_data.get("diff_text") or ""),
                confidence=float(patch_data.get("confidence") or 0.0),
            )
        );
        if cluster_node.cluster_id not in GENERATED_PATCH_REGISTRY {
            GENERATED_PATCH_REGISTRY[cluster_node.cluster_id] = [];
        }
        if stable_patch_id not in GENERATED_PATCH_REGISTRY[cluster_node.cluster_id] {
            GENERATED_PATCH_REGISTRY[cluster_node.cluster_id].append(stable_patch_id);
        }
        commit();
        return {
            "patch_id": patch_node.patch_id,
            "created": True,
        };
    }

    existing.scope = str(patch_data.get("scope") or existing.scope);
    existing.title = str(patch_data.get("title") or existing.title);
    existing.diff_text = str(patch_data.get("diff_text") or existing.diff_text);
    existing.confidence = float(patch_data.get("confidence") or existing.confidence);
    if cluster_node.cluster_id not in GENERATED_PATCH_REGISTRY {
        GENERATED_PATCH_REGISTRY[cluster_node.cluster_id] = [];
    }
    if stable_patch_id not in GENERATED_PATCH_REGISTRY[cluster_node.cluster_id] {
        GENERATED_PATCH_REGISTRY[cluster_node.cluster_id].append(stable_patch_id);
    }
    commit();
    return {
        "patch_id": existing.patch_id,
        "created": False,
    };
}

def _file_node(path: str, file_nodes: dict[str, any]) -> FileArtifact {
    if path in file_nodes {
        return file_nodes[path];
    }
    file_node = FileArtifact(
        path=path,
        basename=Path(path).name,
        ext=Path(path).suffix,
    );
    file_nodes[path] = file_node;
    return file_node;
}

def _attach_failure_hypotheses(run_node: Run, fingerprint: dict[str, any]) -> None {
    scores = fingerprint["failure_class_scores"];
    run_batch_id = run_batch_id_value(run_node);
    for label in scores {
        score = float(scores[label]);
        if score <= 0.0 {
            continue;
        }
        run_node +>: SupportsHypothesis(weight=score) :+> FailureHypothesis(
            hyp_id=f"{run_batch_id}:{run_node.run_id}:{label}",
            label=failure_class_to_enum(str(label)),
            score=score,
            rationale=f"Deterministic score for {label}",
        );
    }
}

def _run_detail_hydrated(run_node: Run) -> bool {
    return bool(run_node.metadata.get("traceforge_detail_hydrated"));
}

def _attach_step_artifacts(step_node: Step, file_nodes: dict[str, any], parsed_step: any, run_id: str, batch_id: str) -> None {
    linked_files: list[FileArtifact] = [];
    for file_path in parsed_step.touched_files {
        file_node = _file_node(file_path, file_nodes);
        step_node +>: TouchesFile() :+> file_node;
        linked_files.append(file_node);
    }

    if parsed_step.patch_text {
        stats = patch_stats(parsed_step.patch_text);
        patch_file_path = parsed_step.touched_files[0] if parsed_step.touched_files else "";
        patch_node = Patch(
            patch_id=f"{batch_id}:{run_id}:patch:{parsed_step.index}",
            file_path=patch_file_path,
            adds=stats["adds"],
            dels=stats["dels"],
            parse_ok=not ("syntaxerror" in parsed_step.patch_text.lower() or "invalid syntax" in parsed_step.patch_text.lower()),
            patch_hash=hash_text(parsed_step.patch_text),
        );
        step_node +>: ProducesPatch() :+> patch_node;
        if linked_files {
            patch_node +>: PatchesFile() :+> linked_files[0];
        }
    }

    if parsed_step.test_text {
        failing_tests = [];
        for token in extract_file_tokens(parsed_step.test_text) {
            if "::" in token or token.startswith("tests/") {
                failing_tests.append(token);
            }
        }
        step_node +>: RunsTest() :+> TestEvent(
            test_id=f"{batch_id}:{run_id}:test:{parsed_step.index}",
            command=truncate_text(parsed_step.test_text, 240),
            status=test_status_from_text(parsed_step.test_text),
            failing_tests=failing_tests,
            excerpt=truncate_text(parsed_step.test_text, 240),
        );
    }

    if parsed_step.error_text {
        step_node +>: RaisesError() :+> ErrorEvent(
            error_id=f"{batch_id}:{run_id}:error:{parsed_step.index}",
            error_type=error_type_from_text(parsed_step.error_text),
            message=truncate_text(parsed_step.error_text, 240),
            severity=Severity.ERROR,
        );
    }
}

def _attach_run_steps(run_node: Run, parsed_run: ParsedRun, file_nodes: dict[str, any]) -> None {
    seen_hashes: set[str] = set();
    previous_step_node: Step | None = None;
    run_batch_id = run_batch_id_value(run_node);
    for parsed_step in parsed_run.steps {
        is_repeated = parsed_step.content_hash in seen_hashes;
        seen_hashes.add(parsed_step.content_hash);
        run_node +>: HasStep(order=parsed_step.index) :+> (step_node := Step(
            step_id=f"{run_batch_id}:{parsed_run.run_id}:step:{parsed_step.index}",
            idx=parsed_step.index,
            kind=step_kind_to_enum(parsed_step.kind),
            role=parsed_step.role,
            phase=parsed_step.phase,
            excerpt=parsed_step.excerpt,
            raw_offset=parsed_step.index,
            content_hash=parsed_step.content_hash,
            repeated=is_repeated,
        ));
        if previous_step_node is not None {
            previous_step_node +>: NextStep() :+> step_node;
        }
        previous_step_node = step_node;
        _attach_step_artifacts(step_node, file_nodes, parsed_step, parsed_run.run_id, run_batch_id);
    }
}

def hydrate_run_graph(run_node: Run) -> bool {
    if _run_detail_hydrated(run_node) {
        return False;
    }
    existing_steps = list_run_steps(run_node);
    if existing_steps {
        metadata = dict(run_node.metadata);
        metadata["traceforge_detail_hydrated"] = True;
        run_node.metadata = metadata;
        commit();
        return False;
    }
    parsed_run = parse_run(run_node.raw_path, run_node.run_id);
    _attach_run_steps(run_node, parsed_run, {});
    metadata = dict(run_node.metadata);
    metadata["traceforge_detail_hydrated"] = True;
    run_node.metadata = metadata;
    commit();
    return True;
}

def _create_run_node(batch: Batch, parsed_run: ParsedRun, order: int) -> dict[str, any] {
    fingerprint = fingerprint_to_dict(compute_run_fingerprint(parsed_run));
    primary_failure = dominant_failure_label(fingerprint);
    critical = localize_critical_step(parsed_run, fingerprint);
    summary = build_run_digest(parsed_run, fingerprint);
    metadata = dict(parsed_run.metadata);
    metadata["traceforge_detail_hydrated"] = False;
    metadata["batch_id"] = batch.batch_id;

    batch +>: HasRun(order=order) :+> (run_node := Run(
        run_id=parsed_run.run_id,
        batch_id=batch.batch_id,
        instance_id=parsed_run.instance_id,
        task_title=parsed_run.task_title,
        raw_path=parsed_run.source_path,
        metadata=metadata,
        exit_status=run_status_from_text(str(parsed_run.metadata.get("exit_status") or parsed_run.metadata.get("status") or "")),
        api_calls=_int_metadata_value(parsed_run.metadata, "api_calls", 0),
        cost=_float_metadata_value(parsed_run.metadata, "instance_cost", 0.0),
        step_count=len(parsed_run.steps),
        unique_files=int(fingerprint["num_unique_files"]),
        fingerprint=fingerprint,
        primary_failure=failure_class_to_enum(primary_failure),
        critical_step_idx=int(critical["critical_step_idx"]),
        summary=summary,
    ));

    _attach_failure_hypotheses(run_node, fingerprint);
    return {
        "run_node": run_node,
        "run_id": parsed_run.run_id,
        "task_title": parsed_run.task_title,
        "fingerprint": fingerprint,
        "primary_failure": primary_failure,
        "summary": summary,
        "critical": critical,
    };
}

def _batch_graph_is_current(batch: Batch) -> bool {
    for run_node in list_batch_runs(batch) {
        if run_batch_id_value(run_node) != batch.batch_id {
            return False;
        }
    }
    return True;
}

def _attach_clusters(batch: Batch, run_records: list[dict[str, any]], batch_id: str) -> None {
    clusters = build_clusters(run_records, batch_id);
    run_node_map: dict[str, Run] = {};
    record_map: dict[str, dict[str, any]] = {};
    assigned_run_ids: set[str] = set();
    for record in run_records {
        run_node_map[record["run_id"]] = record["run_node"];
        record_map[record["run_id"]] = record;
    }

    for cluster in clusters {
        cluster_node = Cluster(
            cluster_id=cluster["cluster_id"],
            label=cluster["label"],
            failure_class=failure_class_to_enum(str(cluster["failure_class"])),
            size=int(cluster["size"]),
            medoid_run_id=str(cluster["medoid_run_id"]),
            summary=str(cluster["summary"]),
        );
        run_ids = cluster["run_ids"];
        for run_id in run_ids {
            run_node = run_node_map[run_id];
            run_node.cluster_id = cluster["cluster_id"];
            run_node +>: InCluster() :+> cluster_node;
            assigned_run_ids.add(run_id);
        }

        for pair in cluster["similar_pairs"] {
            left_id = str(pair["left_run_id"]);
            right_id = str(pair["right_run_id"]);
            score = float(pair["score"]);
            if score <= 0.0 {
                continue;
            }
            run_node_map[left_id] +>: SimilarRun(score=score) :+> run_node_map[right_id];
            run_node_map[right_id] +>: SimilarRun(score=score) :+> run_node_map[left_id];
        }
    }

    unassigned_by_family: dict[str, list[dict[str, any]]] = {};
    for record in run_records {
        run_id = str(record["run_id"]);
        if run_id in assigned_run_ids {
            continue;
        }
        family = str(record["primary_failure"] or "UNKNOWN");
        if family not in unassigned_by_family {
            unassigned_by_family[family] = [];
        }
        unassigned_by_family[family].append(record);
    }

    for family in unassigned_by_family {
        family_records = unassigned_by_family[family];
        fallback_cluster_id = f"{batch_id}:{family.lower()}:fallback";
        fallback_cluster = Cluster(
            cluster_id=fallback_cluster_id,
            label=failure_class_label(family) + " fallback",
            failure_class=failure_class_to_enum(family),
            size=len(family_records),
            medoid_run_id=str(family_records[0]["run_id"]),
            summary=f"{failure_class_label(family)} fallback cluster with {len(family_records)} run(s).",
        );
        for record in family_records {
            run_node = record["run_node"];
            run_node.cluster_id = fallback_cluster_id;
            run_node +>: InCluster() :+> fallback_cluster;
        }
    }
}

def invalidate_batch_graph(root_node: any, target_batch_id: str) -> dict[str, any] {
    existing = find_batch_node(root_node, target_batch_id);
    if existing is None {
        return {
            "batch_id": target_batch_id,
            "deleted": False,
            "status": "missing",
        };
    }

    cluster_nodes = list_batch_clusters(existing);
    run_nodes = list_batch_runs(existing);
    for cluster_node in cluster_nodes {
        if cluster_node.cluster_id in GENERATED_PATCH_REGISTRY {
            GENERATED_PATCH_REGISTRY[cluster_node.cluster_id] = [];
        }
        for patch_node in list_cluster_patches(cluster_node) {
            del patch_node;
        }
    }
    for run_node in run_nodes {
        for hypothesis in list_run_hypotheses(run_node) {
            del hypothesis;
        }
        for step_node in list_run_steps(run_node) {
            for patch_node in list_step_patches(step_node) {
                del patch_node;
            }
            for test_node in list_step_tests(step_node) {
                del test_node;
            }
            for error_node in list_step_errors(step_node) {
                del error_node;
            }
            del step_node;
        }
        del run_node;
    }
    for cluster_node in cluster_nodes {
        del cluster_node;
    }
    root_node del--> existing;
    del existing;
    commit();
    return {
        "batch_id": target_batch_id,
        "deleted": True,
        "status": "invalidated",
    };
}

def ensure_batch_graph(root_node: Root, target_batch_id: str, force_rebuild: bool = False) -> dict[str, any] {
    existing = find_batch_node(root_node, target_batch_id);
    if existing is not None and not force_rebuild {
        if not _batch_graph_is_current(existing) {
            invalidate_batch_graph(root_node, target_batch_id);
        } else {
            return {
                "batch": existing,
                "created": False,
                "status": "existing_graph",
            };
        }
    }
    existing = find_batch_node(root_node, target_batch_id);
    if existing is not None and force_rebuild {
        invalidate_batch_graph(root_node, target_batch_id);
    }
    existing = find_batch_node(root_node, target_batch_id);
    if existing is not None {
        return {
            "batch": existing,
            "created": False,
            "status": "existing_graph",
        };
    }

    batch_meta = batch_summary(target_batch_id);
    if batch_meta["status"] != "ready" {
        return {
            "batch": None,
            "created": False,
            "status": "missing",
        };
    }

    root_node +>: HasBatch() :+> (batch := Batch(
        batch_id=target_batch_id,
        name=str(batch_meta["name"]),
        source_format=str(batch_meta["source_format"]),
        created_at=current_timestamp(),
        run_count=int(batch_meta["run_count"]),
    ));

    run_records: list[dict[str, any]] = [];
    for (order, path) in enumerate(batch_files(target_batch_id)) {
        parsed_run = parse_run(path);
        run_records.append(_create_run_node(batch, parsed_run, order));
    }
    _attach_clusters(batch, run_records, target_batch_id);
    commit();
    return {
        "batch": batch,
        "created": True,
        "status": "recompiled" if force_rebuild else "compiled",
    };
}

def run_graph_stats(run_node: Run) -> dict[str, any] {
    steps = list_run_steps(run_node);
    file_count = 0;
    patch_count = 0;
    test_count = 0;
    error_count = 0;
    artifact_edges = 0;
    for step_node in steps {
        step_files = list_step_files(step_node);
        step_patches = list_step_patches(step_node);
        step_tests = list_step_tests(step_node);
        step_errors = list_step_errors(step_node);
        file_count += len(step_files);
        patch_count += len(step_patches);
        test_count += len(step_tests);
        error_count += len(step_errors);
        artifact_edges += len(step_files) + len(step_patches) + len(step_tests) + len(step_errors);
    }
    return {
        "status": "graph_compiled",
        "node_counts": {
            "Run": 1,
            "Step": len(steps),
            "FileArtifact": file_count,
            "Patch": patch_count,
            "TestEvent": test_count,
            "ErrorEvent": error_count,
            "FailureHypothesis": len(list_run_hypotheses(run_node)),
        },
        "edge_counts": {
            "HasStep": len(steps),
            "NextStep": max(len(steps) - 1, 0),
            "ArtifactLinks": artifact_edges,
            "SupportsHypothesis": len(list_run_hypotheses(run_node)),
        },
    };
}
