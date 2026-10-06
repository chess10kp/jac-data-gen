import from traceforge.parser {
    ParsedRun,
    ParsedStep,
    extract_file_tokens,
    step_has_command,
    step_has_error,
    step_has_patch,
    step_has_submit,
    step_has_test,
    step_text,
    truncate_text,
    unique_strings
}

def bounded_ratio(numerator: int|float, denominator: int|float) -> float {
    if denominator <= 0 {
        return 0.0;
    }
    ratio = numerator / denominator;
    if ratio < 0.0 {
        ratio = 0.0;
    }
    if ratio > 1.0 {
        ratio = 1.0;
    }
    return round(ratio, 4);
}

def count_tokens(items: list[str]) -> dict[str, int] {
    counts: dict[str, int] = {};
    for item in items {
        key = str(item);
        if not key {
            continue;
        }
        counts[key] = counts.get(key, 0) + 1;
    }
    return counts;
}

def sort_count_pairs(counts: dict[str, int]) -> list[tuple[str, int]] {
    pairs: list[tuple[str, int]] = [];
    for key in counts {
        pairs.append((key, counts[key]));
    }
    return sorted(
        pairs,
        key=lambda (pair: any) -> any { (-pair[1], pair[0]) },
    );
}

def summarize_counts(items: list[str], limit: int = 5) -> list[tuple[str, int]] {
    return sort_count_pairs(count_tokens(items))[: max(limit, 0)];
}

def cosine_like_overlap(left: list[str], right: list[str]) -> float {
    left_counts = count_tokens(left);
    right_counts = count_tokens(right);
    if not left_counts and not right_counts {
        return 1.0;
    }
    if not left_counts or not right_counts {
        return 0.0;
    }

    intersection = 0;
    for token in left_counts {
        if token in right_counts {
            intersection += min(left_counts[token], right_counts[token]);
        }
    }
    left_total = 0;
    right_total = 0;
    for token in left_counts {
        left_total += left_counts[token];
    }
    for token in right_counts {
        right_total += right_counts[token];
    }
    return round((2.0 * intersection) / (left_total + right_total), 4);
}

def top_k_indices(values: list[float], k: int = 5) -> list[int] {
    indexed = [];
    for (index, value) in enumerate(values) {
        indexed.append((index, value));
    }
    ordered = sorted(indexed, key=lambda (pair: any) -> any { (-pair[1], pair[0]) });
    return [index for (index, _) in ordered[: max(k, 0)]];
}

def dominant_failure_label(fingerprint: dict[str, any]) -> str {
    scores = fingerprint.get("failure_class_scores", {});
    best_label = "UNKNOWN";
    best_score = 0.0;
    for label in scores {
        score = float(scores[label]);
        if score > best_score {
            best_label = str(label);
            best_score = score;
        }
    }
    return best_label;
}

def _status_is_resolved(run: ParsedRun) -> bool {
    status = str(run.metadata.get("status") or "").lower();
    return status in {"resolved", "passed", "success", "succeeded"};
}

def compute_run_fingerprint(run: ParsedRun) -> dict[str, any] {
    fingerprint: dict[str, any] = {
        "num_steps": len(run.steps),
        "num_turns": len(run.turns),
        "num_commands": 0,
        "num_tests": 0,
        "num_patches": 0,
        "num_unique_files": 0,
        "repeated_step_ratio": 0.0,
        "repeated_file_ratio": 0.0,
        "first_patch_step": -1,
        "first_test_step": -1,
        "first_error_step": -1,
        "first_submit_step": -1,
        "submit_before_recovery": False,
        "nonzero_return_ratio": 0.0,
        "loop_score": 0.0,
        "top_files": [],
        "top_test_names": [],
        "top_error_keywords": [],
        "step_kind_sequence": [],
        "failure_class_scores": {},
        "did_any_edit": False,
        "did_any_test": False,
        "did_any_patch_parse_fail": False,
        "did_any_syntax_error": False,
        "did_any_import_error": False,
        "ended_in_fail_signal": False,
        "late_first_edit": False,
        "late_first_test": False,
        "run_status": str(run.metadata.get("status") or "unknown").lower(),
    };

    files: list[str] = [];
    repeated_hits = 0;
    seen_hashes: set[str] = set();
    nonzero_returns = 0;
    saw_error = False;
    passed_after_error = False;
    search_command_hits = 0;
    syntax_error_after_patch = False;
    planning_steps = 0;

    for (idx, step) in enumerate(run.steps) {
        text = step_text(step);
        lower = text.lower();
        fingerprint["step_kind_sequence"].append(step.kind or "OTHER");

        if step_has_command(step) {
            fingerprint["num_commands"] += 1;
        }
        command_lower = str(step.command_text or "").lower();
        if any(token in command_lower for token in ["grep ", "ls ", "find ", "read ", "inspect", "rg ", "cat ", "sed "]) {
            search_command_hits += 1;
            if step.phase == "inspect" {
                planning_steps += 1;
            }
        }
        if step_has_test(step) {
            fingerprint["num_tests"] += 1;
            fingerprint["did_any_test"] = True;
            if fingerprint["first_test_step"] < 0 {
                fingerprint["first_test_step"] = idx;
            }
            fingerprint["top_test_names"].extend(extract_file_tokens(step.test_text));
        }
        if step_has_patch(step) {
            fingerprint["num_patches"] += 1;
            fingerprint["did_any_edit"] = True;
            if fingerprint["first_patch_step"] < 0 {
                fingerprint["first_patch_step"] = idx;
            }
        }
        if step_has_error(step) {
            saw_error = True;
            if fingerprint["first_error_step"] < 0 {
                fingerprint["first_error_step"] = idx;
            }
            error_lower = step.error_text.lower();
            for token in ["traceback", "error", "exception", "failed", "syntaxerror", "importerror"] {
                if token in error_lower {
                    fingerprint["top_error_keywords"].append(token);
                }
            }
            if "syntaxerror" in error_lower or "invalid syntax" in error_lower {
                fingerprint["did_any_syntax_error"] = True;
            }
            if "importerror" in error_lower or "module not found" in error_lower {
                fingerprint["did_any_import_error"] = True;
            }
            if fingerprint["first_patch_step"] >= 0 and idx >= fingerprint["first_patch_step"] {
                if "syntaxerror" in error_lower or "invalid syntax" in error_lower or "traceback" in error_lower {
                    syntax_error_after_patch = True;
                    fingerprint["did_any_patch_parse_fail"] = True;
                }
            }
        }
        if saw_error and (" passed" in lower or lower.startswith("passed") or "resolved" in lower or "1 passed" in lower) {
            passed_after_error = True;
        }
        if step_has_submit(step) {
            if fingerprint["first_submit_step"] < 0 {
                fingerprint["first_submit_step"] = idx;
            }
        }
        if "returncode" in command_lower or "exit code" in command_lower or "non-zero" in command_lower or "command failed" in command_lower {
            nonzero_returns += 1;
        }
        if step.phase == "reason" and not step_has_command(step) and not step_has_patch(step) and not step_has_test(step) {
            planning_steps += 1;
        }

        extracted = extract_file_tokens(text);
        if extracted {
            files.extend(extracted);
        }
        if step.content_hash in seen_hashes {
            repeated_hits += 1;
        } else {
            seen_hashes.add(step.content_hash);
        }
    }

    unique_files = unique_strings(files);
    fingerprint["num_unique_files"] = len(unique_files);
    fingerprint["top_files"] = unique_files[:8];
    fingerprint["top_error_keywords"] = unique_strings(fingerprint["top_error_keywords"])[:8];
    fingerprint["top_test_names"] = unique_strings(fingerprint["top_test_names"])[:8];
    fingerprint["repeated_step_ratio"] = bounded_ratio(repeated_hits, max(len(run.steps), 1));
    fingerprint["repeated_file_ratio"] = bounded_ratio(len(files) - len(unique_files), max(len(files), 1));
    fingerprint["nonzero_return_ratio"] = bounded_ratio(nonzero_returns, max(len(run.steps), 1));
    fingerprint["loop_score"] = round(
        (fingerprint["repeated_step_ratio"] * 0.6) + (fingerprint["repeated_file_ratio"] * 0.4),
        4,
    );
    fingerprint["submit_before_recovery"] = (
        fingerprint["first_submit_step"] >= 0
        and fingerprint["first_error_step"] >= 0
        and not passed_after_error
    );
    fingerprint["late_first_edit"] = (
        fingerprint["first_patch_step"] >= 0
        and fingerprint["first_patch_step"] >= max(len(run.steps) // 2, 1)
    );
    fingerprint["late_first_test"] = (
        fingerprint["first_test_step"] >= 0
        and fingerprint["first_test_step"] >= max(len(run.steps) // 2, 1)
    );
    fingerprint["ended_in_fail_signal"] = (
        not _status_is_resolved(run)
        and not passed_after_error
        and fingerprint["first_error_step"] >= 0
    );

    failure_scores = {
        "PREMATURE_COMPLETION": 0.0,
        "INVALID_PATCH": 0.0,
        "WRONG_FILE_FOCUS": 0.0,
        "OSCILLATION_LOOP": 0.0,
        "TOOL_MISUSE": fingerprint["nonzero_return_ratio"],
        "STALE_CONTEXT_OR_BAD_PLAN": 0.0,
        "REQUIREMENT_DRIFT": 0.0,
    };
    if fingerprint["submit_before_recovery"] {
        failure_scores["PREMATURE_COMPLETION"] = 0.8;
    }
    if (
        fingerprint["first_patch_step"] >= 0
        and fingerprint["first_error_step"] >= 0
        and fingerprint["first_patch_step"] <= fingerprint["first_error_step"]
        and not passed_after_error
    ) {
        failure_scores["INVALID_PATCH"] = 0.95 if syntax_error_after_patch else 0.5;
    }
    if fingerprint["num_unique_files"] > 0 and fingerprint["repeated_file_ratio"] > 0.5 {
        failure_scores["WRONG_FILE_FOCUS"] = 0.5;
    }
    if (
        not passed_after_error
        and (
            fingerprint["loop_score"] >= 0.35
            or search_command_hits >= 3
            or (fingerprint["repeated_file_ratio"] >= 0.25 and fingerprint["num_tests"] == 0)
        )
    ) {
        failure_scores["OSCILLATION_LOOP"] = max(fingerprint["loop_score"], 0.7);
    }
    if fingerprint["num_patches"] == 0 and planning_steps >= 2 and fingerprint["num_tests"] <= 1 {
        failure_scores["STALE_CONTEXT_OR_BAD_PLAN"] = 0.55;
    }
    if fingerprint["num_unique_files"] >= 4 and fingerprint["num_tests"] == 0 {
        failure_scores["REQUIREMENT_DRIFT"] = 0.45;
    }
    fingerprint["failure_class_scores"] = failure_scores;
    return fingerprint;
}

def fingerprint_to_dict(fingerprint: dict[str, any]) -> dict[str, any] {
    return dict(fingerprint);
}

def build_run_digest(run: ParsedRun, fingerprint: dict[str, any]) -> str {
    status = str(run.metadata.get("status") or "unknown");
    primary_failure = dominant_failure_label(fingerprint);
    parts: list[str] = [
        f"Run {run.run_id} on task '{run.task_title or 'unknown task'}' ended with status {status}.",
        f"{fingerprint['num_steps']} decision steps, {fingerprint['num_tests']} test actions, {fingerprint['num_patches']} patch actions.",
    ];
    if primary_failure != "UNKNOWN" {
        parts.append(f"Primary failure family: {primary_failure}.");
    }
    if fingerprint["top_files"] {
        parts.append("Top files: " + ", ".join(fingerprint["top_files"][:4]) + ".");
    }
    if fingerprint["top_error_keywords"] {
        parts.append("Error signals: " + ", ".join(fingerprint["top_error_keywords"][:4]) + ".");
    }
    if fingerprint["submit_before_recovery"] {
        parts.append("Submission happened before visible recovery.");
    }
    if fingerprint["loop_score"] >= 0.35 {
        parts.append(f"Loop score {fingerprint['loop_score']} indicates repetition.");
    }
    return truncate_text(" ".join(parts), 500);
}
