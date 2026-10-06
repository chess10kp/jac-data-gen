"""
Jac execution layer tests for segmented runtime behavior.

Run with:  jac run jac/execution_test.jac
All assertions print PASS on success; any failure prints FAIL and the summary shows the count.
"""

import from jac.layers.execution {
    build_plan,
    execute_segmented_artifact
}

glob COUNTS: dict[str, int] = {"passed": 0, "failed": 0};

def assert_eq(label: str, got: any, expected: any) {
    if got == expected {
        COUNTS["passed"] = COUNTS["passed"] + 1;
        print("PASS  " + label);
    } else {
        COUNTS["failed"] = COUNTS["failed"] + 1;
        print("FAIL  " + label);
        print("      got:      " + str(got));
        print("      expected: " + str(expected));
    }
}

def assert_true(label: str, condition: bool) {
    assert_eq(label, condition, True);
}

"""R: Build a minimal valid segmented artifact for execution-layer tests.
M: Fills the required compiled-artifact contract while allowing each test to vary steps and policies.
E: Uses explicit ids so tests can detect leakage between one_time and repeated phases.
"""
def mk_artifact(
    one_time_steps: list[any],
    repeated_steps: list[any],
    continuation_strategy: list[any],
    stop_policy: dict[str, any]
) -> dict[str, any] {
    return {
        "version": "1.0",
        "id": "wf_exec_test",
        "name": "Execution test workflow",
        "recording_id": "rec_exec_test",
        "metadata": {
            "createdAt": "2026-04-04T00:00:00Z",
            "updatedAt": "2026-04-04T00:00:00Z",
            "createdByUserId": "user_test",
            "source": {
                "recordingId": "rec_exec_test",
                "origin": "segmented-recording",
                "startUrl": "https://example.com",
                "domains": ["example.com"]
            }
        },
        "one_time": {
            "inputs": [],
            "steps": one_time_steps,
            "annotations": [],
            "safety_rules": []
        },
        "repeated": {
            "inputs": [],
            "steps": repeated_steps,
            "annotations": [],
            "safety_rules": []
        },
        "continuation": {
            "strategy": continuation_strategy
        },
        "stop_policy": stop_policy,
        "compileInfo": {
            "compilerVersion": "0.2.0",
            "compiledAt": "2026-04-04T00:00:00Z",
            "sourceRecordingId": "rec_exec_test"
        }
    };
}

def mk_click_step(step_id: str, selector: str) -> dict[str, any] {
    return {
        "id": step_id,
        "type": "click",
        "target": {
            "primary": {
                "kind": "css",
                "selector": selector
            }
        }
    };
}

def mk_fill_input_step(step_id: str, input_key: str) -> dict[str, any] {
    return {
        "id": step_id,
        "type": "fill",
        "target": {
            "primary": {
                "kind": "label",
                "label": "Value"
            }
        },
        "value_source": "input." + input_key
    };
}

"""R: Count emitted step results for one phase in a run result.
M: Filters `step_results` by the stored phase field.
E: Missing or malformed step_results return 0.
"""
def count_phase_steps(result: dict[str, any], phase: str) -> int {
    raw: any = result.get("step_results", []);
    if not isinstance(raw, list) {
        return 0;
    }

    return len([
        item for item in raw
        if isinstance(item, dict) and str(item.get("phase", "")) == phase
    ]);
}

"""R: Collect step ids for one phase so tests can detect cross-phase leakage.
M: Filters the recorded step results and extracts each step_id in execution order.
E: Missing or malformed step_results return an empty list.
"""
def phase_step_ids(result: dict[str, any], phase: str) -> list[str] {
    raw: any = result.get("step_results", []);
    if not isinstance(raw, list) {
        return [];
    }

    return [
        str(item.get("step_id", ""))
        for item in raw
        if isinstance(item, dict) and str(item.get("phase", "")) == phase
    ];
}

glob STOP_NO_MORE_ITEMS: dict[str, any] = {"mode": "no_more_items", "options": {}};

def test_only_one_time_executes_once() {
    artifact: dict[str, any] = mk_artifact(
        [mk_click_step("ot_click", "#login")],
        [],
        [{"mode": "stop", "options": {}}],
        STOP_NO_MORE_ITEMS
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_true("exec1: result ok", bool(result.get("ok", False)));
    assert_eq("exec1: one_time marked complete", bool(result.get("one_time_completed", False)), True);
    assert_eq("exec1: repeated_iterations is 0", result.get("repeated_iterations", 0), 0);
    assert_eq("exec1: one_time emitted 1 step result", count_phase_steps(result, "one_time"), 1);
    assert_eq("exec1: run_status is success", str(result.get("run_status", "")), "success");
}

def test_only_repeated_executes_one_iteration() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_click_step("rep_click", "#item")],
        [{"mode": "next_similar_item", "options": {}}],
        STOP_NO_MORE_ITEMS
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_true("exec2: result ok", bool(result.get("ok", False)));
    assert_eq("exec2: one_time empty is still completed", bool(result.get("one_time_completed", False)), True);
    assert_eq("exec2: repeated_iterations is 1", result.get("repeated_iterations", 0), 1);
    assert_eq("exec2: successful_repeated_runs is 1", result.get("successful_repeated_runs", 0), 1);
    assert_eq("exec2: repeated emitted 1 step result", count_phase_steps(result, "repeated"), 1);
}

def test_one_time_does_not_repeat_across_iterations() {
    artifact: dict[str, any] = mk_artifact(
        [mk_click_step("ot_login", "#login")],
        [mk_click_step("rep_item", "#item")],
        [{"mode": "next_similar_item", "options": {}}],
        {"mode": "after_n_reviews", "options": {"count": 3}}
    );
    payload: dict[str, any] = {
        "traversal_results": {
            "next_similar_item": [
                {"advanced": True},
                {"advanced": True}
            ]
        }
    };
    result: dict[str, any] = execute_segmented_artifact(artifact, payload);
    assert_true("exec3: result ok", bool(result.get("ok", False)));
    assert_eq("exec3: repeated_iterations is 3", result.get("repeated_iterations", 0), 3);
    assert_eq("exec3: one_time emitted once total", count_phase_steps(result, "one_time"), 1);
}

def test_repeated_block_repeats_across_iterations() {
    artifact: dict[str, any] = mk_artifact(
        [mk_click_step("ot_login", "#login")],
        [mk_click_step("rep_item", "#item")],
        [{"mode": "next_similar_item", "options": {}}],
        {"mode": "after_n_reviews", "options": {"count": 3}}
    );
    payload: dict[str, any] = {
        "traversal_results": {
            "next_similar_item": [
                {"advanced": True},
                {"advanced": True}
            ]
        }
    };
    result: dict[str, any] = execute_segmented_artifact(artifact, payload);
    assert_eq("exec4: repeated emitted once per iteration", count_phase_steps(result, "repeated"), 3);
    assert_eq("exec4: successful_repeated_runs is 3", result.get("successful_repeated_runs", 0), 3);
}

def test_continuation_stop_ends_cleanly() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_click_step("rep_stop", "#stop")],
        [{"mode": "stop", "options": {}}],
        STOP_NO_MORE_ITEMS
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_eq("exec5: run_status is success", str(result.get("run_status", "")), "success");
    assert_eq("exec5: stop reason is continuation_stop", str(result.get("stop_reason", "")), "continuation_stop");
    assert_eq("exec5: repeated_iterations is 1", result.get("repeated_iterations", 0), 1);
}

def test_manual_pick_next_blocks() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_click_step("rep_manual", "#manual")],
        [{"mode": "manual_pick_next", "options": {}}],
        STOP_NO_MORE_ITEMS
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_eq("exec6: run_status is blocked_manual", str(result.get("run_status", "")), "blocked_manual");
    assert_eq("exec6: stop_reason is manual_pick_next", str(result.get("stop_reason", "")), "manual_pick_next");
    assert_eq("exec6: pending action recorded", str(result.get("pending_user_action", "")), "manual_pick_next");
}

def test_after_n_successes_stops_on_success_count() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_click_step("rep_success", "#success")],
        [{"mode": "next_similar_item", "options": {}}],
        {"mode": "after_n_successes", "options": {"count": 2}}
    );
    payload: dict[str, any] = {
        "traversal_results": {
            "next_similar_item": [
                {"advanced": True}
            ]
        }
    };
    result: dict[str, any] = execute_segmented_artifact(artifact, payload);
    assert_eq("exec7: run_status is stopped_policy", str(result.get("run_status", "")), "stopped_policy");
    assert_eq("exec7: stop_reason is after_n_successes", str(result.get("stop_reason", "")), "after_n_successes");
    assert_eq("exec7: repeated_iterations is 2", result.get("repeated_iterations", 0), 2);
    assert_eq("exec7: successful_repeated_runs is 2", result.get("successful_repeated_runs", 0), 2);
}

def test_after_n_reviews_uses_iteration_count() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_fill_input_step("rep_fill", "missing_review_input")],
        [{"mode": "next_similar_item", "options": {}}],
        {"mode": "after_n_reviews", "options": {"count": 2}}
    );
    payload: dict[str, any] = {
        "traversal_results": {
            "next_similar_item": [
                {"advanced": True}
            ]
        }
    };
    result: dict[str, any] = execute_segmented_artifact(artifact, payload);
    assert_eq("exec8: run_status is stopped_policy", str(result.get("run_status", "")), "stopped_policy");
    assert_eq("exec8: stop_reason is after_n_reviews", str(result.get("stop_reason", "")), "after_n_reviews");
    assert_eq("exec8: repeated_iterations is 2", result.get("repeated_iterations", 0), 2);
    assert_eq("exec8: successful_repeated_runs stays 0", result.get("successful_repeated_runs", 0), 0);
}

def test_no_more_items_stops_when_continuation_exhausts() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_click_step("rep_item", "#item")],
        [{"mode": "next_similar_item", "options": {}}],
        STOP_NO_MORE_ITEMS
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_eq("exec9: run_status is stopped_policy", str(result.get("run_status", "")), "stopped_policy");
    assert_eq("exec9: stop_reason is no_more_items", str(result.get("stop_reason", "")), "no_more_items");
    assert_eq("exec9: continuation_attempts is 1", result.get("continuation_attempts", 0), 1);
}

def test_continuation_and_stop_policy_are_reflected() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_click_step("rep_page", "#page")],
        [{"mode": "next_page", "options": {"max_pages": 2}}],
        {"mode": "after_n_reviews", "options": {"count": 1}}
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_eq("exec10: continuation strategy reflects next_page", result.get("continuation_strategy", []), ["next_page"]);
    assert_eq("exec10: stop policy mode reflected", str(result.get("stop_policy_mode", "")), "after_n_reviews");
}

def test_empty_one_time_is_valid() {
    artifact: dict[str, any] = mk_artifact(
        [],
        [mk_click_step("rep_empty_ot", "#item")],
        [{"mode": "stop", "options": {}}],
        STOP_NO_MORE_ITEMS
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_true("exec11: result ok", bool(result.get("ok", False)));
    assert_eq("exec11: one_time emitted 0 step results", count_phase_steps(result, "one_time"), 0);
    assert_eq("exec11: one_time still completed", bool(result.get("one_time_completed", False)), True);
}

def test_empty_repeated_is_predictable() {
    artifact: dict[str, any] = mk_artifact(
        [mk_click_step("ot_only", "#only")],
        [],
        [{"mode": "next_similar_item", "options": {}}],
        STOP_NO_MORE_ITEMS
    );
    result: dict[str, any] = execute_segmented_artifact(artifact, {});
    assert_eq("exec12: run_status is success", str(result.get("run_status", "")), "success");
    assert_eq("exec12: stop_reason is no_repeated_steps", str(result.get("stop_reason", "")), "no_repeated_steps");
    assert_eq("exec12: repeated_iterations is 0", result.get("repeated_iterations", 0), 0);
}

def test_segmented_execution_has_no_phase_leakage() {
    artifact: dict[str, any] = mk_artifact(
        [mk_click_step("ot_unique", "#login")],
        [mk_click_step("rep_unique", "#item")],
        [{"mode": "next_similar_item", "options": {}}],
        {"mode": "after_n_reviews", "options": {"count": 2}}
    );
    payload: dict[str, any] = {
        "traversal_results": {
            "next_similar_item": [
                {"advanced": True}
            ]
        }
    };
    result: dict[str, any] = execute_segmented_artifact(artifact, payload);
    assert_eq("exec13: one_time step ids stay isolated", phase_step_ids(result, "one_time"), ["ot_unique"]);
    assert_eq("exec13: repeated step ids stay isolated", phase_step_ids(result, "repeated"), ["rep_unique", "rep_unique"]);
}

def test_flat_planner_path_is_preserved() {
    workflow: dict[str, any] = {
        "id": "wf_flat_test",
        "steps": [
            {"id": "goto_1", "type": "goto", "url": "https://example.com"},
            {"id": "fill_1", "type": "fill", "value_source": "input.query"}
        ]
    };
    plan: dict[str, any] = build_plan(workflow, {});
    assert_eq("exec14: flat plan still returns 2 planned steps", len(plan.get("planned_steps", [])), 2);
    assert_eq("exec14: flat plan still tracks unresolved inputs", plan.get("unresolved_inputs", []), ["query"]);
}

with entry {
    test_only_one_time_executes_once();
    test_only_repeated_executes_one_iteration();
    test_one_time_does_not_repeat_across_iterations();
    test_repeated_block_repeats_across_iterations();
    test_continuation_stop_ends_cleanly();
    test_manual_pick_next_blocks();
    test_after_n_successes_stops_on_success_count();
    test_after_n_reviews_uses_iteration_count();
    test_no_more_items_stops_when_continuation_exhausts();
    test_continuation_and_stop_policy_are_reflected();
    test_empty_one_time_is_valid();
    test_empty_repeated_is_predictable();
    test_segmented_execution_has_no_phase_leakage();
    test_flat_planner_path_is_preserved();

    print("");
    print("Results: " + str(COUNTS["passed"]) + " passed, " + str(COUNTS["failed"]) + " failed.");
    if COUNTS["failed"] > 0 {
        print("SOME TESTS FAILED");
    }
    if COUNTS["failed"] == 0 {
        print("ALL TESTS PASSED");
    }
}
