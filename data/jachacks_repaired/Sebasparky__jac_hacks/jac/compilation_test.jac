"""
Jac compilation layer — manual tests.
Mirrors the semantics verified by src/__tests__/compilation/cleaner.test.ts
and src/__tests__/compilation/compiler.test.ts.

Run with:  jac run jac/compilation_test.jac
All assertions print PASS on success; any failure prints FAIL and halts.
"""

import from jac.layers.compilation {
    remove_noise,
    merge_typing_events,
    collapse_duplicate_clicks,
    infer_inputs,
    infer_assertions,
    infer_safety_rules,
    event_to_step,
    compile_session,
    validate_workflow,
    compile_segmented_recording,
    validate_compiled_artifact
}
import from jac.llm.kimi_client {
    build_kimi_compile_request,
    build_ollama_chat_request,
    build_kimi_cli_prompt,
    parse_json_object_text
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

glob T0: int = 1000000000000;

def ts(offset: int) -> str {
    sec: int = (T0 + offset) // 1000;
    ms: int = (T0 + offset) % 1000;
    # Approximate: use epoch + sec as a rough ISO string (good enough for deltas)
    import time;
    t: any = time.gmtime(sec);
    base: str = time.strftime("%Y-%m-%dT%H:%M:%S", t);
    ms_str: str = str(ms).zfill(3);
    return base + "." + ms_str + "Z";
}

def mk_input(name: str, value: str, offset: int, el_overrides: dict[str, any] = {}) -> dict[str, any] {
    el: dict[str, any] = {"tag": "input", "name": name};
    for (k, v) in el_overrides.items() {
        el[k] = v;
    }
    return {
        "id": "evt_" + name + "_" + str(offset),
        "sessionId": "sess_1",
        "url": "https://example.com",
        "timestamp": ts(offset),
        "type": "input",
        "element": el,
        "value": value,
        "masked": False
    };
}

def mk_click(element_id: str, offset: int) -> dict[str, any] {
    return {
        "id": "evt_click_" + element_id + "_" + str(offset),
        "sessionId": "sess_1",
        "url": "https://example.com",
        "timestamp": ts(offset),
        "type": "click",
        "element": {"tag": "button", "id": element_id}
    };
}

def mk_nav(url: str, offset: int) -> dict[str, any] {
    return {
        "id": "evt_nav_" + str(offset),
        "sessionId": "sess_1",
        "url": url,
        "timestamp": ts(offset),
        "type": "navigation",
        "previousUrl": "https://example.com",
        "trigger": "link_click"
    };
}

def mk_focus(element_id: str, offset: int) -> dict[str, any] {
    return {
        "id": "evt_focus_" + element_id + "_" + str(offset),
        "sessionId": "sess_1",
        "url": "https://example.com",
        "timestamp": ts(offset),
        "type": "focus",
        "element": {"tag": "input", "id": element_id}
    };
}

def mk_blur(element_id: str, offset: int) -> dict[str, any] {
    return {
        "id": "evt_blur_" + element_id + "_" + str(offset),
        "sessionId": "sess_1",
        "url": "https://example.com",
        "timestamp": ts(offset),
        "type": "blur",
        "element": {"tag": "input", "id": element_id}
    };
}

glob DEFAULT_PRIVACY: dict[str, any] = {
    "mode": "local",
    "llmUsage": {
        "allowDuringCompile": False,
        "allowDuringRepair": False,
        "allowRawDomInRepair": False
    }
};

glob DEFAULT_OPTIONS: dict[str, any] = {
    "createdByUserId": "user_test",
    "privacy": DEFAULT_PRIVACY
};

# ============================================================
# merge_typing_events
# ============================================================

def test_merge_typing_events() {
    # Collapses consecutive same-element inputs to last value
    evts: list[any] = [
        mk_input("email", "a", 0),
        mk_input("email", "ab", 100),
        mk_input("email", "abc", 200)
    ];
    r: list[any] = merge_typing_events(evts);
    assert_eq("merge: 3 keystrokes collapse to 1", len(r), 1);
    assert_eq("merge: final value preserved", str(r[0].get("value", "")), "abc");

    # Different elements produce separate entries
    evts2: list[any] = [
        mk_input("first_name", "Jo", 0),
        mk_input("last_name", "Sm", 100),
        mk_input("last_name", "Smith", 200)
    ];
    r2: list[any] = merge_typing_events(evts2);
    assert_eq("merge: different elements kept separate", len(r2), 2);
    assert_eq("merge: second field final value", str(r2[1].get("value", "")), "Smith");

    # Non-input events between two same-field inputs break the run
    evts3: list[any] = [
        mk_input("email", "a", 0),
        mk_click("btn", 150),
        mk_input("email", "b", 300)
    ];
    r3: list[any] = merge_typing_events(evts3);
    assert_eq("merge: run broken by intervening click", len(r3), 3);

    # Empty array handled
    assert_eq("merge: empty array", len(merge_typing_events([])), 0);
}

# ============================================================
# collapse_duplicate_clicks
# ============================================================

def test_collapse_duplicate_clicks() {
    # Same element within 300ms — second dropped
    evts: list[any] = [mk_click("btn-submit", 0), mk_click("btn-submit", 200)];
    r: list[any] = collapse_duplicate_clicks(evts);
    assert_eq("collapse: second click within 300ms dropped", len(r), 1);

    # Same element >300ms apart — both kept
    evts2: list[any] = [mk_click("btn-submit", 0), mk_click("btn-submit", 400)];
    assert_eq("collapse: clicks >300ms apart both kept", len(collapse_duplicate_clicks(evts2)), 2);

    # Different elements — both kept even if close
    evts3: list[any] = [mk_click("btn-a", 0), mk_click("btn-b", 50)];
    assert_eq("collapse: different elements both kept", len(collapse_duplicate_clicks(evts3)), 2);

    # Same element within 300ms with intervening nav — second still dropped
    evts4: list[any] = [mk_click("btn-submit", 0), mk_nav("https://x.com/2", 100), mk_click("btn-submit", 200)];
    r4: list[any] = collapse_duplicate_clicks(evts4);
    assert_eq("collapse: intervening nav doesn't reset window, second click dropped", len(r4), 2);
    click_count: int = len([e for e in r4 if isinstance(e, dict) and e.get("type") == "click"]);
    assert_eq("collapse: exactly 1 click remains", click_count, 1);
}

# ============================================================
# remove_noise
# ============================================================

def test_remove_noise() {
    # Orphan focus removed
    focus: dict[str, any] = mk_focus("orphan", 0);
    r: dict[str, any] = remove_noise([focus]);
    assert_eq("noise: orphan focus removed", len(r["events"]), 0);
    assert_eq("noise: orphan focus logged", len(r["removed"]), 1);

    # Focus on element that also has input — kept
    inp: dict[str, any] = mk_input("username", "alice", 100, {"id": "username-field"});
    focus2: dict[str, any] = mk_focus("username-field", 0);
    r2: dict[str, any] = remove_noise([focus2, inp]);
    focus_ids: list[str] = [str(e.get("id", "")) for e in r2["events"]];
    assert_true("noise: focus with input kept", focus2["id"] in focus_ids);

    # Orphan blur removed
    blur: dict[str, any] = mk_blur("orphan", 0);
    r3: dict[str, any] = remove_noise([blur]);
    assert_eq("noise: orphan blur removed", len(r3["events"]), 0);

    # Duplicate nav within 500ms — second dropped
    nav1: dict[str, any] = mk_nav("https://example.com/page", 0);
    nav2: dict[str, any] = mk_nav("https://example.com/page", 300);
    r4: dict[str, any] = remove_noise([nav1, nav2]);
    assert_eq("noise: dup nav within 500ms dropped", len(r4["events"]), 1);
    assert_eq("noise: second nav logged as removed", str(r4["removed"][0].get("id", "")), nav2["id"]);

    # Same nav >500ms apart — both kept
    nav3: dict[str, any] = mk_nav("https://example.com/page", 0);
    nav4: dict[str, any] = mk_nav("https://example.com/page", 600);
    assert_eq("noise: same nav >500ms apart both kept", len(remove_noise([nav3, nav4])["events"]), 2);

    # Different nav URLs close together — both kept
    nav5: dict[str, any] = mk_nav("https://example.com/a", 0);
    nav6: dict[str, any] = mk_nav("https://example.com/b", 100);
    assert_eq("noise: different URLs always kept", len(remove_noise([nav5, nav6])["events"]), 2);
}

# ============================================================
# compile_session — heuristic path
# ============================================================

def test_compile_session() {
    session: dict[str, any] = {
        "id": "sess_test_1",
        "startedAt": ts(0),
        "status": "stopped",
        "startUrl": "https://app.example.com/login",
        "domains": ["app.example.com"],
        "goalContext": "Log in to the app",
        "events": [
            {
                "id": "e1", "sessionId": "sess_test_1", "timestamp": ts(0),
                "type": "navigation", "url": "https://app.example.com/login",
                "previousUrl": "https://app.example.com", "trigger": "link_click"
            },
            {
                "id": "e2", "sessionId": "sess_test_1", "timestamp": ts(1000),
                "type": "input", "url": "https://app.example.com/login",
                "element": {"tag": "input", "name": "email", "label": "Email", "type": "email"},
                "value": "user@test.com", "masked": False
            },
            {
                "id": "e3", "sessionId": "sess_test_1", "timestamp": ts(2000),
                "type": "input", "url": "https://app.example.com/login",
                "element": {"tag": "input", "name": "email", "label": "Email", "type": "email"},
                "value": "user@test.com", "masked": False
            }
        ]
    };

    result: dict[str, any] = compile_session(session, DEFAULT_OPTIONS);
    assert_true("compile: ok is True for valid session", bool(result.get("ok", False)));

    wf: any = result.get("workflow", {});
    steps: list[any] = wf.get("steps", []);
    fill_steps: list[any] = [s for s in steps if isinstance(s, dict) and s.get("type") == "fill"];
    goto_steps: list[any] = [s for s in steps if isinstance(s, dict) and s.get("type") == "goto"];

    assert_eq("compile: two consecutive email inputs collapse to one fill", len(fill_steps), 1);
    assert_eq("compile: navigation produces goto step", len(goto_steps), 1);
    assert_eq("compile: goto url matches navigation event", str(goto_steps[0].get("url", "")), "https://app.example.com/login");
    assert_eq("compile: goalContext becomes workflow name", str(wf.get("name", "")), "Log in to the app");
    assert_eq("compile: createdByUserId tracked", str(wf.get("metadata", {}).get("createdByUserId", "")), "user_test");

    email_inputs: list[any] = [i for i in wf.get("inputs", []) if isinstance(i, dict) and i.get("type") == "email"];
    assert_true("compile: email field inferred as runtime input", len(email_inputs) > 0);

    # Validation passes on the compiled output
    v: dict[str, any] = validate_workflow(wf);
    assert_true("compile: compiled workflow passes validate_workflow", bool(v.get("ok", False)));
}

def test_masked_input_becomes_secret() {
    session: dict[str, any] = {
        "id": "sess_masked",
        "startUrl": "https://app.example.com/login",
        "goalContext": "",
        "events": [
            {
                "id": "e_pwd", "sessionId": "sess_masked", "timestamp": ts(0),
                "type": "input", "url": "https://app.example.com/login",
                "element": {"tag": "input", "name": "password", "type": "password"},
                "value": "secret", "masked": True
            }
        ]
    };
    result: dict[str, any] = compile_session(session, DEFAULT_OPTIONS);
    assert_true("masked: ok is True", bool(result.get("ok", False)));
    steps: list[any] = result.get("workflow", {}).get("steps", []);
    fill: list[any] = [s for s in steps if isinstance(s, dict) and s.get("type") == "fill"];
    kind: str = str(fill[0].get("value", {}).get("kind", "")) if fill else "";
    assert_eq("masked: fill value kind is secret", kind, "secret");
}

def test_compile_session_live_schema() {
    session: dict[str, any] = {
        "session_id": "sess_live_1",
        "source_url": "https://app.example.com/login",
        "title": "Log in from live trace",
        "events": [
            {
                "type": "navigate",
                "url": "https://app.example.com/login",
                "recorded_at": ts(0),
                "target": {}
            },
            {
                "type": "input",
                "url": "https://app.example.com/login",
                "recorded_at": ts(1000),
                "target": {"tag": "input", "name": "email", "label": "Email", "type": "email"},
                "value": "user@test.com"
            }
        ]
    };

    result: dict[str, any] = compile_session(session, DEFAULT_OPTIONS);
    assert_true("live schema: ok is True", bool(result.get("ok", False)));

    wf: any = result.get("workflow", {});
    steps: list[any] = wf.get("steps", []);
    goto_steps: list[any] = [s for s in steps if isinstance(s, dict) and s.get("type") == "goto"];
    fill_steps: list[any] = [s for s in steps if isinstance(s, dict) and s.get("type") == "fill"];

    assert_eq("live schema: navigate becomes goto", len(goto_steps), 1);
    assert_eq("live schema: input becomes fill", len(fill_steps), 1);
    assert_eq("live schema: title becomes workflow name", str(wf.get("name", "")), "Log in from live trace");
    assert_eq(
        "live schema: session_id becomes recording session id",
        str(wf.get("metadata", {}).get("source", {}).get("recordingSessionId", "")),
        "sess_live_1"
    );

    origins: list[any] = wf.get("compileInfo", {}).get("stepOrigins", []);
    first_origin: any = origins[0] if origins else {};
    source_ids: list[any] = first_origin.get("sourceEventIds", []) if isinstance(first_origin, dict) else [];
    first_source_id: str = str(source_ids[0]) if source_ids else "";
    assert_true("live schema: missing ids are synthesized", first_source_id.startswith("evt_sess_live_1_"));
}

def test_compile_session_uses_user_explanation_context() {
    session: dict[str, any] = {
        "session_id": "sess_live_explain",
        "source_url": "https://app.example.com/invoices",
        "goalContext": "Review overdue invoices",
        "userExplanation": "Repeat the review for each overdue invoice and download the matching PDF before moving on.",
        "events": [
            {
                "type": "navigate",
                "url": "https://app.example.com/invoices",
                "recorded_at": ts(0),
                "target": {}
            },
            {
                "type": "click",
                "url": "https://app.example.com/invoices",
                "recorded_at": ts(1000),
                "target": {"tag": "button", "text": "Download PDF", "label": "Download PDF"}
            }
        ]
    };

    result: dict[str, any] = compile_session(session, DEFAULT_OPTIONS);
    assert_true("explain: compile ok", bool(result.get("ok", False)));

    wf: any = result.get("workflow", {});
    context: any = wf.get("context", {});
    provided: any = context.get("userProvidedContext", []);
    assert_eq("explain: goal stays primary workflow goal", str(context.get("goal", "")), "Review overdue invoices");
    assert_true(
        "explain: user explanation is preserved in compile context",
        isinstance(provided, list) and "Repeat the review for each overdue invoice and download the matching PDF before moving on." in provided
    );
}

def test_kimi_compile_request_includes_user_explanation() {
    raw_session: dict[str, any] = {
        "events": [],
        "semantic": {}
    };
    normalized_session: dict[str, any] = {
        "goalContext": "Review overdue invoices",
        "userExplanation": "The workflow loops through each overdue invoice and downloads the PDF.",
        "startUrl": "https://app.example.com/invoices",
        "status": "stopped"
    };
    cleaned: dict[str, any] = {"events": []};
    partial: dict[str, any] = {
        "name": "Review overdue invoices",
        "context": {"goal": "Review overdue invoices"},
        "inputs": [],
        "steps": [{"type": "goto"}]
    };
    payload: dict[str, any] = build_kimi_compile_request(
        raw_session,
        normalized_session,
        cleaned,
        partial,
        {"model": "kimi-k2.5", "thinking_mode": "disabled"}
    );
    messages: any = payload.get("messages", []);
    user_content: str = "";
    if isinstance(messages, list) and len(messages) > 2 and isinstance(messages[2], dict) {
        user_content = str(messages[2].get("content", ""));
    }
    assert_true("kimi request: user explanation included", "\"user_explanation\": \"The workflow loops through each overdue invoice and downloads the PDF.\"" in user_content);
}

def test_kimi_cli_prompt_includes_user_explanation() {
    prompt: str = build_kimi_cli_prompt(
        {"events": []},
        {
            "goalContext": "Review overdue invoices",
            "userExplanation": "The workflow loops through each overdue invoice and downloads the PDF.",
            "startUrl": "https://app.example.com/invoices",
            "status": "stopped"
        },
        {"events": []},
        {
            "name": "Review overdue invoices",
            "context": {"goal": "Review overdue invoices"},
            "inputs": [],
            "steps": [{"type": "goto"}]
        }
    );

    assert_true("kimi cli prompt: includes JSON contract", "Return exactly one JSON object." in prompt);
    assert_true("kimi cli prompt: user explanation included", "\"user_explanation\": \"The workflow loops through each overdue invoice and downloads the PDF.\"" in prompt);
}

def test_ollama_request_includes_json_mode_and_user_explanation() {
    payload: dict[str, any] = build_ollama_chat_request(
        {"events": []},
        {
            "goalContext": "Review overdue invoices",
            "userExplanation": "The workflow loops through each overdue invoice and downloads the PDF.",
            "startUrl": "https://app.example.com/invoices",
            "status": "stopped"
        },
        {"events": []},
        {
            "name": "Review overdue invoices",
            "context": {"goal": "Review overdue invoices"},
            "inputs": [],
            "steps": [{"type": "goto"}]
        },
        {"model": "qwen2.5:3b-instruct-q4_0"}
    );

    assert_eq("ollama request: format json", str(payload.get("format", "")), "json");
    assert_eq("ollama request: stream disabled", bool(payload.get("stream", True)), False);
    messages: any = payload.get("messages", []);
    user_content: str = "";
    if isinstance(messages, list) and len(messages) > 2 and isinstance(messages[2], dict) {
        user_content = str(messages[2].get("content", ""));
    }
    assert_true("ollama request: user explanation included", "\"user_explanation\": \"The workflow loops through each overdue invoice and downloads the PDF.\"" in user_content);
}

def test_parse_json_object_text_accepts_fenced_json() {
    parsed: dict[str, any] = parse_json_object_text(
        """```json
{"ok": true, "name": "compiled"}
```"""
    );
    assert_eq("kimi parse: fenced json ok", bool(parsed.get("ok", False)), True);
    assert_eq("kimi parse: fenced json name", str(parsed.get("name", "")), "compiled");
}

def test_validate_rejects_partial() {
    bad: dict[str, any] = {"name": "broken", "steps": []};
    r: dict[str, any] = validate_workflow(bad);
    assert_eq("validate: rejects missing version field", bool(r.get("ok", True)), False);
    assert_true("validate: returns error list", len(r.get("errors", [])) > 0);
}

def test_infer_safety_rules() {
    steps: list[any] = [
        {"type": "click", "target": {"primary": {"kind": "text", "text": "Submit Order"}}},
        {"type": "click", "target": {"primary": {"kind": "label", "label": "Delete Account"}}},
        {"type": "click", "target": {"primary": {"kind": "label", "label": "Continue"}}},
    ];
    rules: list[any] = infer_safety_rules(steps);
    assert_eq("safety: 2 high-stakes clicks get rules", len(rules), 2);
    actions: list[str] = [str(r.get("action", "")) for r in rules];
    assert_true("safety: all rules require approval", all(a == "require_approval" for a in actions));
}

# ============================================================
# SEGMENTED COMPILATION TESTS — helpers
# ============================================================

glob DEFAULT_CONTINUATION: dict[str, any] = {
    "strategy": [{"mode": "next_similar_item", "options": {}}]
};

glob DEFAULT_STOP_POLICY: dict[str, any] = {
    "mode": "no_more_items",
    "options": {}
};

def mk_segmented_recording(
    ot_events: list[any],
    rep_events: list[any],
    continuation: dict[str, any],
    stop_policy: dict[str, any]
) -> dict[str, any] {
    return {
        "recording_id": "rec_test_001",
        "task_name": "Test workflow",
        "state": "finished",
        "segments": {
            "one_time": {"events": ot_events, "annotations": []},
            "repeated": {"events": rep_events, "annotations": []}
        },
        "continuation": continuation,
        "stop_policy": stop_policy,
        "meta": {
            "start_url": "https://example.com",
            "domains": ["example.com"],
            "user_goal": "Test goal"
        }
    };
}

# ============================================================
# Test 1: only one_time events compile successfully
# ============================================================

def test_seg_only_one_time() {
    rec: dict[str, any] = mk_segmented_recording(
        [mk_click("btn-login", 0), mk_nav("https://example.com/list", 100)],
        [],
        DEFAULT_CONTINUATION,
        DEFAULT_STOP_POLICY
    );
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg1: only one_time compiles ok", bool(result.get("ok", False)));
    art: any = result.get("artifact", {});
    ot_steps: list[any] = art.get("one_time", {}).get("steps", []);
    rep_steps: list[any] = art.get("repeated", {}).get("steps", []);
    assert_true("seg1: one_time has steps", len(ot_steps) > 0);
    assert_eq("seg1: repeated is empty", len(rep_steps), 0);
}

# ============================================================
# Test 2: only repeated events compile successfully
# ============================================================

def test_seg_only_repeated() {
    rec: dict[str, any] = mk_segmented_recording(
        [],
        [mk_click("btn-item", 0), mk_nav("https://example.com/item/1", 100)],
        DEFAULT_CONTINUATION,
        DEFAULT_STOP_POLICY
    );
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg2: only repeated compiles ok", bool(result.get("ok", False)));
    art: any = result.get("artifact", {});
    ot_steps: list[any] = art.get("one_time", {}).get("steps", []);
    rep_steps: list[any] = art.get("repeated", {}).get("steps", []);
    assert_eq("seg2: one_time is empty", len(ot_steps), 0);
    assert_true("seg2: repeated has steps", len(rep_steps) > 0);
}

# ============================================================
# Test 3: both segments compile successfully
# ============================================================

def test_seg_both_segments() {
    rec: dict[str, any] = mk_segmented_recording(
        [mk_nav("https://example.com", 0)],
        [mk_click("btn-next", 0), mk_nav("https://example.com/item", 100)],
        DEFAULT_CONTINUATION,
        DEFAULT_STOP_POLICY
    );
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg3: both segments compile ok", bool(result.get("ok", False)));
    art: any = result.get("artifact", {});
    assert_true("seg3: one_time has steps", len(art.get("one_time", {}).get("steps", [])) > 0);
    assert_true("seg3: repeated has steps", len(art.get("repeated", {}).get("steps", [])) > 0);
}

# ============================================================
# Test 4: one_time events compile into one_time steps only
# ============================================================

def test_seg_one_time_steps_isolated() {
    rec: dict[str, any] = mk_segmented_recording(
        [mk_click("btn-login", 0)],
        [mk_click("btn-item", 0)],
        DEFAULT_CONTINUATION,
        DEFAULT_STOP_POLICY
    );
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg4: compiles ok", bool(result.get("ok", False)));
    art: any = result.get("artifact", {});
    ot_clicks: list[any] = [s for s in art.get("one_time", {}).get("steps", []) if isinstance(s, dict) and s.get("type") == "click"];
    rep_clicks: list[any] = [s for s in art.get("repeated", {}).get("steps", []) if isinstance(s, dict) and s.get("type") == "click"];
    assert_eq("seg4: one_time has exactly 1 click", len(ot_clicks), 1);
    assert_eq("seg4: repeated has exactly 1 click", len(rep_clicks), 1);
    ot_sel: str = str(ot_clicks[0].get("target", {}).get("primary", {}).get("selector", ""));
    rep_sel: str = str(rep_clicks[0].get("target", {}).get("primary", {}).get("selector", ""));
    assert_eq("seg4: one_time click is btn-login", ot_sel, "#btn-login");
    assert_eq("seg4: repeated click is btn-item", rep_sel, "#btn-item");
}

# ============================================================
# Test 5: repeated events compile into repeated steps only
# ============================================================

def test_seg_repeated_steps_isolated() {
    rec: dict[str, any] = mk_segmented_recording(
        [],
        [mk_click("btn-process", 0)],
        DEFAULT_CONTINUATION,
        DEFAULT_STOP_POLICY
    );
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg5: compiles ok", bool(result.get("ok", False)));
    art: any = result.get("artifact", {});
    ot_steps: list[any] = art.get("one_time", {}).get("steps", []);
    rep_clicks: list[any] = [s for s in art.get("repeated", {}).get("steps", []) if isinstance(s, dict) and s.get("type") == "click"];
    assert_eq("seg5: one_time has 0 steps", len(ot_steps), 0);
    assert_eq("seg5: repeated has 1 click step", len(rep_clicks), 1);
}

# ============================================================
# Test 6: repeated typing collapse works inside repeated
# ============================================================

def test_seg_repeated_typing_collapse() {
    rec: dict[str, any] = mk_segmented_recording(
        [],
        [
            mk_input("search", "h", 0),
            mk_input("search", "he", 100),
            mk_input("search", "hello", 200)
        ],
        DEFAULT_CONTINUATION,
        DEFAULT_STOP_POLICY
    );
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg6: compiles ok", bool(result.get("ok", False)));
    rep_steps: list[any] = result.get("artifact", {}).get("repeated", {}).get("steps", []);
    fills: list[any] = [s for s in rep_steps if isinstance(s, dict) and s.get("type") == "fill"];
    assert_eq("seg6: 3 keystrokes collapse to 1 fill in repeated", len(fills), 1);
    assert_eq("seg6: fill value is final keystroke", str(fills[0].get("value", {}).get("value", "")), "hello");
}

# ============================================================
# Test 7: masked repeated input becomes secret in repeated output
# ============================================================

def test_seg_masked_repeated_input_is_secret() {
    pwd_evt: dict[str, any] = {
        "id": "evt_pwd_rep", "timestamp": ts(0), "type": "input",
        "url": "https://example.com",
        "element": {"tag": "input", "name": "password", "type": "password"},
        "value": "s3cret", "masked": True
    };
    rec: dict[str, any] = mk_segmented_recording([], [pwd_evt], DEFAULT_CONTINUATION, DEFAULT_STOP_POLICY);
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg7: compiles ok", bool(result.get("ok", False)));
    rep_steps: list[any] = result.get("artifact", {}).get("repeated", {}).get("steps", []);
    fills: list[any] = [s for s in rep_steps if isinstance(s, dict) and s.get("type") == "fill"];
    kind: str = str(fills[0].get("value", {}).get("kind", "")) if fills else "";
    assert_eq("seg7: masked repeated input becomes secret", kind, "secret");
    ot_steps: list[any] = result.get("artifact", {}).get("one_time", {}).get("steps", []);
    assert_eq("seg7: one_time has no secret fill", len(ot_steps), 0);
}

# ============================================================
# Test 8: continuation strategy preserved in compiled output
# ============================================================

def test_seg_continuation_preserved() {
    cont: dict[str, any] = {
        "strategy": [{"mode": "next_page", "options": {"max_pages": 5}}]
    };
    rec: dict[str, any] = mk_segmented_recording([], [mk_click("btn-next", 0)], cont, DEFAULT_STOP_POLICY);
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg8: compiles ok", bool(result.get("ok", False)));
    stored_cont: any = result.get("artifact", {}).get("continuation", {});
    strategy: list[any] = stored_cont.get("strategy", []);
    assert_eq("seg8: strategy has 1 entry", len(strategy), 1);
    assert_eq("seg8: strategy mode preserved", str(strategy[0].get("mode", "")), "next_page");
    assert_eq("seg8: strategy max_pages preserved", strategy[0].get("options", {}).get("max_pages", 0), 5);
}

# ============================================================
# Test 9: stop policy preserved in compiled output
# ============================================================

def test_seg_stop_policy_preserved() {
    sp: dict[str, any] = {"mode": "after_n_successes", "options": {"count": 10}};
    rec: dict[str, any] = mk_segmented_recording([], [mk_click("btn-item", 0)], DEFAULT_CONTINUATION, sp);
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg9: compiles ok", bool(result.get("ok", False)));
    stored_sp: any = result.get("artifact", {}).get("stop_policy", {});
    assert_eq("seg9: stop_policy mode preserved", str(stored_sp.get("mode", "")), "after_n_successes");
    assert_eq("seg9: stop_policy count preserved", stored_sp.get("options", {}).get("count", 0), 10);
}

# ============================================================
# Test 10: one_time and repeated segments do not leak events
# ============================================================

def test_seg_no_event_leakage() {
    ot_click: dict[str, any] = mk_click("btn-login", 0);
    rep_click: dict[str, any] = mk_click("btn-download", 0);
    rec: dict[str, any] = mk_segmented_recording([ot_click], [rep_click], DEFAULT_CONTINUATION, DEFAULT_STOP_POLICY);
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg10: compiles ok", bool(result.get("ok", False)));
    art: any = result.get("artifact", {});
    ot_css: list[str] = [
        str(s.get("target", {}).get("primary", {}).get("selector", ""))
        for s in art.get("one_time", {}).get("steps", [])
        if isinstance(s, dict) and s.get("type") == "click"
    ];
    rep_css: list[str] = [
        str(s.get("target", {}).get("primary", {}).get("selector", ""))
        for s in art.get("repeated", {}).get("steps", [])
        if isinstance(s, dict) and s.get("type") == "click"
    ];
    assert_true("seg10: login click in one_time", "#btn-login" in ot_css);
    assert_true("seg10: download click NOT in one_time", "#btn-download" not in ot_css);
    assert_true("seg10: download click in repeated", "#btn-download" in rep_css);
    assert_true("seg10: login click NOT in repeated", "#btn-login" not in rep_css);
}

# ============================================================
# Test 11: validate_compiled_artifact positive and negative
# ============================================================

def test_seg_validate_artifact() {
    rec: dict[str, any] = mk_segmented_recording(
        [mk_click("btn-start", 0)],
        [mk_click("btn-item", 0)],
        DEFAULT_CONTINUATION,
        DEFAULT_STOP_POLICY
    );
    result: dict[str, any] = compile_segmented_recording(rec, DEFAULT_OPTIONS);
    assert_true("seg11: compile ok", bool(result.get("ok", False)));
    v: dict[str, any] = validate_compiled_artifact(result.get("artifact", {}));
    assert_true("seg11: valid artifact passes validation", bool(v.get("ok", False)));

    bad: dict[str, any] = {"name": "incomplete"};
    v_bad: dict[str, any] = validate_compiled_artifact(bad);
    assert_eq("seg11: bad artifact fails validation", bool(v_bad.get("ok", True)), False);
    assert_true("seg11: error list is non-empty", len(v_bad.get("errors", [])) > 0);
}

# ============================================================
# Test 12: flat-session dry_run path is still supported
# ============================================================

def test_old_dry_run_still_works() {
    session: dict[str, any] = {
        "id": "sess_compat_1",
        "startUrl": "https://example.com",
        "goalContext": "Check backward compat",
        "events": [
            mk_nav("https://example.com/page", 0),
            mk_click("btn-ok", 200)
        ]
    };
    result: dict[str, any] = compile_session(session, DEFAULT_OPTIONS);
    assert_true("compat: flat compile_session still works", bool(result.get("ok", False)));
    wf: any = result.get("workflow", {});
    assert_true("compat: flat workflow has steps", len(wf.get("steps", [])) > 0);
    v: dict[str, any] = validate_workflow(wf);
    assert_true("compat: flat workflow passes validate_workflow", bool(v.get("ok", False)));
}

# ============================================================
# Run all tests
# ============================================================

with entry {
    test_merge_typing_events();
    test_collapse_duplicate_clicks();
    test_remove_noise();
    test_compile_session();
    test_masked_input_becomes_secret();
    test_compile_session_live_schema();
    test_compile_session_uses_user_explanation_context();
    test_validate_rejects_partial();
    test_infer_safety_rules();
    test_kimi_compile_request_includes_user_explanation();
    test_kimi_cli_prompt_includes_user_explanation();
    test_ollama_request_includes_json_mode_and_user_explanation();
    test_parse_json_object_text_accepts_fenced_json();

    test_seg_only_one_time();
    test_seg_only_repeated();
    test_seg_both_segments();
    test_seg_one_time_steps_isolated();
    test_seg_repeated_steps_isolated();
    test_seg_repeated_typing_collapse();
    test_seg_masked_repeated_input_is_secret();
    test_seg_continuation_preserved();
    test_seg_stop_policy_preserved();
    test_seg_no_event_leakage();
    test_seg_validate_artifact();
    test_old_dry_run_still_works();

    print("");
    print("Results: " + str(COUNTS["passed"]) + " passed, " + str(COUNTS["failed"]) + " failed.");
    if COUNTS["failed"] > 0 {
        print("SOME TESTS FAILED");
    } else {
        print("ALL TESTS PASSED");
    }
}
