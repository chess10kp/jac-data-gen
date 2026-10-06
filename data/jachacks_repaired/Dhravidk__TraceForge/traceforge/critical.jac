import from traceforge.parser { ParsedRun, ParsedStep, step_text }
import from traceforge.features { bounded_ratio }

def _has_error_signal(text: str) -> bool {
    lower = text.lower();
    return any(token in lower for token in ["traceback", "error", "exception", "failed", "syntaxerror"]);
}

def _has_recovery_signal(text: str) -> bool {
    lower = text.lower();
    return any(token in lower for token in ["1 passed", " passed", "resolved", "fixed", "success"]);
}

def _has_submit_signal(text: str) -> bool {
    lower = text.lower();
    return "submit" in lower or "final" in lower;
}

def _has_patch_signal(text: str) -> bool {
    lower = text.lower();
    return "patch" in lower or "diff" in lower or "apply_patch" in lower;
}

def _has_test_signal(text: str) -> bool {
    lower = text.lower();
    return "pytest" in lower or "test" in lower;
}

def _step_texts(run: ParsedRun) -> list[str] {
    output: list[str] = [];
    for step in run.steps {
        output.append(step_text(step));
    }
    return output;
}

def candidate_step_indices(run: ParsedRun, fingerprint: dict[str, any]) -> list[int] {
    candidates: list[int] = [];
    for key in ["first_patch_step", "first_test_step", "first_error_step", "first_submit_step"] {
        value = int(fingerprint.get(key, -1));
        if value >= 0 and value not in candidates {
            candidates.append(value);
        }
    }

    seen_hashes: dict[str, int] = {};
    seen_files: dict[str, int] = {};
    for (index, step) in enumerate(run.steps) {
        if step.content_hash and step.content_hash in seen_hashes and index not in candidates {
            candidates.append(index);
        }
        if step.content_hash {
            seen_hashes[step.content_hash] = index;
        }
        if step.touched_files {
            key = "|".join(step.touched_files);
            if key in seen_files and index not in candidates {
                candidates.append(index);
            }
            seen_files[key] = index;
        }
    }
    return sorted(candidates);
}

def build_evidence_window(run: ParsedRun, center_index: int, radius: int = 1) -> list[dict[str, any]] {
    window: list[dict[str, any]] = [];
    if center_index < 0 {
        return window;
    }
    start = max(center_index - radius, 0);
    stop = min(center_index + radius, len(run.steps) - 1);
    for index = start while index<=stop with index+=1 {
        step = run.steps[index];
        window.append(
            {
                "idx": step.index,
                "kind": step.kind,
                "phase": step.phase,
                "excerpt": step.excerpt,
            }
        );
    }
    return window;
}

def score_candidate_step(run: ParsedRun, fingerprint: dict[str, any], index: int) -> dict[str, any] {
    texts = _step_texts(run);
    text = texts[index];
    lower = text.lower();
    later_texts = texts[index + 1:];
    current_has_error = _has_error_signal(text);
    later_has_error = any(_has_error_signal(item) for item in later_texts);
    later_has_recovery = any(_has_recovery_signal(item) for item in later_texts);
    next_has_error = False;
    if index + 1 < len(texts) {
        next_has_error = _has_error_signal(texts[index + 1]);
    }

    persistence_of_damage = 0.35 if later_has_error and not later_has_recovery else 0.0;
    new_error_after_step = 0.25 if (not current_has_error and next_has_error) else 0.0;
    no_recovery_after_step = 0.2 if not later_has_recovery else 0.0;
    divergence_from_target_files = 0.0;
    top_files = fingerprint.get("top_files", []);
    current_files = run.steps[index].touched_files;
    if current_files and top_files {
        overlap = 0;
        for file_path in current_files {
            if file_path in top_files {
                overlap += 1;
            }
        }
        if bounded_ratio(overlap, len(current_files)) < 0.34 {
            divergence_from_target_files = 0.15;
        }
    }
    premature_submit_signal = 0.0;
    first_submit = int(fingerprint.get("first_submit_step", -1));
    if bool(fingerprint.get("submit_before_recovery")) and (index == first_submit or index + 1 == first_submit) {
        premature_submit_signal = 0.3;
    }
    loop_start_signal = 0.0;
    if float(fingerprint.get("loop_score", 0.0)) >= 0.35 {
        if index + 1 < len(run.steps) {
            next_step = run.steps[index + 1];
            if next_step.content_hash == run.steps[index].content_hash {
                loop_start_signal = 0.2;
            } elif run.steps[index].touched_files and next_step.touched_files and run.steps[index].touched_files == next_step.touched_files {
                loop_start_signal = 0.15;
            }
        } elif _has_submit_signal(text) and not later_has_recovery {
            loop_start_signal = 0.1;
        }
    }
    patch_to_error_signal = 0.0;
    if _has_patch_signal(text) and later_has_error and not later_has_recovery {
        patch_to_error_signal = 0.25;
    }
    test_failure_signal = 0.0;
    if _has_test_signal(text) and current_has_error and not later_has_recovery {
        test_failure_signal = 0.15;
    }
    recovery_signal = 0.25 if later_has_recovery else 0.0;

    score = round(
        persistence_of_damage
        + new_error_after_step
        + no_recovery_after_step
        + divergence_from_target_files
        + premature_submit_signal
        + loop_start_signal
        + patch_to_error_signal
        + test_failure_signal
        - recovery_signal,
        4,
    );
    return {
        "step_idx": index,
        "score": score,
        "signals": {
            "persistence_of_damage": persistence_of_damage,
            "new_error_after_step": new_error_after_step,
            "no_recovery_after_step": no_recovery_after_step,
            "divergence_from_target_files": divergence_from_target_files,
            "premature_submit_signal": premature_submit_signal,
            "loop_start_signal": loop_start_signal,
            "patch_to_error_signal": patch_to_error_signal,
            "test_failure_signal": test_failure_signal,
            "recovery_signal": recovery_signal,
        },
    };
}

def localize_critical_step(run: ParsedRun, fingerprint: dict[str, any]) -> dict[str, any] {
    if str(run.metadata.get("status") or "").lower() in {"resolved", "passed", "success", "succeeded"} {
        return {
            "critical_step_idx": -1,
            "confidence": 0.0,
            "candidate_scores": [],
            "evidence_window": [],
            "status": "resolved_run",
        };
    }

    candidates = candidate_step_indices(run, fingerprint);
    if not candidates and len(run.steps) > 0 {
        candidates = [0];
    }

    scored: list[dict[str, any]] = [];
    for candidate in candidates {
        scored.append(score_candidate_step(run, fingerprint, candidate));
    }

    chosen_idx = -1;
    chosen_score = -999.0;
    threshold = 0.45;
    for item in scored {
        item_score = float(item["score"]);
        item_idx = int(item["step_idx"]);
        if item_score >= threshold {
            chosen_idx = item_idx;
            chosen_score = item_score;
            break;
        }
        if item_score > chosen_score or (item_score == chosen_score and (chosen_idx < 0 or item_idx < chosen_idx)) {
            chosen_idx = item_idx;
            chosen_score = item_score;
        }
    }

    rounded_score: float = round(chosen_score, 4);
    return {
        "critical_step_idx": chosen_idx,
        "confidence": max(rounded_score, 0.0),
        "candidate_scores": scored,
        "evidence_window": build_evidence_window(run, chosen_idx),
        "status": "localized",
    };
}
