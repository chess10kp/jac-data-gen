"""
Recording layer — state machine, data model, validation, and persistence tests.

Original tests cover 11 requirements (state machine + data model).
New tests cover 20 requirements (continuation/stop_policy validation + persistence):
  C1.  empty strategy list is accepted
  C2.  valid next_similar_item strategy is accepted
  C3.  valid scroll_for_more with scroll_style and max_scrolls is accepted
  C4.  valid next_page with button_hint and max_pages is accepted
  C5.  hybrid ordered strategy list is accepted
  C6.  unknown continuation mode is rejected
  C7.  malformed strategy entry is rejected
  C8.  invalid scroll_style is rejected
  C9.  non-positive max_scrolls is rejected
  C10. non-positive max_pages is rejected
  S1.  no_more_items is accepted
  S2.  ask_before_continue is accepted
  S3.  after_n_successes with positive count is accepted
  S4.  after_n_reviews with positive count is accepted
  S5.  unknown stop mode is rejected
  S6.  missing count for count-based mode is rejected
  S7.  non-positive count is rejected
  P1.  configure_continuation stores strategy on the recording
  P2.  configure_stop_policy stores stop_policy on the recording
  P3.  finishing after valid continuation/stop config still works

Run with:  jac run jac/recording_test.jac
All assertions print PASS on success; any failure prints FAIL with details.
"""

import from jac.layers.recording {
    transition_allowed,
    apply_transition,
    new_recording_session,
    active_segment,
    append_event_to_segment,
    append_annotation_to_segment,
    validate_continuation_strategy,
    validate_strategy_item,
    validate_stop_policy,
    cmd_create,
    cmd_enter_repeated,
    cmd_finish_repeated_example,
    cmd_configure_continuation,
    cmd_configure_stop_policy,
    cmd_finish,
    cmd_get
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

def assert_false(label: str, condition: bool) {
    assert_eq(label, condition, False);
}

# ============================================================
# Helper: build a minimal in-memory recording session
# ============================================================

def make_session(state: str) -> dict[str, any] {
    rec = new_recording_session("test task", {});
    rec["state"] = state;
    return rec;
}

# ============================================================
# Test 1 & 2: new session starts in idle, no mode auto-selected
# ============================================================

def test_new_session_starts_idle() {
    rec = new_recording_session("test task", {});
    assert_eq("1: new session state is idle", str(rec.get("state", "")), "idle");
    assert_eq("2: no mode auto-selected (state is idle, not one_time or repeated)",
        str(rec.get("state", "")) == "recording_one_time" or str(rec.get("state", "")) == "recording_repeated",
        False);
    assert_true("1: recording_id is present", bool(rec.get("recording_id", "")));
    assert_true("1: segments key exists", "segments" in rec);
    seg = rec.get("segments", {});
    assert_true("1: one_time segment exists", "one_time" in seg);
    assert_true("1: repeated segment exists", "repeated" in seg);
    assert_eq("1: one_time events start empty", rec["segments"]["one_time"]["events"], []);
    assert_eq("1: repeated events start empty", rec["segments"]["repeated"]["events"], []);
}

# ============================================================
# Test 3: entering one-time recording from idle
# ============================================================

def test_enter_one_time() {
    rec = make_session("idle");
    result = apply_transition(rec, "recording_one_time");
    assert_true("3: enter one_time from idle ok", bool(result.get("ok", False)));
    assert_eq("3: state is now recording_one_time", str(rec.get("state", "")), "recording_one_time");
    assert_eq("3: active segment is one_time", active_segment("recording_one_time"), "one_time");
}

# ============================================================
# Test 4: entering repeated recording from idle
# ============================================================

def test_enter_repeated_from_idle() {
    rec = make_session("idle");
    result = apply_transition(rec, "recording_repeated");
    assert_true("4: enter repeated from idle ok", bool(result.get("ok", False)));
    assert_eq("4: state is now recording_repeated", str(rec.get("state", "")), "recording_repeated");
    assert_eq("4: active segment is repeated", active_segment("recording_repeated"), "repeated");
}

# ============================================================
# Test 5: switching repeated -> one-time (correction path)
# ============================================================

def test_switch_repeated_to_one_time() {
    rec = make_session("recording_repeated");
    result = apply_transition(rec, "recording_one_time");
    assert_true("5: repeated -> one_time transition allowed", bool(result.get("ok", False)));
    assert_eq("5: state is now recording_one_time", str(rec.get("state", "")), "recording_one_time");

    # Also verify the reverse is NOT a correction path to idle (idle -> repeated_example_complete should fail)
    rec2 = make_session("idle");
    bad = apply_transition(rec2, "repeated_example_complete");
    assert_false("5: idle -> repeated_example_complete is blocked", bool(bad.get("ok", True)));
}

# ============================================================
# Test 6: one-time events go only into one_time.events
# ============================================================

def test_one_time_events_in_correct_segment() {
    rec = make_session("recording_one_time");
    evt: dict[str, any] = {"type": "click", "target": "button#login"};
    result = append_event_to_segment(rec, evt);
    assert_true("6: append event ok", bool(result.get("ok", False)));
    assert_eq("6: segment reported is one_time", str(result.get("segment", "")), "one_time");
    assert_eq("6: event_count is 1", result.get("event_count", 0), 1);

    ot_events = rec["segments"]["one_time"]["events"];
    rp_events = rec["segments"]["repeated"]["events"];
    assert_eq("6: one_time.events has 1 event", len(ot_events), 1);
    assert_eq("6: repeated.events still empty", len(rp_events), 0);
    assert_eq("6: event segment tag is one_time", str(ot_events[0].get("segment", "")), "one_time");
}

# ============================================================
# Test 7: repeated events go only into repeated.events
# ============================================================

def test_repeated_events_in_correct_segment() {
    rec = make_session("recording_repeated");
    evt: dict[str, any] = {"type": "navigate", "url": "https://example.com/list"};
    result = append_event_to_segment(rec, evt);
    assert_true("7: append event ok", bool(result.get("ok", False)));
    assert_eq("7: segment reported is repeated", str(result.get("segment", "")), "repeated");

    ot_events = rec["segments"]["one_time"]["events"];
    rp_events = rec["segments"]["repeated"]["events"];
    assert_eq("7: repeated.events has 1 event", len(rp_events), 1);
    assert_eq("7: one_time.events still empty", len(ot_events), 0);
    assert_eq("7: event segment tag is repeated", str(rp_events[0].get("segment", "")), "repeated");
}

# ============================================================
# Test 8: repeated annotations go only into repeated.annotations
# ============================================================

def test_repeated_annotations_in_correct_segment() {
    rec = make_session("recording_repeated");
    ann: dict[str, any] = {"note": "this is the list item loop", "kind": "loop_anchor"};
    result = append_annotation_to_segment(rec, ann);
    assert_true("8: append annotation ok", bool(result.get("ok", False)));
    assert_eq("8: segment reported is repeated", str(result.get("segment", "")), "repeated");

    ot_anns = rec["segments"]["one_time"]["annotations"];
    rp_anns = rec["segments"]["repeated"]["annotations"];
    assert_eq("8: repeated.annotations has 1 annotation", len(rp_anns), 1);
    assert_eq("8: one_time.annotations still empty", len(ot_anns), 0);
    assert_eq("8: annotation segment tag is repeated", str(rp_anns[0].get("segment", "")), "repeated");

    # Also verify one_time state puts annotations in one_time
    rec2 = make_session("recording_one_time");
    ann2: dict[str, any] = {"note": "setup step", "kind": "setup"};
    result2 = append_annotation_to_segment(rec2, ann2);
    assert_eq("8: one_time annotation segment tag", str(result2.get("segment", "")), "one_time");
    assert_eq("8: one_time.annotations has 1", len(rec2["segments"]["one_time"]["annotations"]), 1);
    assert_eq("8: repeated.annotations still empty", len(rec2["segments"]["repeated"]["annotations"]), 0);
}

# ============================================================
# Test 9: finishing repeated example moves to repeated_example_complete
# ============================================================

def test_finish_repeated_example() {
    rec = make_session("recording_repeated");
    result = apply_transition(rec, "repeated_example_complete");
    assert_true("9: finish repeated example ok", bool(result.get("ok", False)));
    assert_eq("9: state is repeated_example_complete", str(rec.get("state", "")), "repeated_example_complete");

    # Appending events after this should fail
    evt: dict[str, any] = {"type": "click"};
    bad = append_event_to_segment(rec, evt);
    assert_false("9: cannot append event after repeated_example_complete", bool(bad.get("ok", True)));
}

# ============================================================
# Test 10: continuation can be represented in the data structure
# ============================================================

def test_continuation_structure() {
    rec = new_recording_session("task with continuation", {});

    # Continuation placeholder exists from creation
    assert_true("10: continuation key exists at creation", "continuation" in rec);
    cont = rec.get("continuation", {});
    assert_true("10: continuation.strategy is a list", isinstance(cont.get("strategy", None), list));
    assert_eq("10: continuation.strategy starts empty", cont.get("strategy", None), []);

    # stop_policy placeholder exists
    assert_true("10: stop_policy key exists at creation", "stop_policy" in rec);
    sp = rec.get("stop_policy", {});
    assert_eq("10: stop_policy.mode starts empty", str(sp.get("mode", "")), "");

    # Can update continuation strategy in the dict
    rec["continuation"] = {"strategy": [{"kind": "next_page", "selector": "a.next"}]};
    strategy = rec["continuation"]["strategy"];
    assert_eq("10: continuation strategy can be set", len(strategy), 1);
    assert_eq("10: strategy entry kind", str(strategy[0].get("kind", "")), "next_page");
}

# ============================================================
# Test 11: finishing moves to finished
# ============================================================

def test_finish() {
    # Path via configuring_continuation
    rec = make_session("configuring_continuation");
    result = apply_transition(rec, "finished");
    assert_true("11: configuring_continuation -> finished ok", bool(result.get("ok", False)));
    assert_eq("11: state is finished", str(rec.get("state", "")), "finished");

    # Path via recording_one_time direct finish
    rec2 = make_session("recording_one_time");
    result2 = apply_transition(rec2, "finished");
    assert_true("11: recording_one_time -> finished ok", bool(result2.get("ok", False)));
    assert_eq("11: state is finished via one_time", str(rec2.get("state", "")), "finished");

    # finished -> anything should be blocked
    bad = apply_transition(rec, "idle");
    assert_false("11: finished -> idle is blocked", bool(bad.get("ok", True)));
}

# ============================================================
# Extra: invalid transition in idle state is blocked
# ============================================================

def test_invalid_transitions_blocked() {
    rec = make_session("idle");
    bad = apply_transition(rec, "finished");
    assert_false("extra: idle -> finished is blocked", bool(bad.get("ok", True)));
    assert_eq("extra: state unchanged after failed transition", str(rec.get("state", "")), "idle");

    bad2 = apply_transition(rec, "repeated_example_complete");
    assert_false("extra: idle -> repeated_example_complete is blocked", bool(bad2.get("ok", True)));

    # Append in idle state should fail
    evt: dict[str, any] = {"type": "click"};
    bad3 = append_event_to_segment(rec, evt);
    assert_false("extra: append event in idle state fails", bool(bad3.get("ok", True)));
}

# ============================================================
# Extra: segment ownership does not bleed between segments
# ============================================================

def test_segment_isolation() {
    rec = new_recording_session("isolation test", {});

    # Append to one_time
    apply_transition(rec, "recording_one_time");
    append_event_to_segment(rec, {"type": "click", "target": "btn-login"});
    append_event_to_segment(rec, {"type": "input", "value": "user@test.com"});

    # Switch to repeated
    apply_transition(rec, "recording_repeated");
    append_event_to_segment(rec, {"type": "navigate", "url": "https://example.com/feed"});
    append_annotation_to_segment(rec, {"note": "start of loop"});

    ot = rec["segments"]["one_time"];
    rp = rec["segments"]["repeated"];

    assert_eq("extra: one_time has 2 events", len(ot["events"]), 2);
    assert_eq("extra: repeated has 1 event", len(rp["events"]), 1);
    assert_eq("extra: one_time has 0 annotations", len(ot["annotations"]), 0);
    assert_eq("extra: repeated has 1 annotation", len(rp["annotations"]), 1);
}

# ============================================================
# Continuation validation tests (C1-C10)
# ============================================================

def test_continuation_empty_strategy_accepted() {
    result = validate_continuation_strategy([]);
    assert_true("C1: empty strategy list is accepted", bool(result.get("ok", False)));
}

def test_continuation_next_similar_item_accepted() {
    strategy: list[any] = [{"mode": "next_similar_item", "options": {}}];
    result = validate_continuation_strategy(strategy);
    assert_true("C2: next_similar_item with empty options is accepted", bool(result.get("ok", False)));
}

def test_continuation_scroll_for_more_accepted() {
    strategy: list[any] = [
        {"mode": "scroll_for_more", "options": {"scroll_style": "partial", "max_scrolls": 3}}
    ];
    result = validate_continuation_strategy(strategy);
    assert_true("C3: scroll_for_more with scroll_style and max_scrolls is accepted", bool(result.get("ok", False)));
}

def test_continuation_next_page_accepted() {
    strategy: list[any] = [
        {"mode": "next_page", "options": {"button_hint": "Next", "max_pages": 20}}
    ];
    result = validate_continuation_strategy(strategy);
    assert_true("C4: next_page with button_hint and max_pages is accepted", bool(result.get("ok", False)));
}

def test_continuation_hybrid_strategy_accepted() {
    strategy: list[any] = [
        {"mode": "next_similar_item", "options": {}},
        {"mode": "scroll_for_more", "options": {"scroll_style": "viewport", "max_scrolls": 5}},
        {"mode": "next_page", "options": {"button_hint": "Load More", "max_pages": 10}},
        {"mode": "manual_pick_next", "options": {}},
        {"mode": "stop", "options": {}}
    ];
    result = validate_continuation_strategy(strategy);
    assert_true("C5: hybrid ordered strategy list is accepted", bool(result.get("ok", False)));
}

def test_continuation_unknown_mode_rejected() {
    strategy: list[any] = [{"mode": "teleport_to_next_item", "options": {}}];
    result = validate_continuation_strategy(strategy);
    assert_false("C6: unknown continuation mode is rejected", bool(result.get("ok", True)));
    assert_true("C6: error mentions unknown mode", "unknown" in str(result.get("error", "")));
}

def test_continuation_malformed_entry_rejected() {
    # A string instead of a dict
    strategy: list[any] = ["scroll_for_more"];
    result = validate_continuation_strategy(strategy);
    assert_false("C7: non-dict strategy entry is rejected", bool(result.get("ok", True)));

    # Missing options key
    strategy2: list[any] = [{"mode": "next_page"}];
    result2 = validate_continuation_strategy(strategy2);
    assert_false("C7: entry missing options key is rejected", bool(result2.get("ok", True)));

    # Missing mode key
    strategy3: list[any] = [{"options": {}}];
    result3 = validate_continuation_strategy(strategy3);
    assert_false("C7: entry missing mode key is rejected", bool(result3.get("ok", True)));
}

def test_continuation_invalid_scroll_style_rejected() {
    strategy: list[any] = [{"mode": "scroll_for_more", "options": {"scroll_style": "infinite"}}];
    result = validate_continuation_strategy(strategy);
    assert_false("C8: invalid scroll_style is rejected", bool(result.get("ok", True)));
    assert_true("C8: error mentions scroll_style", "scroll_style" in str(result.get("error", "")));
}

def test_continuation_non_positive_max_scrolls_rejected() {
    strategy_zero: list[any] = [{"mode": "scroll_for_more", "options": {"max_scrolls": 0}}];
    result_zero = validate_continuation_strategy(strategy_zero);
    assert_false("C9: max_scrolls=0 is rejected", bool(result_zero.get("ok", True)));

    strategy_neg: list[any] = [{"mode": "scroll_for_more", "options": {"max_scrolls": -1}}];
    result_neg = validate_continuation_strategy(strategy_neg);
    assert_false("C9: max_scrolls=-1 is rejected", bool(result_neg.get("ok", True)));
}

def test_continuation_non_positive_max_pages_rejected() {
    strategy_zero: list[any] = [{"mode": "next_page", "options": {"max_pages": 0}}];
    result_zero = validate_continuation_strategy(strategy_zero);
    assert_false("C10: max_pages=0 is rejected", bool(result_zero.get("ok", True)));

    strategy_neg: list[any] = [{"mode": "next_page", "options": {"max_pages": -5}}];
    result_neg = validate_continuation_strategy(strategy_neg);
    assert_false("C10: max_pages=-5 is rejected", bool(result_neg.get("ok", True)));
}

# ============================================================
# Stop policy validation tests (S1-S7)
# ============================================================

def test_stop_policy_no_more_items_accepted() {
    sp: dict[str, any] = {"mode": "no_more_items", "options": {}};
    result = validate_stop_policy(sp);
    assert_true("S1: no_more_items is accepted", bool(result.get("ok", False)));
}

def test_stop_policy_ask_before_continue_accepted() {
    sp: dict[str, any] = {"mode": "ask_before_continue", "options": {}};
    result = validate_stop_policy(sp);
    assert_true("S2: ask_before_continue is accepted", bool(result.get("ok", False)));
}

def test_stop_policy_after_n_successes_accepted() {
    sp: dict[str, any] = {"mode": "after_n_successes", "options": {"count": 20}};
    result = validate_stop_policy(sp);
    assert_true("S3: after_n_successes with positive count is accepted", bool(result.get("ok", False)));
}

def test_stop_policy_after_n_reviews_accepted() {
    sp: dict[str, any] = {"mode": "after_n_reviews", "options": {"count": 5}};
    result = validate_stop_policy(sp);
    assert_true("S4: after_n_reviews with positive count is accepted", bool(result.get("ok", False)));
}

def test_stop_policy_unknown_mode_rejected() {
    sp: dict[str, any] = {"mode": "after_coffee_break", "options": {}};
    result = validate_stop_policy(sp);
    assert_false("S5: unknown stop mode is rejected", bool(result.get("ok", True)));
    assert_true("S5: error mentions unknown mode", "unknown" in str(result.get("error", "")));
}

def test_stop_policy_missing_count_rejected() {
    sp_no_count: dict[str, any] = {"mode": "after_n_successes", "options": {}};
    result = validate_stop_policy(sp_no_count);
    assert_false("S6: after_n_successes without count is rejected", bool(result.get("ok", True)));
    assert_true("S6: error mentions count", "count" in str(result.get("error", "")));

    sp_no_count2: dict[str, any] = {"mode": "after_n_reviews", "options": {}};
    result2 = validate_stop_policy(sp_no_count2);
    assert_false("S6: after_n_reviews without count is rejected", bool(result2.get("ok", True)));
}

def test_stop_policy_non_positive_count_rejected() {
    sp_zero: dict[str, any] = {"mode": "after_n_successes", "options": {"count": 0}};
    result_zero = validate_stop_policy(sp_zero);
    assert_false("S7: count=0 is rejected", bool(result_zero.get("ok", True)));

    sp_neg: dict[str, any] = {"mode": "after_n_reviews", "options": {"count": -3}};
    result_neg = validate_stop_policy(sp_neg);
    assert_false("S7: count=-3 is rejected", bool(result_neg.get("ok", True)));
}

# ============================================================
# Persistence tests (P1-P3) — use real cmd handlers + disk I/O
# ============================================================

def setup_recording_at_configuring() -> str {
    # Creates a recording and drives it to configuring_continuation state
    create_result = cmd_create({"task_name": "persistence test"});
    rec_id: str = str(create_result.get("recording_id", ""));

    cmd_enter_repeated({"recording_id": rec_id});
    cmd_finish_repeated_example({"recording_id": rec_id});
    # configure_continuation transitions repeated_example_complete -> configuring_continuation
    cmd_configure_continuation({"recording_id": rec_id, "strategy": []});
    return rec_id;
}

def test_persistence_configure_continuation_stores_strategy() {
    rec_id = setup_recording_at_configuring();

    strategy: list[any] = [
        {"mode": "next_similar_item", "options": {}},
        {"mode": "next_page", "options": {"button_hint": "Next", "max_pages": 10}}
    ];
    result = cmd_configure_continuation({"recording_id": rec_id, "strategy": strategy});
    assert_true("P1: configure_continuation returns ok", bool(result.get("ok", False)));

    get_result = cmd_get({"recording_id": rec_id});
    assert_true("P1: cmd_get returns ok", bool(get_result.get("ok", False)));

    rec: dict[str, any] = get_result.get("recording", {});
    stored_cont: dict[str, any] = rec.get("continuation", {});
    stored_strategy: list[any] = stored_cont.get("strategy", []);
    assert_eq("P1: strategy has 2 entries after configure", len(stored_strategy), 2);
    assert_eq("P1: first strategy mode is next_similar_item", str(stored_strategy[0].get("mode", "")), "next_similar_item");
    assert_eq("P1: second strategy mode is next_page", str(stored_strategy[1].get("mode", "")), "next_page");
    assert_eq("P1: state is configuring_continuation", str(rec.get("state", "")), "configuring_continuation");
}

def test_persistence_configure_stop_policy_stores_stop_policy() {
    rec_id = setup_recording_at_configuring();

    sp: dict[str, any] = {"mode": "after_n_successes", "options": {"count": 15}};
    result = cmd_configure_stop_policy({"recording_id": rec_id, "stop_policy": sp});
    assert_true("P2: configure_stop_policy returns ok", bool(result.get("ok", False)));

    get_result = cmd_get({"recording_id": rec_id});
    assert_true("P2: cmd_get returns ok", bool(get_result.get("ok", False)));

    rec: dict[str, any] = get_result.get("recording", {});
    stored_sp: dict[str, any] = rec.get("stop_policy", {});
    assert_eq("P2: stop_policy mode is stored", str(stored_sp.get("mode", "")), "after_n_successes");
    stored_options: dict[str, any] = stored_sp.get("options", {});
    assert_eq("P2: stop_policy count is stored", stored_options.get("count", 0), 15);
    assert_eq("P2: state remains configuring_continuation", str(rec.get("state", "")), "configuring_continuation");
}

def test_persistence_finish_after_continuation_config() {
    rec_id = setup_recording_at_configuring();

    strategy: list[any] = [{"mode": "scroll_for_more", "options": {"scroll_style": "until_new_items"}}];
    cmd_configure_continuation({"recording_id": rec_id, "strategy": strategy});

    sp: dict[str, any] = {"mode": "no_more_items", "options": {}};
    cmd_configure_stop_policy({"recording_id": rec_id, "stop_policy": sp});

    finish_result = cmd_finish({"recording_id": rec_id});
    assert_true("P3: finish after continuation+stop config returns ok", bool(finish_result.get("ok", False)));
    assert_eq("P3: state is finished", str(finish_result.get("state", "")), "finished");

    get_result = cmd_get({"recording_id": rec_id});
    rec: dict[str, any] = get_result.get("recording", {});
    assert_eq("P3: persisted state is finished", str(rec.get("state", "")), "finished");

    stored_cont: dict[str, any] = rec.get("continuation", {});
    stored_strategy: list[any] = stored_cont.get("strategy", []);
    assert_eq("P3: strategy still stored after finish", len(stored_strategy), 1);

    stored_sp: dict[str, any] = rec.get("stop_policy", {});
    assert_eq("P3: stop_policy still stored after finish", str(stored_sp.get("mode", "")), "no_more_items");
}

# ============================================================
# Run all tests
# ============================================================

with entry {
    test_new_session_starts_idle();
    test_enter_one_time();
    test_enter_repeated_from_idle();
    test_switch_repeated_to_one_time();
    test_one_time_events_in_correct_segment();
    test_repeated_events_in_correct_segment();
    test_repeated_annotations_in_correct_segment();
    test_finish_repeated_example();
    test_continuation_structure();
    test_finish();
    test_invalid_transitions_blocked();
    test_segment_isolation();

    print("");
    print("--- Continuation validation ---");
    test_continuation_empty_strategy_accepted();
    test_continuation_next_similar_item_accepted();
    test_continuation_scroll_for_more_accepted();
    test_continuation_next_page_accepted();
    test_continuation_hybrid_strategy_accepted();
    test_continuation_unknown_mode_rejected();
    test_continuation_malformed_entry_rejected();
    test_continuation_invalid_scroll_style_rejected();
    test_continuation_non_positive_max_scrolls_rejected();
    test_continuation_non_positive_max_pages_rejected();

    print("");
    print("--- Stop policy validation ---");
    test_stop_policy_no_more_items_accepted();
    test_stop_policy_ask_before_continue_accepted();
    test_stop_policy_after_n_successes_accepted();
    test_stop_policy_after_n_reviews_accepted();
    test_stop_policy_unknown_mode_rejected();
    test_stop_policy_missing_count_rejected();
    test_stop_policy_non_positive_count_rejected();

    print("");
    print("--- Persistence ---");
    test_persistence_configure_continuation_stores_strategy();
    test_persistence_configure_stop_policy_stores_stop_policy();
    test_persistence_finish_after_continuation_config();

    print("");
    print("Results: " + str(COUNTS["passed"]) + " passed, " + str(COUNTS["failed"]) + " failed.");
    if COUNTS["failed"] > 0 {
        print("SOME TESTS FAILED");
    } else {
        print("ALL TESTS PASSED");
    }
}
