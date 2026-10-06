import os;
import sys;
import json;
import time;

glob DATA_ROOT: str = "./jac/layer_data";
glob WORKFLOW_DIR: str = DATA_ROOT + "/workflows";

glob RUN_STATUS_SUCCESS: str = "success";
glob RUN_STATUS_PARTIAL: str = "partial";
glob RUN_STATUS_BLOCKED_MANUAL: str = "blocked_manual";
glob RUN_STATUS_STOPPED_POLICY: str = "stopped_policy";
glob RUN_STATUS_FAILED: str = "failed";

glob PHASE_INITIALIZING: str = "initializing";
glob PHASE_ONE_TIME: str = "one_time";
glob PHASE_REPEATED: str = "repeated";
glob PHASE_CONTINUATION: str = "continuation";
glob PHASE_FINISHED: str = "finished";

glob DEFAULT_MAX_REPEATED_ITERATIONS: int = 25;

"""R: Return a simple timestamp string for planner metadata.
M: Uses `time.time()` and string-casts for compatibility.
E: Timestamp format is epoch-like string, not ISO.
"""
def timestamp_now() -> str {
    return str(time.time());
}

"""R: Parse JSON payload passed from CLI command args.
M: Joins args index 2+ and decodes JSON object payload.
E: Invalid/non-dict payload returns empty dict.
"""
def parse_payload() -> dict[str, any] {
    raw_payload: str = "{}";
    if len(sys.argv) > 2 {
        raw_payload = " ".join(sys.argv[2:]);
    }

    try {
        parsed = json.loads(raw_payload);
        if isinstance(parsed, dict) {
            return parsed;
        }
        return {};
    } except json.JSONDecodeError {
        return {};
    }
}

"""R: Build workflow file path for one workflow id.
M: Joins workflow dir and `<workflow_id>.json`.
E: Caller validates workflow id.
"""
def workflow_file(workflow_id: str) -> str {
    return WORKFLOW_DIR + "/" + workflow_id + ".json";
}

"""R: Read one workflow JSON document from disk.
M: Loads file and returns dict payload if valid.
E: Missing/invalid documents return empty dict.
"""
def read_workflow(workflow_id: str) -> dict[str, any] {
    path = workflow_file(workflow_id);
    if not os.path.exists(path) {
        return {};
    }

    try {
        with open(path, "r") as file {
            parsed = json.load(file);
            if isinstance(parsed, dict) {
                return parsed;
            }
        }
    } except json.JSONDecodeError {
        return {};
    } except OSError {
        return {};
    }

    return {};
}

"""R: Add unresolved input keys once while preserving order.
M: Appends only when key is non-empty and not already present.
E: Mutates list in place for planner/runtime efficiency.
"""
def add_unique_key(values: list[str], key: str) {
    if not key {
        return;
    }
    if key not in values {
        values.append(key);
    }
}

"""R: Resolve one workflow step with runtime inputs when placeholders exist.
M: Copies the step and materializes supported input references into a concrete value.
E: Unknown fill-value shapes are passed through unchanged.
"""
def resolve_step(step: dict[str, any], run_inputs: dict[str, any], unresolved: list[str]) -> dict[str, any] {
    resolved_step: dict[str, any] = dict(step);
    step_type = str(step.get("type", ""));

    if step_type != "fill" {
        return resolved_step;
    }

    value_source = str(step.get("value_source", ""));
    if value_source.startswith("input.") {
        input_key = value_source[6:];
        runtime_value = str(run_inputs.get(input_key, ""));
        resolved_step["value"] = {"kind": "literal", "value": runtime_value};

        if not runtime_value {
            add_unique_key(unresolved, input_key);
        }

        return resolved_step;
    }

    value_spec: any = step.get("value", {});
    if isinstance(value_spec, dict) and str(value_spec.get("kind", "")) == "input" {
        input_key = str(
            value_spec.get("inputKey", "") or
            value_spec.get("name", "") or
            value_spec.get("key", "")
        );
        runtime_value = str(run_inputs.get(input_key, ""));
        resolved_step["value"] = {"kind": "literal", "value": runtime_value};

        if not runtime_value {
            add_unique_key(unresolved, input_key);
        }
    }

    return resolved_step;
}

"""R: Build a dry-run execution plan from a flat workflow + runtime inputs.
M: Resolves each step deterministically and tracks unresolved input placeholders.
E: Non-dict steps are ignored to avoid planner crashes.
"""
def build_plan(workflow: dict[str, any], run_inputs: dict[str, any]) -> dict[str, any] {
    planned_steps: list[any] = [];
    unresolved_inputs: list[str] = [];

    raw_steps: list[any] = [];
    candidate_steps = workflow.get("steps", []);
    if isinstance(candidate_steps, list) {
        raw_steps = candidate_steps;
    }

    for raw_step in raw_steps {
        if not isinstance(raw_step, dict) {
            continue;
        }

        resolved = resolve_step(raw_step, run_inputs, unresolved_inputs);
        planned_steps.append(resolved);
    }

    return {
        "planned_steps": planned_steps,
        "unresolved_inputs": unresolved_inputs
    };
}

"""R: Detect whether a JSON payload is a segmented compiled artifact.
M: Checks for the structural keys emitted by the segmented compiler.
E: Invalid or partial shapes return False instead of raising.
"""
def is_segmented_artifact(candidate: any) -> bool {
    if not isinstance(candidate, dict) {
        return False;
    }

    return (
        "one_time" in candidate and
        "repeated" in candidate and
        "continuation" in candidate and
        "stop_policy" in candidate
    );
}

"""R: Validate one segmented compiled artifact before execution.
M: Checks the same structural contract used by compilation without importing its CLI module.
E: Structural validation only; semantic/runtime issues are handled by the executor later.
"""
def validate_compiled_artifact(candidate: dict[str, any]) -> dict[str, any] {
    if not isinstance(candidate, dict) {
        return {"ok": False, "errors": ["artifact must be a dict"]};
    }

    errors: list[str] = [];
    required_top: list[str] = [
        "version", "id", "name", "recording_id", "metadata",
        "one_time", "repeated", "continuation", "stop_policy", "compileInfo"
    ];

    for field in required_top {
        if field not in candidate {
            errors.append(field + ": required field is missing");
        }
    }

    if candidate.get("version") != "1.0" {
        errors.append("version: must be \"1.0\"");
    }

    metadata: any = candidate.get("metadata", {});
    if isinstance(metadata, dict) {
        for field in ["createdAt", "updatedAt", "createdByUserId", "source"] {
            if field not in metadata {
                errors.append("metadata." + field + ": required field is missing");
            }
        }

        source: any = metadata.get("source", {});
        if isinstance(source, dict) {
            for field in ["recordingId", "origin", "domains"] {
                if field not in source {
                    errors.append("metadata.source." + field + ": required field is missing");
                }
            }
        }
    }

    for seg_name in ["one_time", "repeated"] {
        segment: any = candidate.get(seg_name, {});
        if not isinstance(segment, dict) {
            errors.append(seg_name + ": must be a dict");
        } else {
            if not isinstance(segment.get("inputs"), list) {
                errors.append(seg_name + ".inputs: must be a list");
            }
            if not isinstance(segment.get("steps"), list) {
                errors.append(seg_name + ".steps: must be a list");
            }
            if not isinstance(segment.get("annotations"), list) {
                errors.append(seg_name + ".annotations: must be a list");
            }
        }
    }

    continuation: any = candidate.get("continuation", {});
    if not isinstance(continuation, dict) {
        errors.append("continuation: must be a dict");
    } elif not isinstance(continuation.get("strategy"), list) {
        errors.append("continuation.strategy: must be a list");
    }

    stop_policy: any = candidate.get("stop_policy", {});
    if not isinstance(stop_policy, dict) {
        errors.append("stop_policy: must be a dict");
    } else {
        if "mode" not in stop_policy {
            errors.append("stop_policy.mode: required field is missing");
        }
        if "options" not in stop_policy {
            errors.append("stop_policy.options: required field is missing");
        }
    }

    compile_info: any = candidate.get("compileInfo", {});
    if isinstance(compile_info, dict) {
        for field in ["compilerVersion", "compiledAt", "sourceRecordingId"] {
            if field not in compile_info {
                errors.append("compileInfo." + field + ": required field is missing");
            }
        }
    }

    if errors {
        return {"ok": False, "errors": errors};
    }

    return {"ok": True, "artifact": candidate};
}

"""R: Build execution plan output for one flat compiled workflow.
M: Loads workflow, resolves input placeholders, and returns planner payload.
E: Segmented artifacts are rejected explicitly so they do not silently flatten.
"""
def plan_workflow(payload: dict[str, any]) -> dict[str, any] {
    workflow_id = str(payload.get("workflow_id", ""));
    if not workflow_id {
        return {"ok": False, "error": "workflow_id is required"};
    }

    run_inputs: dict[str, any] = {};
    candidate_inputs = payload.get("inputs", {});
    if isinstance(candidate_inputs, dict) {
        run_inputs = candidate_inputs;
    }

    workflow = read_workflow(workflow_id);
    if not workflow {
        return {"ok": False, "error": "workflow not found", "workflow_id": workflow_id};
    }

    if is_segmented_artifact(workflow) {
        return {
            "ok": False,
            "error": "segmented artifacts are executed via execute/execute_segmented, not plan",
            "workflow_id": workflow_id
        };
    }

    plan = build_plan(workflow, run_inputs);

    return {
        "ok": True,
        "workflow_id": workflow_id,
        "planned_at": timestamp_now(),
        "step_count": len(plan["planned_steps"]),
        "unresolved_inputs": plan["unresolved_inputs"],
        "planned_steps": plan["planned_steps"]
    };
}

"""R: Normalize optional runtime controls used by the segmented executor.
M: Accepts either payload-level keys or a nested `runtime` object for testability.
E: Invalid control shapes fall back to safe defaults.
"""
def runtime_controls_from_payload(payload: dict[str, any]) -> dict[str, any] {
    controls: dict[str, any] = payload;

    nested: any = payload.get("runtime", {});
    if isinstance(nested, dict) {
        controls = {**payload, **nested};
    }

    max_repeated_iterations: int = DEFAULT_MAX_REPEATED_ITERATIONS;
    raw_max = controls.get("max_repeated_iterations", None);
    if raw_max is not None and isinstance(raw_max, int) and not isinstance(raw_max, bool) and raw_max > 0 {
        max_repeated_iterations = raw_max;
    }

    traversal_results: dict[str, any] = {};
    raw_results = controls.get("traversal_results", {});
    if isinstance(raw_results, dict) {
        traversal_results = raw_results;
    }

    return {
        "max_repeated_iterations": max_repeated_iterations,
        "traversal_results": traversal_results,
        "traversal_cursors": {}
    };
}

"""R: Build the mutable runtime state/result envelope for one segmented run.
M: Seeds counters, execution logs, and policy summaries before any work starts.
E: Assumes validation already happened or will happen immediately after creation.
"""
def new_execution_state(artifact: dict[str, any]) -> dict[str, any] {
    continuation: any = artifact.get("continuation", {});
    strategy: list[any] = [];
    if isinstance(continuation, dict) and isinstance(continuation.get("strategy", []), list) {
        strategy = continuation.get("strategy", []);
    }

    continuation_modes: list[str] = [];
    for item in strategy {
        if isinstance(item, dict) {
            continuation_modes.append(str(item.get("mode", "")));
        }
    }

    stop_policy: any = artifact.get("stop_policy", {});
    stop_policy_mode: str = "";
    stop_policy_options: dict[str, any] = {};
    if isinstance(stop_policy, dict) {
        stop_policy_mode = str(stop_policy.get("mode", ""));
        options = stop_policy.get("options", {});
        if isinstance(options, dict) {
            stop_policy_options = options;
        }
    }

    return {
        "artifact_id": str(artifact.get("id", "")),
        "artifact_name": str(artifact.get("name", "")),
        "recording_id": str(artifact.get("recording_id", "")),
        "run_status": RUN_STATUS_PARTIAL,
        "current_phase": PHASE_INITIALIZING,
        "one_time_completed": False,
        "repeated_iterations": 0,
        "successful_repeated_runs": 0,
        "continuation_attempts": 0,
        "continuation_counts": {
            "next_similar_item": 0,
            "scroll_for_more": 0,
            "next_page": 0
        },
        "continuation_strategy": continuation_modes,
        "last_continuation_action": "",
        "stop_policy_mode": stop_policy_mode,
        "stop_policy_options": stop_policy_options,
        "stop_reason": "",
        "warnings": [],
        "logs": [],
        "step_results": [],
        "continuation_history": [],
        "unresolved_inputs": [],
        "pending_user_action": ""
    };
}

"""R: Resolve every step in one compiled segment with runtime inputs.
M: Applies placeholder resolution step-by-step and accumulates unresolved keys.
E: Non-dict steps are skipped to keep execution tolerant of malformed artifacts.
"""
def resolve_segment_steps(block: dict[str, any], run_inputs: dict[str, any]) -> dict[str, any] {
    resolved_steps: list[any] = [];
    unresolved_inputs: list[str] = [];

    raw_steps: list[any] = [];
    candidate_steps = block.get("steps", []);
    if isinstance(candidate_steps, list) {
        raw_steps = candidate_steps;
    }

    for raw_step in raw_steps {
        if not isinstance(raw_step, dict) {
            continue;
        }
        resolved_steps.append(resolve_step(raw_step, run_inputs, unresolved_inputs));
    }

    return {
        "steps": resolved_steps,
        "unresolved_inputs": unresolved_inputs
    };
}

"""R: Execute one logical segment block while keeping runtime bookkeeping explicit.
M: Resolves the block, records one step result per step, and marks success by unresolved-input absence.
E: Empty blocks are valid and return success with zero recorded steps.
"""
def execute_segment_block(
    block: dict[str, any],
    phase: str,
    iteration: int,
    run_inputs: dict[str, any],
    state: dict[str, any]
) -> dict[str, any] {
    resolved: dict[str, any] = resolve_segment_steps(block, run_inputs);
    resolved_steps: list[any] = resolved["steps"];
    unresolved_inputs: list[str] = resolved["unresolved_inputs"];

    label: str = phase;
    if phase == PHASE_REPEATED {
        label = phase + " iteration " + str(iteration);
    }

    state["logs"].append("Starting " + label + " with " + str(len(resolved_steps)) + " steps");

    for step in resolved_steps {
        step_result: dict[str, any] = {
            "phase": phase,
            "iteration": iteration,
            "step_id": str(step.get("id", "")),
            "step_type": str(step.get("type", "")),
            "status": "success",
            "step": step
        };
        state["step_results"].append(step_result);
    }

    if len(unresolved_inputs) > 0 {
        for key in unresolved_inputs {
            add_unique_key(state["unresolved_inputs"], key);
        }
        state["warnings"].append(
            label + " unresolved inputs: " + ", ".join(unresolved_inputs)
        );
    }

    state["logs"].append("Completed " + label);

    return {
        "ok": len(unresolved_inputs) == 0,
        "step_count": len(resolved_steps),
        "unresolved_inputs": unresolved_inputs
    };
}

"""R: Consume the next scripted traversal outcome for one continuation mode.
M: Uses per-mode cursors so tests can drive deterministic continuation without mutating input data.
E: Missing or exhausted scripts return an empty dict, which callers interpret as no advance.
"""
def next_scripted_traversal_result(runtime: dict[str, any], mode: str) -> dict[str, any] {
    traversal_results: any = runtime.get("traversal_results", {});
    if not isinstance(traversal_results, dict) {
        return {};
    }

    raw_mode_results: any = traversal_results.get(mode, []);
    if not isinstance(raw_mode_results, list) {
        return {};
    }

    cursors: any = runtime.get("traversal_cursors", {});
    if not isinstance(cursors, dict) {
        runtime["traversal_cursors"] = {};
        cursors = runtime["traversal_cursors"];
    }

    cursor: int = int(cursors.get(mode, 0));
    if cursor >= len(raw_mode_results) {
        return {};
    }

    cursors[mode] = cursor + 1;
    item = raw_mode_results[cursor];
    if isinstance(item, dict) {
        return item;
    }
    return {};
}

"""R: Attempt one traversal action from the continuation strategy.
M: Enforces mode-specific bounds, consumes scripted outcomes, and records the attempt in runtime state.
E: Browser actions are abstracted away; absent scripts default to `no_more_items`.
"""
def attempt_traversal_mode(
    mode: str,
    options: dict[str, any],
    iteration: int,
    state: dict[str, any],
    runtime: dict[str, any]
) -> dict[str, any] {
    advanced: bool = False;
    reason: str = "no_more_items";

    if mode == "scroll_for_more" {
        max_scrolls = options.get("max_scrolls", None);
        if isinstance(max_scrolls, int) and not isinstance(max_scrolls, bool) {
            if int(state["continuation_counts"]["scroll_for_more"]) >= max_scrolls {
                reason = "max_scrolls_reached";
                state["continuation_attempts"] = state["continuation_attempts"] + 1;
                state["continuation_history"].append({
                    "iteration": iteration,
                    "mode": mode,
                    "advanced": False,
                    "reason": reason
                });
                return {"advanced": False, "reason": reason, "mode": mode};
            }
        }
    }

    if mode == "next_page" {
        max_pages = options.get("max_pages", None);
        if isinstance(max_pages, int) and not isinstance(max_pages, bool) {
            if int(state["continuation_counts"]["next_page"]) >= max_pages {
                reason = "max_pages_reached";
                state["continuation_attempts"] = state["continuation_attempts"] + 1;
                state["continuation_history"].append({
                    "iteration": iteration,
                    "mode": mode,
                    "advanced": False,
                    "reason": reason
                });
                return {"advanced": False, "reason": reason, "mode": mode};
            }
        }
    }

    scripted: dict[str, any] = next_scripted_traversal_result(runtime, mode);
    if scripted {
        advanced = bool(scripted.get("advanced", False));
        default_reason: str = "advanced" if advanced else "no_more_items";
        reason = str(scripted.get("reason", default_reason));
    }

    state["continuation_attempts"] = state["continuation_attempts"] + 1;
    if advanced and mode in state["continuation_counts"] {
        state["continuation_counts"][mode] = state["continuation_counts"][mode] + 1;
        state["last_continuation_action"] = mode;
    }

    state["continuation_history"].append({
        "iteration": iteration,
        "mode": mode,
        "advanced": advanced,
        "reason": reason
    });

    return {"advanced": advanced, "reason": reason, "mode": mode};
}

"""R: Interpret continuation.strategy without mixing traversal into step execution.
M: Walks strategy entries in order and returns continue/stop/manual/cannot-continue decisions.
E: Empty strategy stops cleanly after the current repeated iteration.
"""
def apply_continuation_strategy(
    artifact: dict[str, any],
    iteration: int,
    state: dict[str, any],
    runtime: dict[str, any]
) -> dict[str, any] {
    continuation: any = artifact.get("continuation", {});
    strategy: list[any] = [];
    if isinstance(continuation, dict) and isinstance(continuation.get("strategy", []), list) {
        strategy = continuation.get("strategy", []);
    }

    if len(strategy) == 0 {
        state["logs"].append("No continuation strategy configured; stopping after current repeated run");
        return {"decision": "stop", "reason": "no_continuation_strategy", "mode": ""};
    }

    last_reason: str = "no_more_items";

    for raw_entry in strategy {
        if not isinstance(raw_entry, dict) {
            continue;
        }

        mode: str = str(raw_entry.get("mode", ""));
        options: dict[str, any] = {};
        raw_options = raw_entry.get("options", {});
        if isinstance(raw_options, dict) {
            options = raw_options;
        }

        if mode == "manual_pick_next" {
            state["continuation_history"].append({
                "iteration": iteration,
                "mode": mode,
                "advanced": False,
                "reason": "manual_pick_next"
            });
            state["pending_user_action"] = "manual_pick_next";
            state["logs"].append("Continuation requires manual item selection");
            return {"decision": "blocked_manual", "reason": "manual_pick_next", "mode": mode};
        }

        if mode == "stop" {
            state["continuation_history"].append({
                "iteration": iteration,
                "mode": mode,
                "advanced": False,
                "reason": "continuation_stop"
            });
            state["logs"].append("Continuation strategy requested stop");
            return {"decision": "stop", "reason": "continuation_stop", "mode": mode};
        }

        attempt: dict[str, any] = attempt_traversal_mode(mode, options, iteration, state, runtime);
        last_reason = str(attempt.get("reason", "no_more_items"));
        if bool(attempt.get("advanced", False)) {
            state["logs"].append("Continuation advanced via " + mode);
            return {"decision": "continue", "reason": "advanced", "mode": mode};
        }
    }

    state["logs"].append("Continuation could not find another repeated target");
    return {"decision": "cannot_continue", "reason": last_reason, "mode": ""};
}

"""R: Apply explicit stop policy rules after a repeated block completes.
M: Checks success/review counters and returns an action only when the policy should intervene.
E: `no_more_items` is handled when continuation cannot advance, not here.
"""
def check_stop_policy(artifact: dict[str, any], state: dict[str, any]) -> dict[str, any] {
    stop_policy: any = artifact.get("stop_policy", {});
    if not isinstance(stop_policy, dict) {
        return {"stop": False};
    }

    mode: str = str(stop_policy.get("mode", ""));
    options: dict[str, any] = {};
    raw_options = stop_policy.get("options", {});
    if isinstance(raw_options, dict) {
        options = raw_options;
    }

    if mode == "after_n_successes" {
        count = options.get("count", None);
        if isinstance(count, int) and not isinstance(count, bool) {
            if int(state["successful_repeated_runs"]) >= count {
                return {
                    "stop": True,
                    "run_status": RUN_STATUS_STOPPED_POLICY,
                    "reason": "after_n_successes"
                };
            }
        }
    }

    if mode == "after_n_reviews" {
        count = options.get("count", None);
        if isinstance(count, int) and not isinstance(count, bool) {
            if int(state["repeated_iterations"]) >= count {
                return {
                    "stop": True,
                    "run_status": RUN_STATUS_STOPPED_POLICY,
                    "reason": "after_n_reviews"
                };
            }
        }
    }

    if mode == "ask_before_continue" and int(state["repeated_iterations"]) > 0 {
        return {
            "stop": True,
            "run_status": RUN_STATUS_BLOCKED_MANUAL,
            "reason": "ask_before_continue",
            "pending_user_action": "approve_continue"
        };
    }

    return {"stop": False};
}

"""R: Execute a validated segmented compiled artifact with explicit segmented semantics.
M: Runs one_time once, repeats repeated as a unit, applies continuation between runs, and enforces stop policy on counters.
E: Empty one_time is valid; empty repeated exits cleanly with a documented stop reason.
"""
def execute_segmented_artifact(artifact: dict[str, any], payload: dict[str, any]) -> dict[str, any] {
    validation: dict[str, any] = validate_compiled_artifact(artifact);
    if not bool(validation.get("ok", False)) {
        return {
            "ok": False,
            "artifact_id": str(artifact.get("id", "")),
            "run_status": RUN_STATUS_FAILED,
            "error": "invalid segmented artifact",
            "errors": validation.get("errors", [])
        };
    }

    run_inputs: dict[str, any] = {};
    candidate_inputs = payload.get("inputs", {});
    if isinstance(candidate_inputs, dict) {
        run_inputs = candidate_inputs;
    }

    runtime: dict[str, any] = runtime_controls_from_payload(payload);
    state: dict[str, any] = new_execution_state(artifact);

    one_time_block: dict[str, any] = {};
    raw_one_time = artifact.get("one_time", {});
    if isinstance(raw_one_time, dict) {
        one_time_block = raw_one_time;
    }

    repeated_block: dict[str, any] = {};
    raw_repeated = artifact.get("repeated", {});
    if isinstance(raw_repeated, dict) {
        repeated_block = raw_repeated;
    }

    state["current_phase"] = PHASE_ONE_TIME;
    one_time_result: dict[str, any] = execute_segment_block(
        one_time_block,
        PHASE_ONE_TIME,
        0,
        run_inputs,
        state
    );
    state["one_time_completed"] = True;

    if not bool(one_time_result.get("ok", False)) {
        state["run_status"] = RUN_STATUS_FAILED;
        state["stop_reason"] = "one_time_failed";
        return {"ok": False, **state};
    }

    repeated_steps: list[any] = [];
    raw_repeated_steps = repeated_block.get("steps", []);
    if isinstance(raw_repeated_steps, list) {
        repeated_steps = raw_repeated_steps;
    }

    if len(repeated_steps) == 0 {
        state["current_phase"] = PHASE_FINISHED;
        state["run_status"] = RUN_STATUS_SUCCESS;
        state["stop_reason"] = "no_repeated_steps";
        state["warnings"].append("repeated segment is empty; no repeated iterations executed");
        return {"ok": True, **state};
    }

    max_iterations: int = int(runtime.get("max_repeated_iterations", DEFAULT_MAX_REPEATED_ITERATIONS));

    while True {
        if int(state["repeated_iterations"]) >= max_iterations {
            state["current_phase"] = PHASE_FINISHED;
            state["run_status"] = RUN_STATUS_PARTIAL;
            state["stop_reason"] = "max_iterations_guard";
            state["warnings"].append(
                "max_repeated_iterations guard reached at " + str(max_iterations)
            );
            return {"ok": True, **state};
        }

        iteration: int = int(state["repeated_iterations"]) + 1;
        state["current_phase"] = PHASE_REPEATED;

        repeated_result: dict[str, any] = execute_segment_block(
            repeated_block,
            PHASE_REPEATED,
            iteration,
            run_inputs,
            state
        );

        state["repeated_iterations"] = iteration;
        if bool(repeated_result.get("ok", False)) {
            state["successful_repeated_runs"] = state["successful_repeated_runs"] + 1;
        }

        stop_result: dict[str, any] = check_stop_policy(artifact, state);
        if bool(stop_result.get("stop", False)) {
            state["current_phase"] = PHASE_FINISHED;
            state["run_status"] = str(stop_result.get("run_status", RUN_STATUS_STOPPED_POLICY));
            state["stop_reason"] = str(stop_result.get("reason", ""));
            if stop_result.get("pending_user_action", "") {
                state["pending_user_action"] = str(stop_result.get("pending_user_action", ""));
            }
            return {"ok": True, **state};
        }

        state["current_phase"] = PHASE_CONTINUATION;
        continuation_result: dict[str, any] = apply_continuation_strategy(
            artifact,
            iteration,
            state,
            runtime
        );

        decision: str = str(continuation_result.get("decision", ""));
        if decision == "continue" {
            continue;
        }

        if decision == "blocked_manual" {
            state["run_status"] = RUN_STATUS_BLOCKED_MANUAL;
            state["stop_reason"] = str(continuation_result.get("reason", "manual_pick_next"));
            return {"ok": True, **state};
        }

        state["current_phase"] = PHASE_FINISHED;

        if decision == "stop" {
            state["run_status"] = RUN_STATUS_SUCCESS;
            state["stop_reason"] = str(continuation_result.get("reason", "continuation_stop"));
            return {"ok": True, **state};
        }

        if decision == "cannot_continue" {
            if str(state["stop_policy_mode"]) == "no_more_items" {
                state["run_status"] = RUN_STATUS_STOPPED_POLICY;
            } else {
                state["run_status"] = RUN_STATUS_SUCCESS;
            }
            state["stop_reason"] = str(continuation_result.get("reason", "no_more_items"));
            return {"ok": True, **state};
        }

        state["run_status"] = RUN_STATUS_FAILED;
        state["stop_reason"] = "unknown_continuation_decision";
        state["warnings"].append("unknown continuation decision: " + decision);
        return {"ok": False, **state};
    }

    state["current_phase"] = PHASE_FINISHED;
    state["run_status"] = RUN_STATUS_FAILED;
    state["stop_reason"] = "execution_loop_terminated_unexpectedly";
    state["warnings"].append("execution loop terminated unexpectedly");
    return {"ok": False, **state};
}

"""R: Load or accept one segmented artifact payload and execute it.
M: Supports inline `artifact` for tests and persisted `artifact_id`/`workflow_id` for CLI runs.
E: Flat workflows are rejected explicitly so the legacy planner path stays separate.
"""
def execute_segmented_payload(payload: dict[str, any]) -> dict[str, any] {
    artifact: dict[str, any] = {};

    inline_artifact: any = payload.get("artifact", {});
    if isinstance(inline_artifact, dict) and inline_artifact {
        artifact = inline_artifact;
    } else {
        artifact_id: str = str(payload.get("artifact_id", "") or payload.get("workflow_id", ""));
        if not artifact_id {
            return {"ok": False, "error": "artifact_id or payload.artifact is required"};
        }

        artifact = read_workflow(artifact_id);
        if not artifact {
            return {"ok": False, "error": "artifact not found", "artifact_id": artifact_id};
        }
    }

    if not is_segmented_artifact(artifact) {
        return {
            "ok": False,
            "artifact_id": str(artifact.get("id", "")),
            "error": "artifact is not segmented; use plan/dry_run for flat workflows"
        };
    }

    return execute_segmented_artifact(artifact, payload);
}

"""R: Route a layer command to flat planning or segmented execution operations.
M: Preserves `plan`/`dry_run` for flat workflows and adds explicit segmented execution commands.
E: Unknown commands return a usage payload.
"""
def dispatch(command: str, payload: dict[str, any]) -> dict[str, any] {
    if command == "plan" {
        return plan_workflow(payload);
    }

    if command == "dry_run" {
        return plan_workflow(payload);
    }

    if command == "execute" {
        return execute_segmented_payload(payload);
    }

    if command == "execute_segmented" {
        return execute_segmented_payload(payload);
    }

    if command == "dry_run_segmented" {
        return execute_segmented_payload(payload);
    }

    return {
        "ok": False,
        "error": "unknown command",
        "valid_commands": ["plan", "dry_run", "execute", "execute_segmented", "dry_run_segmented"]
    };
}

"""R: Decide whether this module should execute its CLI entrypoint.
M: Treats non-empty, non-path-like argv values as commands and ignores import-time script paths.
E: Unknown direct commands still dispatch so the caller gets the usual usage payload.
"""
def should_dispatch_cli(command: str) -> bool {
    if not command {
        return False;
    }

    return ("/" not in command) and ("\\" not in command) and not command.endswith(".jac");
}

with entry {
    command: str = "";
    if len(sys.argv) > 1 {
        command = str(sys.argv[1]);
    }

    if should_dispatch_cli(command) {
        payload = parse_payload();
        result = dispatch(command, payload);
        print(json.dumps(result));
    }
}
