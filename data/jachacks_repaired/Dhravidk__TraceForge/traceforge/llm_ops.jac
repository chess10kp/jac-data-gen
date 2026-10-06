import from os { getenv }
import from traceforge.analysis { cluster_view_summary, run_view_summary }
import from traceforge.graph_build {
    ensure_batch_graph,
    failure_class_name,
    find_cluster_node,
    upsert_cluster_patch
}
import from traceforge.parser { truncate_text }
import from traceforge.provider_config { configured_provider_key }
import from traceforge.schema { ClusterLabel, ComparisonVerdict, FailureClass, MemoryPatchProposal, RunDiagnosis }

def choose_failure_class(text: str) -> FailureClass by llm();

def draft_cluster_label(text: str) -> ClusterLabel by llm();

def draft_memory_patch(text: str) -> MemoryPatchProposal by llm();

def propose_run_diagnosis(text: str) -> RunDiagnosis by llm();

def compare_run_diagnoses(text: str) -> ComparisonVerdict by llm();

def llm_enabled() -> bool {
    return str(configured_provider_key("openai") or getenv("OPENAI_API_KEY") or "") != "";
}

def diagnosis_reason(failure_class: str) -> str {
    reasons = {
        "PREMATURE_COMPLETION": "the run moved to submission before validating that the failing state had recovered",
        "INVALID_PATCH": "the patch introduced or preserved a syntax-level failure that the run never repaired",
        "WRONG_FILE_FOCUS": "the run spent effort on files that did not reduce the target failure",
        "OSCILLATION_LOOP": "the run repeated the same search or file-touch pattern without creating recovery evidence",
        "TOOL_MISUSE": "tool interactions kept returning failure signals and the run never corrected the workflow",
        "STALE_CONTEXT_OR_BAD_PLAN": "the run stayed in planning or inspection too long without decisive repo interaction",
        "REQUIREMENT_DRIFT": "the run drifted away from the issue target and never came back to a validating path",
        "UNKNOWN": "the failure pattern is not yet classified strongly enough for a tighter explanation",
    };
    return reasons.get(failure_class, reasons["UNKNOWN"]);
}

def cluster_rule_lines(failure_class: str) -> list[str] {
    if failure_class == "PREMATURE_COMPLETION" {
        return [
            "Before submitting, rerun at least one targeted failing test if any test failed earlier.",
            "Do not submit if the latest visible state lacks post-patch validation.",
        ];
    }
    if failure_class == "INVALID_PATCH" {
        return [
            "After applying a patch, run the targeted test before submitting.",
            "Do not submit when the latest output still shows syntax, import, or traceback failures.",
        ];
    }
    if failure_class == "OSCILLATION_LOOP" {
        return [
            "After two repeated search or same-file inspection cycles with no new evidence, change strategy.",
            "If the same file has been touched repeatedly without recovery, re-rank candidate files from failing tests and errors.",
        ];
    }
    if failure_class == "WRONG_FILE_FOCUS" {
        return [
            "Prioritize files named in failing tests, stack traces, or direct issue context before editing secondary files.",
            "If edits do not reduce the original failure signal, stop and re-rank the target files.",
        ];
    }
    if failure_class == "TOOL_MISUSE" {
        return [
            "Treat repeated non-zero tool outcomes as a strategy failure and adjust before continuing.",
            "Do not keep issuing malformed or irrelevant commands after the same failure repeats.",
        ];
    }
    if failure_class == "STALE_CONTEXT_OR_BAD_PLAN" {
        return [
            "Limit consecutive planning or search-only turns without touching the repo or validating a hypothesis.",
            "After prolonged inspection, commit to one concrete file-level hypothesis and test it.",
        ];
    }
    if failure_class == "REQUIREMENT_DRIFT" {
        return [
            "Keep edits anchored to the failing test, stack trace, or issue target.",
            "If later steps stop mentioning the original failure context, pause and re-establish the target before editing again.",
        ];
    }
    return [
        "Prefer targeted validation before submission.",
        "Escalate to a new strategy when repeated steps stop producing new evidence.",
    ];
}

def _join_tokens(items: list[any], limit: int = 3) -> str {
    chosen: list[str] = [];
    for item in items {
        if len(chosen) >= limit {
            break;
        }
        chosen.append(str(item));
    }
    return ", ".join(chosen);
}

def _critical_quote(run_view: dict[str, any]) -> str {
    for step in run_view["critical_evidence_window"] {
        if int(step["idx"]) == int(run_view["critical_step_idx"]) {
            return str(step["excerpt"]);
        }
    }
    if len(run_view["critical_evidence_window"]) > 0 {
        return str(run_view["critical_evidence_window"][0]["excerpt"]);
    }
    return str(run_view["summary"]);
}

def _cluster_support_records(root_node: any, cluster_view: dict[str, any]) -> list[dict[str, any]] {
    batch_id = str(cluster_view.get("batch_id") or str(cluster_view["cluster_id"]).split(":")[0]);
    support_records: list[dict[str, any]] = [];
    for run_item in cluster_view["representative_runs"] {
        if len(support_records) >= 3 {
            break;
        }
        run_view = run_view_summary(root_node, str(run_item["run_id"]), batch_id);
        if run_view["status"] == "stub" {
            continue;
        }
        support_records.append(
            {
                "run_id": run_view["run_id"],
                "batch_id": run_view["batch_id"],
                "critical_step_idx": run_view["critical_step_idx"],
                "quote": _critical_quote(run_view),
                "top_files": run_view["artifacts"]["fingerprint"].get("top_files", []),
                "top_tests": run_view["artifacts"]["fingerprint"].get("top_test_names", []),
                "top_errors": run_view["artifacts"]["fingerprint"].get("top_error_keywords", []),
            }
        );
    }
    return support_records;
}

def _supported_steps(records: list[dict[str, any]]) -> list[int] {
    steps: list[int] = [];
    for record in records {
        step_idx = int(record["critical_step_idx"]);
        if step_idx >= 0 and step_idx not in steps {
            steps.append(step_idx);
        }
    }
    return steps;
}

def _evidence_lines(cluster_view: dict[str, any], support_records: list[dict[str, any]]) -> list[str] {
    lines: list[str] = [];
    for record in support_records {
        lines.append(
            str(record["run_id"])
            + "@"
            + str(record["critical_step_idx"])
            + ": "
            + str(record["quote"])
        );
    }
    if cluster_view["recurring_tests"] {
        lines.append(
            "Recurring tests: "
            + _join_tokens([item[0] for item in cluster_view["recurring_tests"]], 3)
        );
    }
    if cluster_view["recurring_errors"] {
        lines.append(
            "Recurring errors: "
            + _join_tokens([item[0] for item in cluster_view["recurring_errors"]], 3)
        );
    }
    if cluster_view["recurring_files"] {
        lines.append(
            "Recurring files: "
            + _join_tokens([item[0] for item in cluster_view["recurring_files"]], 3)
        );
    }
    return lines;
}

def _evidence_grounded_rule_records(cluster_view: dict[str, any], support_records: list[dict[str, any]]) -> list[dict[str, any]] {
    failure_class = str(cluster_view["failure_class"]);
    base_rules = cluster_rule_lines(failure_class);
    recurring_tests = [item[0] for item in cluster_view["recurring_tests"]];
    recurring_errors = [item[0] for item in cluster_view["recurring_errors"]];
    recurring_files = [item[0] for item in cluster_view["recurring_files"]];
    step_refs = _supported_steps(support_records);
    evidence_anchor = _join_tokens(
        [
            str(record["run_id"]) + "@" + str(record["critical_step_idx"])
            for record in support_records
        ],
        3,
    );
    evidence_quote = _join_tokens([str(record["quote"]) for record in support_records], 2);
    records: list[dict[str, any]] = [];

    for (index, rule_text) in enumerate(base_rules) {
        refined_rule = rule_text;
        if failure_class == "PREMATURE_COMPLETION" and recurring_tests {
            refined_rule = "Before submitting after failures in " + _join_tokens(recurring_tests, 2) + ", rerun at least one targeted failing test.";
        } elif failure_class == "INVALID_PATCH" and recurring_errors {
            refined_rule = "Do not keep a patch live when errors like " + _join_tokens(recurring_errors, 2) + " still appear after the edit.";
        } elif failure_class == "WRONG_FILE_FOCUS" and recurring_files {
            refined_rule = "Prioritize files like " + _join_tokens(recurring_files, 2) + " before editing secondary files.";
        } elif failure_class == "OSCILLATION_LOOP" and recurring_files {
            refined_rule = "If the run revisits " + _join_tokens(recurring_files, 2) + " without reducing failures, stop and re-rank targets.";
        } elif failure_class == "TOOL_MISUSE" and recurring_errors {
            refined_rule = "Treat repeated tool failures such as " + _join_tokens(recurring_errors, 2) + " as a strategy reset signal, not a reason to repeat the same command.";
        }

        records.append(
            {
                "title": str(cluster_view["label"]) + " rule " + str(index + 1),
                "rationale": "Supported by " + evidence_anchor + ". Evidence: " + evidence_quote,
                "rule_text": refined_rule,
                "supported_by_steps": step_refs,
                "confidence": 0.66 if len(step_refs) >= 2 else 0.6,
            }
        );
    }
    return records;
}

def _run_evidence_pack(run_view: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("TraceForge run evidence pack");
    lines.append("Run ID: " + str(run_view["run_id"]));
    lines.append("Task: " + str(run_view["task_title"]));
    lines.append("Primary failure candidate: " + str(run_view["primary_failure"]));
    lines.append("Critical step candidate: " + str(run_view["critical_step_idx"]));
    lines.append("Summary: " + str(run_view["summary"]));
    lines.append("Fingerprint:");
    lines.append(str(run_view["artifacts"]["fingerprint"]));
    lines.append("Critical evidence window:");
    for step in run_view["critical_evidence_window"] {
        lines.append(
            "Step "
            + str(step["idx"])
            + " ["
            + str(step["phase"])
            + "]: "
            + str(step["excerpt"])
        );
    }
    return truncate_text("\n".join(lines), 2200);
}

def _cluster_evidence_pack(cluster_view: dict[str, any]) -> str {
    lines: list[str] = [];
    lines.append("TraceForge cluster evidence pack");
    lines.append("Cluster ID: " + str(cluster_view["cluster_id"]));
    lines.append("Cluster label candidate: " + str(cluster_view["label"]));
    lines.append("Failure class: " + str(cluster_view["failure_class"]));
    lines.append("Cluster size: " + str(cluster_view["size"]));
    lines.append("Summary: " + str(cluster_view["summary"]));
    lines.append("Recurring signals:");
    for signal in cluster_view["recurring_signals"] {
        lines.append("- " + str(signal));
    }
    lines.append("Representative runs:");
    for run_item in cluster_view["representative_runs"] {
        lines.append(
            "- "
            + str(run_item["run_id"])
            + ": "
            + str(run_item["summary"])
        );
    }
    return truncate_text("\n".join(lines), 2000);
}

def _deterministic_diagnosis(run_view: dict[str, any]) -> dict[str, any] {
    evidence = [];
    for step in run_view["critical_evidence_window"] {
        evidence.append(
            {
                "step_idx": step["idx"],
                "artifact": step["phase"],
                "quote": step["excerpt"],
            }
        );
    }
    failure_class = str(run_view.get("primary_failure") or "UNKNOWN");
    return {
        "run_id": run_view["run_id"],
        "failure_class": failure_class,
        "critical_step_idx": run_view["critical_step_idx"],
        "irreversible_because": diagnosis_reason(failure_class),
        "evidence": evidence,
        "confidence": 0.68 if run_view["critical_step_idx"] >= 0 else 0.2,
        "status": "deterministic_diagnosis",
        "llm_used": False,
        "evidence_pack": _run_evidence_pack(run_view),
    };
}

def _deterministic_cluster_label(cluster_view: dict[str, any]) -> dict[str, any] {
    return {
        "cluster_id": cluster_view["cluster_id"],
        "label": cluster_view["label"],
        "summary": cluster_view["summary"],
        "failure_class": cluster_view["failure_class"],
        "confidence": 0.7,
        "status": "deterministic_cluster_label",
        "llm_used": False,
        "evidence_pack": _cluster_evidence_pack(cluster_view),
    };
}

def _deterministic_patch(root_node: any, cluster_view: dict[str, any]) -> dict[str, any] {
    support_records = _cluster_support_records(root_node, cluster_view);
    rules = _evidence_grounded_rule_records(cluster_view, support_records);
    evidence_lines = _evidence_lines(cluster_view, support_records);
    diff_lines = [
        "--- AGENTS.md",
        "+++ AGENTS.md",
        "@@",
        "+## " + str(cluster_view["label"]),
        "+### Evidence Anchors",
    ];
    if evidence_lines {
        for line in evidence_lines {
            diff_lines.append("+- " + line);
        }
    } else {
        diff_lines.append("+- No representative evidence was available; using recurring cluster signals only.");
    }
    diff_lines.append("+### Rules");
    for rule in rules {
        diff_lines.append("+- " + str(rule["rule_text"]));
    }
    return {
        "cluster_id": cluster_view["cluster_id"],
        "scope": "cluster",
        "cluster_label": cluster_view["label"],
        "summary": "Operational memory patch synthesized from representative runs, critical-step evidence, and recurring cluster signals.",
        "rules": rules,
        "diff_text": "\n".join(diff_lines),
        "confidence": 0.66 if len(rules) > 0 else 0.5,
        "status": "deterministic_patch",
        "llm_used": False,
        "evidence_pack": _cluster_evidence_pack(cluster_view) + "\nEvidence anchors:\n" + "\n".join(evidence_lines),
    };
}

def _store_patch_response(root_node: any, cluster_id: str, response: dict[str, any]) -> dict[str, any] {
    batch_id = cluster_id.split(":")[0];
    compiled = ensure_batch_graph(root_node, batch_id);
    if compiled["batch"] is not None {
        cluster_node = find_cluster_node(compiled["batch"], cluster_id);
        if cluster_node is not None {
            stored = upsert_cluster_patch(
                cluster_node,
                {
                    "patch_id": cluster_id + ":memory_patch",
                    "scope": str(response["scope"]),
                    "title": str(response["cluster_label"]) + " memory patch",
                    "diff_text": str(response["diff_text"]),
                    "confidence": float(response["confidence"]),
                },
            );
            response["stored_patch_id"] = stored["patch_id"];
            response["stored_in_graph"] = True;
            response["stored_patch_created"] = stored["created"];
            return response;
        }
    }
    response["stored_in_graph"] = False;
    return response;
}

def diagnose_run_summary(root_node: any, run_id: str, batch_id: str = "") -> dict[str, any] {
    run_view = run_view_summary(root_node, run_id, batch_id);
    if run_view["status"] == "stub" {
        return {
            "run_id": run_id,
            "status": "missing",
            "message": "Run was not found.",
        };
    }

    fallback = _deterministic_diagnosis(run_view);
    if not llm_enabled() {
        return fallback;
    }

    try {
        predicted = choose_failure_class(fallback["evidence_pack"]);
        predicted_name = failure_class_name(predicted);
        return {
            "run_id": fallback["run_id"],
            "failure_class": predicted_name,
            "critical_step_idx": fallback["critical_step_idx"],
            "irreversible_because": diagnosis_reason(predicted_name),
            "evidence": fallback["evidence"],
            "confidence": 0.8 if fallback["critical_step_idx"] >= 0 else 0.35,
            "status": "llm_validated_diagnosis",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
        };
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return fallback;
    }
}

def diagnose_cluster_summary(root_node: any, cluster_id: str) -> dict[str, any] {
    cluster_view = cluster_view_summary(root_node, cluster_id);
    if cluster_view["status"] == "missing" {
        return {
            "cluster_id": cluster_id,
            "status": "missing",
            "message": "Cluster was not found.",
        };
    }

    fallback = _deterministic_cluster_label(cluster_view);
    if not llm_enabled() {
        return fallback;
    }

    try {
        labeled = draft_cluster_label(fallback["evidence_pack"]);
        return {
            "cluster_id": cluster_id,
            "label": labeled.label,
            "summary": labeled.summary,
            "failure_class": cluster_view["failure_class"],
            "confidence": labeled.confidence,
            "status": "llm_cluster_label",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
        };
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return fallback;
    }
}

def compile_memory_patch_summary(root_node: any, cluster_id: str) -> dict[str, any] {
    cluster_view = cluster_view_summary(root_node, cluster_id);
    if cluster_view["status"] == "missing" {
        return {
            "cluster_id": cluster_id,
            "status": "missing",
            "message": "Cluster was not found.",
        };
    }

    fallback = _deterministic_patch(root_node, cluster_view);
    if not llm_enabled() {
        return _store_patch_response(root_node, cluster_id, fallback);
    }

    try {
        proposal = draft_memory_patch(fallback["evidence_pack"]);
        output_rules = [];
        max_confidence = 0.64;
        for rule in proposal.rules {
            rule_confidence = float(rule.confidence);
            if rule_confidence > max_confidence {
                max_confidence = rule_confidence;
            }
            output_rules.append(
                {
                    "title": rule.title,
                    "rationale": rule.rationale,
                    "rule_text": rule.rule_text,
                    "supported_by_steps": rule.supported_by_steps,
                    "confidence": rule.confidence,
                }
            );
        }

        chosen_diff_text = proposal.diff_text;
        if not chosen_diff_text {
            chosen_diff_text = fallback["diff_text"];
        }
        chosen_cluster_label = proposal.cluster_label;
        if not chosen_cluster_label {
            chosen_cluster_label = cluster_view["label"];
        }

        llm_response = {
            "cluster_id": cluster_id,
            "scope": proposal.scope or "cluster",
            "cluster_label": chosen_cluster_label,
            "summary": proposal.summary,
            "rules": output_rules if output_rules else fallback["rules"],
            "diff_text": chosen_diff_text,
            "confidence": max_confidence,
            "status": "llm_patch",
            "llm_used": True,
            "evidence_pack": fallback["evidence_pack"],
        };
        return _store_patch_response(root_node, cluster_id, llm_response);
    } except Exception as err {
        fallback["llm_error"] = str(err);
        return _store_patch_response(root_node, cluster_id, fallback);
    }
}
