import from traceforge.ingest {
    batch_files,
    batch_ids_for_run,
    run_source_path
}
import from traceforge.schema { Batch, Cluster, Run, Step }
import from traceforge.features { summarize_counts }
import from traceforge.graph_build {
    ensure_batch_graph,
    failure_class_name,
    find_batch_node,
    find_cluster_node,
    find_run_node,
    hydrate_run_graph,
    list_batch_clusters,
    list_cluster_patches,
    list_batch_runs,
    list_run_clusters,
    list_run_hypotheses,
    list_run_steps,
    list_step_errors,
    list_step_files,
    list_step_patches,
    list_step_tests,
    remembered_cluster_patch_ids,
    run_graph_stats,
    run_batch_id_value,
    run_status_name,
    step_kind_name
}

def _run_exists_in_batch(batch_id: str, run_id: str) -> bool {
    for path in batch_files(batch_id) {
        if path.endswith("/" + run_id + ".traj.json") or path.endswith("\\" + run_id + ".traj.json") or path.endswith(run_id + ".traj.json") {
            return True;
        }
    }
    return False;
}

def _ensure_graph_for_run(root_node: any, run_id: str, batch_id: str = "") -> any {
    if batch_id {
        run_node = find_run_node(root_node, run_id, batch_id);
        if run_node is not None {
            return run_node;
        }
        if _run_exists_in_batch(batch_id, run_id) {
            ensure_batch_graph(root_node, batch_id);
            return find_run_node(root_node, run_id, batch_id);
        }
        return None;
    }

    matching_batch_ids = batch_ids_for_run(run_id);
    if len(matching_batch_ids) == 1 {
        chosen_batch_id = matching_batch_ids[0];
        if run_source_path(run_id, chosen_batch_id) {
            ensure_batch_graph(root_node, chosen_batch_id);
            return find_run_node(root_node, run_id, chosen_batch_id);
        }
    }
    return None;
}

def _timeline_from_run(run_node: Run) -> list[dict[str, any]] {
    timeline: list[dict[str, any]] = [];
    for step_node in list_run_steps(run_node) {
        timeline.append(
            {
                "idx": step_node.idx,
                "kind": step_kind_name(step_node.kind),
                "phase": step_node.phase,
                "excerpt": step_node.excerpt,
                "touched_files": [file_node.path for file_node in list_step_files(step_node)],
                "has_patch": len(list_step_patches(step_node)) > 0,
                "has_test": len(list_step_tests(step_node)) > 0,
                "has_error": len(list_step_errors(step_node)) > 0,
                "repeated": step_node.repeated,
            }
        );
    }
    return timeline;
}

def _critical_window(timeline: list[dict[str, any]], critical_step_idx: int, radius: int = 1) -> list[dict[str, any]] {
    if critical_step_idx < 0 {
        return [];
    }
    start = max(critical_step_idx - radius, 0);
    stop = min(critical_step_idx + radius, len(timeline) - 1);
    window: list[dict[str, any]] = [];
    for index = start while index<=stop with index+=1 {
        window.append(timeline[index]);
    }
    return window;
}

def _hypothesis_list(run_node: Run) -> list[dict[str, any]] {
    output: list[dict[str, any]] = [];
    for hypothesis in list_run_hypotheses(run_node) {
        output.append(
            {
                "label": failure_class_name(hypothesis.label),
                "score": hypothesis.score,
                "rationale": hypothesis.rationale,
            }
        );
    }
    return sorted(output, key=lambda (item: any) -> any { (-item["score"], item["label"]) });
}

def _run_summary_from_node(run_node: Run) -> dict[str, any] {
    hydrate_run_graph(run_node);
    timeline = _timeline_from_run(run_node);
    primary_failure = failure_class_name(run_node.primary_failure);
    return {
        "run_id": run_node.run_id,
        "batch_id": run_batch_id_value(run_node),
        "task_title": run_node.task_title,
        "source_path": run_node.raw_path,
        "exit_status": run_status_name(run_node.exit_status),
        "api_calls": run_node.api_calls,
        "cost": run_node.cost,
        "summary": run_node.summary,
        "primary_failure": primary_failure,
        "critical_step_idx": run_node.critical_step_idx,
        "critical_evidence_window": _critical_window(timeline, run_node.critical_step_idx),
        "timeline": timeline,
        "artifacts": {
            "turn_count": len(timeline),
            "metadata": run_node.metadata,
            "telemetry": {
                "api_calls": run_node.api_calls,
                "cost": run_node.cost,
                "trajectory_format": str(run_node.metadata.get("trajectory_format") or ""),
            },
            "fingerprint": run_node.fingerprint,
            "graph_preview": run_graph_stats(run_node),
            "failure_hypotheses": _hypothesis_list(run_node),
            "cluster_ids": [cluster_node.cluster_id for cluster_node in list_run_clusters(run_node)],
        },
        "status": "graph_backed",
    };
}

def _cluster_run_nodes(batch: Batch, cluster_id: str) -> list[Run] {
    return sorted(
        [run_node for run_node in list_batch_runs(batch) if run_node.cluster_id == cluster_id],
        key=lambda (item: any) -> any { item.run_id },
    );
}

def _cluster_summary_from_node(batch: Batch, cluster_node: Cluster) -> dict[str, any] {
    cluster_runs = _cluster_run_nodes(batch, cluster_node.cluster_id);
    stored_patches = list_cluster_patches(cluster_node);
    stored_patch_ids = remembered_cluster_patch_ids(cluster_node.cluster_id);
    if not stored_patch_ids {
        stored_patch_ids = [patch_node.patch_id for patch_node in stored_patches];
    }
    recurring_files_raw: list[str] = [];
    recurring_errors_raw: list[str] = [];
    recurring_tests_raw: list[str] = [];
    representative_runs: list[dict[str, any]] = [];
    medoid = {};
    for run_node in cluster_runs {
        recurring_files_raw.extend(run_node.fingerprint.get("top_files", []));
        recurring_errors_raw.extend(run_node.fingerprint.get("top_error_keywords", []));
        recurring_tests_raw.extend(run_node.fingerprint.get("top_test_names", []));
        run_card = {
            "run_id": run_node.run_id,
            "batch_id": run_batch_id_value(run_node, batch.batch_id),
            "task_title": run_node.task_title,
            "summary": run_node.summary,
            "critical_step_idx": run_node.critical_step_idx,
        };
        representative_runs.append(run_card);
        if run_node.run_id == cluster_node.medoid_run_id {
            medoid = run_card;
        }
    }

    recurring_signals: list[str] = [];
    failure_label = failure_class_name(cluster_node.failure_class);
    if failure_label != "UNKNOWN" {
        recurring_signals.append("Primary motif: " + failure_label.replace("_", " ").title());
    }
    recurring_files = summarize_counts(recurring_files_raw, 5);
    recurring_errors = summarize_counts(recurring_errors_raw, 5);
    recurring_tests = summarize_counts(recurring_tests_raw, 5);
    if recurring_files {
        recurring_signals.append("Recurring files: " + ", ".join([item[0] for item in recurring_files[:3]]));
    }
    if recurring_errors {
        recurring_signals.append("Recurring errors: " + ", ".join([item[0] for item in recurring_errors[:3]]));
    }
    if recurring_tests {
        recurring_signals.append("Recurring tests: " + ", ".join([item[0] for item in recurring_tests[:3]]));
    }

    return {
        "cluster_id": cluster_node.cluster_id,
        "batch_id": batch.batch_id,
        "label": cluster_node.label,
        "failure_class": failure_label,
        "size": cluster_node.size,
        "medoid_run_id": cluster_node.medoid_run_id,
        "medoid": medoid,
        "representative_runs": representative_runs,
        "recurring_signals": recurring_signals,
        "recurring_files": recurring_files,
        "recurring_errors": recurring_errors,
        "recurring_tests": recurring_tests,
        "summary": cluster_node.summary,
        "patch_ready": failure_label != "UNKNOWN",
        "stored_patch_count": len(stored_patch_ids),
        "stored_patch_ids": stored_patch_ids,
        "status": "cluster_ready",
    };
}

def batch_overview_summary(root_node: any, batch_id: str) -> dict[str, any] {
    compiled = ensure_batch_graph(root_node, batch_id);
    batch = compiled["batch"];
    if batch is None {
        return {
            "batch_id": batch_id,
            "family_counts": {},
            "clusters": [],
            "top_files": [],
            "top_errors": [],
            "top_tests": [],
            "status": "missing",
        };
    }

    family_counts: dict[str, int] = {};
    status_counts: dict[str, int] = {};
    top_files_raw: list[str] = [];
    top_errors_raw: list[str] = [];
    top_tests_raw: list[str] = [];
    run_summaries: list[dict[str, any]] = [];

    runs = list_batch_runs(batch);
    for run_node in runs {
        failure_label = failure_class_name(run_node.primary_failure);
        family_counts[failure_label] = family_counts.get(failure_label, 0) + 1;
        status_label = run_status_name(run_node.exit_status);
        status_counts[status_label] = status_counts.get(status_label, 0) + 1;
        top_files_raw.extend(run_node.fingerprint.get("top_files", []));
        top_errors_raw.extend(run_node.fingerprint.get("top_error_keywords", []));
        top_tests_raw.extend(run_node.fingerprint.get("top_test_names", []));
        run_summaries.append(
            {
                "run_id": run_node.run_id,
                "batch_id": run_batch_id_value(run_node, batch.batch_id),
                "task_title": run_node.task_title,
                "exit_status": status_label,
                "api_calls": run_node.api_calls,
                "cost": run_node.cost,
                "step_count": run_node.step_count,
                "primary_failure": failure_label,
                "cluster_id": run_node.cluster_id,
                "critical_step_idx": run_node.critical_step_idx,
                "summary": run_node.summary,
            }
        );
    }

    cluster_summaries = [];
    for cluster_node in list_batch_clusters(batch) {
        cluster_summary = _cluster_summary_from_node(batch, cluster_node);
        cluster_summaries.append(
            {
                "cluster_id": cluster_summary["cluster_id"],
                "label": cluster_summary["label"],
                "failure_class": cluster_summary["failure_class"],
                "size": cluster_summary["size"],
                "medoid_run_id": cluster_summary["medoid_run_id"],
                "summary": cluster_summary["summary"],
            }
        );
    }

    return {
        "batch_id": batch_id,
        "family_counts": family_counts,
        "status_counts": status_counts,
        "clusters": cluster_summaries,
        "top_files": summarize_counts(top_files_raw, 5),
        "top_errors": summarize_counts(top_errors_raw, 5),
        "top_tests": summarize_counts(top_tests_raw, 5),
        "run_count": batch.run_count,
        "run_ids": [run_node.run_id for run_node in runs],
        "runs": run_summaries,
        "cluster_count": len(cluster_summaries),
        "status": "graph_backed",
    };
}

def analyze_batch_summary(root_node: any, batch_id: str, force_rebuild: bool = False) -> dict[str, any] {
    compiled = ensure_batch_graph(root_node, batch_id, force_rebuild);
    batch = compiled["batch"];
    if batch is None {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }
    overview = batch_overview_summary(root_node, batch_id);
    return {
        "batch_id": batch_id,
        "status": (
            "graph_rebuilt"
            if compiled["status"] == "recompiled"
            else ("graph_compiled" if compiled["created"] else "graph_reused")
        ),
        "message": "Batch graph is ready for analysis and UI reads.",
        "run_count": overview["run_count"],
        "family_counts": overview["family_counts"],
        "status_counts": overview["status_counts"],
        "cluster_count": overview["cluster_count"],
    };
}

def cluster_view_summary(root_node: any, cluster_id: str) -> dict[str, any] {
    batch_id = cluster_id.split(":")[0];
    compiled = ensure_batch_graph(root_node, batch_id);
    batch = compiled["batch"];
    if batch is None {
        return {
            "cluster_id": cluster_id,
            "label": "Unlabeled cluster",
            "failure_class": "UNKNOWN",
            "size": 0,
            "medoid_run_id": "",
            "recurring_signals": [],
            "patch_ready": False,
            "status": "missing",
        };
    }
    cluster_node = find_cluster_node(batch, cluster_id);
    if cluster_node is None {
        return {
            "cluster_id": cluster_id,
            "label": "Unlabeled cluster",
            "failure_class": "UNKNOWN",
            "size": 0,
            "medoid_run_id": "",
            "recurring_signals": [],
            "patch_ready": False,
            "status": "missing",
        };
    }
    return _cluster_summary_from_node(batch, cluster_node);
}

def run_view_summary(root_node: any, run_id: str, batch_id: str = "") -> dict[str, any] {
    run_node = _ensure_graph_for_run(root_node, run_id, batch_id);
    if run_node is None {
        return {
            "run_id": run_id,
            "summary": "Run view stub",
            "critical_step_idx": -1,
            "timeline": [],
            "artifacts": [],
            "status": "stub",
        };
    }
    return _run_summary_from_node(run_node);
}
