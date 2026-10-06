"""
Jac-native compilation layer.

Pipeline:  RecordingSession  →  clean_trace  →  heuristic_compile
           →  (optional model hook)  →  validate_workflow  →  Workflow IR

Behavioral reference: src/compilation/ TypeScript implementation.
Compiler version: 0.2.0
"""

import os;
import sys;
import json;
import re;
import time;
import uuid;
import from urllib.parse { urlparse }
import from jac.llm.kimi_client {
    resolve_kimi_compile_config,
    kimi_compile_enrichment
}
import from jac.llm.runtime_state { current_runtime_state }

# ============================================================
# CONSTANTS
# ============================================================

glob DATA_ROOT: str = "./jac/layer_data";
glob TRACE_DIR: str = DATA_ROOT + "/traces";
glob WORKFLOW_DIR: str = DATA_ROOT + "/workflows";
glob RECORDING_DIR: str = DATA_ROOT + "/recordings";
glob COMPILER_VERSION: str = "0.2.0";
glob SAFETY_PATTERNS: list[str] = [
    "submit", "confirm", "place order", "pay", "delete", "remove"
];

# ============================================================
# UTILITIES
# ============================================================

"""Generate a prefixed random ID from a UUID v4."""
def new_id(prefix: str) -> str {
    uid: str = str(uuid.uuid4()).replace("-", "");
    return prefix + uid[:16];
}

def new_workflow_id() -> str { return new_id("wf_"); }
def new_step_id() -> str { return new_id("step_"); }
def new_input_id() -> str { return new_id("inp_"); }
def new_rule_id() -> str { return new_id("rule_"); }

"""Return current UTC time as ISO-8601 string (seconds precision)."""
def timestamp_now() -> str {
    t: any = time.gmtime();
    result: str = time.strftime("%Y-%m-%dT%H:%M:%SZ", t);
    return result;
}

"""Parse ISO-8601 timestamp to approximate Unix milliseconds.
Uses time.mktime (local time) — only used for within-session delta comparisons,
so the local-time offset is constant and cancels out.
"""
def parse_ts(iso: str) -> float {
    try {
        s: str = iso.replace("Z", "").replace("+00:00", "");
        ms_part: float = 0.0;
        if "." in s {
            dot: int = s.rfind(".");
            ms_str: str = "0." + s[dot + 1:];
            ms_part = float(ms_str);
            s = s[:dot];
        }
        t: any = time.strptime(s, "%Y-%m-%dT%H:%M:%S");
        base: float = float(time.mktime(t));
        return base * 1000.0 + ms_part * 1000.0;
    } except Exception {
        return 0.0;
    }
}

"""Extract the hostname from a URL string, or empty string on failure."""
def extract_hostname(url: str) -> str {
    try {
        parsed: any = urlparse(url);
        host: str = str(parsed.hostname or "");
        return host;
    } except Exception {
        return "";
    }
}

"""Extract the path component from a URL string, or '/' on failure."""
def extract_pathname(url: str) -> str {
    try {
        parsed: any = urlparse(url);
        path: str = str(parsed.path);
        return path if path else "/";
    } except Exception {
        return "/";
    }
}

"""Convert a human label into a stable snake_case input key."""
def to_snake_case(s: str) -> str {
    s = s.lower().strip();
    s = re.sub(r"[^a-z0-9]+", "_", s);
    s = s.strip("_");
    if not s {
        return "value";
    }
    return s;
}

"""R: Adapt a live observation target dict into the compiler's element schema.
M: Copies only the locator fields the compiler already understands and renames `text`.
E: Missing or malformed targets return an empty element dict without affecting old inputs.
"""
def normalize_compiler_element(raw_target: any) -> dict[str, any] {
    element: dict[str, any] = {};
    if not isinstance(raw_target, dict) { return element; }

    tag: str = str(raw_target.get("tag", ""));
    if tag { element["tag"] = tag; }

    el_id: str = str(raw_target.get("id", ""));
    if el_id { element["id"] = el_id; }

    name: str = str(raw_target.get("name", ""));
    if name { element["name"] = name; }

    role: str = str(raw_target.get("role", ""));
    if role { element["role"] = role; }

    el_type: str = str(raw_target.get("type", ""));
    if el_type { element["type"] = el_type; }

    label: str = str(raw_target.get("label", ""));
    if label { element["label"] = label; }

    inner_text: str = str(raw_target.get("text", ""));
    if inner_text { element["innerText"] = inner_text; }

    placeholder: str = str(raw_target.get("placeholder", ""));
    if placeholder { element["placeholder"] = placeholder; }

    return element;
}

"""R: Normalize a single event into the schema expected by the compiler pipeline.
M: Preserves compiler-native fields, backfills live-trace aliases, and synthesizes ids when absent.
E: Unknown event types pass through; malformed targets only affect the synthesized element field.
"""
def normalize_compiler_event(
    raw_event: any,
    session_id: str,
    index: int
) -> any {
    if not isinstance(raw_event, dict) { return raw_event; }

    event: dict[str, any] = dict(raw_event);
    evt_id: str = str(event.get("id", ""));
    if not evt_id {
        base: str = session_id if session_id else "session";
        evt_id = "evt_" + base + "_" + str(index);
    }
    event["id"] = evt_id;

    if not event.get("sessionId") and session_id {
        event["sessionId"] = session_id;
    }

    if not event.get("timestamp") and event.get("recorded_at") {
        event["timestamp"] = str(event.get("recorded_at", ""));
    }

    if str(event.get("type", "")) == "navigate" {
        event["type"] = "navigation";
    }

    if not isinstance(event.get("element", None), dict) {
        target: dict[str, any] = normalize_compiler_element(event.get("target", {}));
        if target {
            event["element"] = target;
        }
    }

    return event;
}

"""R: Normalize session-level live-trace aliases into the compiler's stable schema.
M: Preserves existing compiler fields and only fills gaps from live observation keys.
E: Old-schema sessions remain unchanged; non-dict event entries are preserved as-is.
"""
def normalize_compiler_session(session: dict[str, any]) -> dict[str, any] {
    normalized: dict[str, any] = dict(session);

    session_id: str = str(session.get("id", "") or session.get("session_id", ""));
    if session_id { normalized["id"] = session_id; }

    start_url: str = str(session.get("startUrl", "") or session.get("source_url", ""));
    if start_url { normalized["startUrl"] = start_url; }

    user_explanation: str = str(session.get("userExplanation", "") or session.get("user_explanation", ""));
    if user_explanation { normalized["userExplanation"] = user_explanation; }

    goal: str = str(session.get("goalContext", "") or session.get("title", "") or user_explanation);
    if goal { normalized["goalContext"] = goal; }

    raw_events: any = session.get("events", []);
    if isinstance(raw_events, list) {
        normalized_events: list[any] = [];
        for (i, raw_event) in enumerate(raw_events) {
            normalized_events.append(normalize_compiler_event(raw_event, session_id, i));
        }
        normalized["events"] = normalized_events;
    }

    return normalized;
}

# ============================================================
# FILE I/O
# ============================================================

"""Ensure the workflow output directory exists."""
def ensure_workflow_dir() {
    os.makedirs(WORKFLOW_DIR, exist_ok=True);
}

"""Read a JSON object from disk; return empty dict on any failure."""
def read_json(path: str) -> dict[str, any] {
    if not os.path.exists(path) {
        return {};
    }
    try {
        with open(path, "r") as f {
            parsed: any = json.load(f);
            if isinstance(parsed, dict) {
                return parsed;
            }
        }
    } except Exception {
        return {};
    }
    return {};
}

"""Write a JSON object to disk with pretty-printing."""
def write_json(path: str, data: dict[str, any]) {
    os.makedirs(os.path.dirname(path), exist_ok=True);
    with open(path, "w") as f {
        json.dump(data, f, indent=2);
    }
}

"""Parse JSON payload from CLI args (position 2+)."""
def parse_payload() -> dict[str, any] {
    if len(sys.argv) > 2 {
        raw: str = " ".join(sys.argv[2:]);
        try {
            parsed: any = json.loads(raw);
            if isinstance(parsed, dict) {
                return parsed;
            }
        } except Exception {
            return {};
        }
    }
    return {};
}

"""Build absolute trace file path from session id."""
def trace_file(session_id: str) -> str {
    return TRACE_DIR + "/" + session_id + ".json";
}

"""Build absolute workflow file path from workflow id."""
def workflow_file(workflow_id: str) -> str {
    return WORKFLOW_DIR + "/" + workflow_id + ".json";
}

# ============================================================
# CLEANER PIPELINE
# ============================================================

"""Filter out events that carry no workflow-level meaning.

Removes:
  - focus/blur events whose element has no corresponding input/change event
  - duplicate navigation events to the same URL within 500ms

E: Empty input returns empty results; malformed timestamps yield delta=0.
"""
def remove_noise(events: list[any]) -> dict[str, any] {
    removed: list[any] = [];
    kept: list[any] = [];

    # Collect element IDs that received at least one input or change event
    inputted_ids: set[str] = set();
    for evt in events {
        if not isinstance(evt, dict) { continue; }
        etype: str = str(evt.get("type", ""));
        if etype == "input" or etype == "change" {
            el: any = evt.get("element", {});
            if isinstance(el, dict) {
                eid: str = str(el.get("id", ""));
                if eid { inputted_ids.add(eid); }
            }
        }
    }

    for evt in events {
        if not isinstance(evt, dict) { continue; }
        etype = str(evt.get("type", ""));
        evt_id: str = str(evt.get("id", ""));

        # Drop orphan focus/blur (no accompanying input on same element)
        if etype == "focus" or etype == "blur" {
            el = evt.get("element", {});
            if isinstance(el, dict) {
                eid = str(el.get("id", ""));
                if eid and eid not in inputted_ids {
                    removed.append({
                        "id": evt_id,
                        "reason": etype + " with no input on element " + eid
                    });
                    continue;
                }
            }
        }

        # Drop duplicate navigation to the same URL within 500ms
        if etype == "navigation" {
            nav_url: str = str(evt.get("url", ""));
            prev_nav: any = None;
            for k in reversed(kept) {
                if isinstance(k, dict) and str(k.get("type", "")) == "navigation" {
                    prev_nav = k;
                    break;
                }
            }
            if prev_nav is not None {
                prev_url: str = str(prev_nav.get("url", ""));
                if prev_url == nav_url {
                    prev_ts: float = parse_ts(str(prev_nav.get("timestamp", "0")));
                    curr_ts: float = parse_ts(str(evt.get("timestamp", "0")));
                    if (curr_ts - prev_ts) < 500.0 {
                        removed.append({
                            "id": evt_id,
                            "reason": "duplicate navigation within 500ms"
                        });
                        continue;
                    }
                }
            }
        }

        kept.append(evt);
    }

    return {"events": kept, "removed": removed};
}

"""True when two input events target the same DOM element.
Matches by element id, then name, then cssSelector.
"""
def same_input_element(a: dict[str, any], b: dict[str, any]) -> bool {
    el_a: any = a.get("element", {});
    el_b: any = b.get("element", {});
    if not isinstance(el_a, dict) or not isinstance(el_b, dict) { return False; }
    id_a: str = str(el_a.get("id", ""));
    id_b: str = str(el_b.get("id", ""));
    if id_a and id_a == id_b { return True; }
    name_a: str = str(el_a.get("name", ""));
    name_b: str = str(el_b.get("name", ""));
    if name_a and name_a == name_b { return True; }
    css_a: str = str(el_a.get("cssSelector", ""));
    css_b: str = str(el_b.get("cssSelector", ""));
    if css_a and css_a == css_b { return True; }
    return False;
}

"""Collapse consecutive input events on the same element into one event.
Keeps the last event in each run, which carries the final typed value.
E: Non-input events pass through unchanged; runs on different elements stay separate.
"""
def merge_typing_events(events: list[any]) -> list[any] {
    result: list[any] = [];
    i: int = 0;
    while i < len(events) {
        evt: any = events[i];
        if not isinstance(evt, dict) {
            i += 1;
            continue;
        }
        if str(evt.get("type", "")) != "input" {
            result.append(evt);
            i += 1;
            continue;
        }
        # Look ahead for consecutive input events on the same element
        group: list[any] = [evt];
        while i + 1 < len(events) {
            next_evt: any = events[i + 1];
            if (isinstance(next_evt, dict) and
                str(next_evt.get("type", "")) == "input" and
                same_input_element(evt, next_evt)) {
                i += 1;
                group.append(events[i]);
            } else {
                break;
            }
        }
        result.append(group[-1]);
        i += 1;
    }
    return result;
}

"""True when two click events target the same DOM element.
Matches by element id, then cssSelector.
"""
def same_click_target(a: dict[str, any], b: dict[str, any]) -> bool {
    el_a: any = a.get("element", {});
    el_b: any = b.get("element", {});
    if not isinstance(el_a, dict) or not isinstance(el_b, dict) { return False; }
    id_a: str = str(el_a.get("id", ""));
    id_b: str = str(el_b.get("id", ""));
    if id_a and id_a == id_b { return True; }
    css_a: str = str(el_a.get("cssSelector", ""));
    css_b: str = str(el_b.get("cssSelector", ""));
    if css_a and css_a == css_b { return True; }
    return False;
}

"""Remove accidental double-clicks: same target within 300ms, keep the first.
Searches backward through the running result for the last click on the same target;
intervening non-click events do not reset the dedup window.
"""
def collapse_duplicate_clicks(events: list[any]) -> list[any] {
    result: list[any] = [];
    for evt in events {
        if not isinstance(evt, dict) or str(evt.get("type", "")) != "click" {
            result.append(evt);
            continue;
        }
        prev_click: any = None;
        for k in reversed(result) {
            if isinstance(k, dict) and str(k.get("type", "")) == "click" {
                if same_click_target(k, evt) {
                    prev_click = k;
                    break;
                }
            }
        }
        if prev_click is not None {
            prev_ts: float = parse_ts(str(prev_click.get("timestamp", "0")));
            curr_ts: float = parse_ts(str(evt.get("timestamp", "0")));
            if (curr_ts - prev_ts) < 300.0 {
                continue;  # drop duplicate
            }
        }
        result.append(evt);
    }
    return result;
}

"""Apply the full three-pass cleaning pipeline to a session.
Order: removeNoise → mergeTypingEvents → collapseDuplicateClicks
"""
def clean_trace(session: dict[str, any]) -> dict[str, any] {
    raw_events: list[any] = [];
    candidate: any = session.get("events", []);
    if isinstance(candidate, list) { raw_events = candidate; }

    noise_result: dict[str, any] = remove_noise(raw_events);
    events: list[any] = noise_result["events"];
    events = merge_typing_events(events);
    events = collapse_duplicate_clicks(events);

    return {
        "sessionId": str(session.get("id", "")),
        "cleanedAt": timestamp_now(),
        "removedEventIds": noise_result["removed"],
        "events": events
    };
}

"""R: Apply the three-pass cleaning pipeline to a raw event list.
M: Runs remove_noise → merge_typing_events → collapse_duplicate_clicks on a flat list.
E: Empty list returns empty results; wraps the same helpers used by clean_trace.
"""
def clean_segment_events(events: list[any]) -> dict[str, any] {
    noise_result: dict[str, any] = remove_noise(events);
    cleaned: list[any] = noise_result["events"];
    cleaned = merge_typing_events(cleaned);
    cleaned = collapse_duplicate_clicks(cleaned);
    return {"events": cleaned, "removed": noise_result["removed"]};
}

# ============================================================
# INFERENCE
# ============================================================

"""Determine the semantic WorkflowInput type from element metadata and value.
Returns empty string if the field should NOT become a runtime input.
Priority: element.type → label/name pattern → value pattern.
"""
def infer_input_type(el: dict[str, any], value: str) -> str {
    el_type: str = str(el.get("type", "")).lower();
    label: str = str(el.get("label", "")).lower();
    name: str = str(el.get("name", "")).lower();

    if el_type == "password" { return "password"; }
    if el_type == "email" or re.search(r"email", label) or re.search(r"email", name) {
        return "email";
    }
    if el_type == "date" or re.search(r"date", label) or re.search(r"\d{4}-\d{2}-\d{2}", value) {
        return "date";
    }
    if el_type == "number" or re.search(r"amount|price|qty|quantity", label) {
        return "number";
    }
    if el_type == "file" { return "file"; }
    if re.match(r"^\d+(\.\d+)?$", value) { return "number"; }
    if re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", value) { return "email"; }
    if len(value) > 3 { return "string"; }
    return "";
}

"""Identify input/change events that should become parameterized workflow inputs.
A field becomes an input when its type inference returns a non-empty type.
Deduplicates by element key (name > label > id).
"""
def infer_inputs(events: list[any]) -> list[any] {
    inputs: list[any] = [];
    seen: set[str] = set();

    for evt in events {
        if not isinstance(evt, dict) { continue; }
        etype: str = str(evt.get("type", ""));
        if etype != "input" and etype != "change" { continue; }
        el: any = evt.get("element", {});
        if not isinstance(el, dict) { continue; }
        key: str = str(el.get("name", "") or el.get("label", "") or el.get("id", ""));
        if not key or key in seen { continue; }
        value: str = str(evt.get("value", ""));
        input_type: str = infer_input_type(el, value);
        if not input_type { continue; }
        seen.add(key);
        label_str: str = str(el.get("label", "") or key);
        is_secret: bool = str(el.get("type", "")) == "password";
        preview: str = value[:30] if len(value) > 30 else value;
        inputs.append({
            "id": new_input_id(),
            "name": to_snake_case(key),
            "label": label_str,
            "type": input_type,
            "required": True,
            "secret": is_secret,
            "sourceHint": {
                "inferredFromStepIds": [],
                "inferenceReason": "value \"" + preview + "\" appears dynamic"
            }
        });
    }
    return inputs;
}

"""Inject postcondition assert steps after navigation and submit events.
After navigation: url_includes with confidence 0.6.
After submit: text_present 'success' with confidence 0.4 (conservative — user should refine).
"""
def infer_assertions(events: list[any]) -> list[any] {
    assertions: list[any] = [];
    for evt in events {
        if not isinstance(evt, dict) { continue; }
        etype: str = str(evt.get("type", ""));
        if etype == "navigation" {
            pathname: str = extract_pathname(str(evt.get("url", "")));
            assertions.append({
                "id": new_step_id(),
                "type": "assert",
                "name": "Assert URL after navigation",
                "confidence": 0.6,
                "signal": {"kind": "url_includes", "value": pathname}
            });
        }
        if etype == "submit" {
            assertions.append({
                "id": new_step_id(),
                "type": "assert",
                "name": "Assert success after form submit",
                "confidence": 0.4,
                "signal": {"kind": "text_present", "text": "success"}
            });
        }
    }
    return assertions;
}

"""Infer conservative approval-required safety rules from high-stakes click targets.
Scans click steps for SAFETY_PATTERNS in the primary locator's text/label field.
All generated rules require_approval; users can downgrade in the workflow editor.
"""
def infer_safety_rules(steps: list[any]) -> list[any] {
    rules: list[any] = [];
    for step in steps {
        if not isinstance(step, dict) or str(step.get("type", "")) != "click" {
            continue;
        }
        target: any = step.get("target", {});
        if not isinstance(target, dict) { continue; }
        primary: any = target.get("primary", {});
        if not isinstance(primary, dict) { continue; }
        kind: str = str(primary.get("kind", ""));
        text: str = "";
        if kind == "text" { text = str(primary.get("text", "")); }
        elif kind == "label" { text = str(primary.get("label", "")); }
        if not text { continue; }
        text_lower: str = text.lower();
        matched: bool = False;
        for pattern in SAFETY_PATTERNS {
            if pattern in text_lower {
                matched = True;
                break;
            }
        }
        if matched {
            rules.append({
                "id": new_rule_id(),
                "description": "Require approval before clicking \"" + text + "\"",
                "condition": {"kind": "target_text_contains", "value": text},
                "action": "require_approval"
            });
        }
    }
    return rules;
}

# ============================================================
# COMPILER CORE
# ============================================================

"""Build a TargetSpec dict from element metadata using semantic locator priority.
Click priority:  label > innerText > placeholder > name > testId > id > css
Fill priority:   label > placeholder > name > id > css  (no innerText)
Returns None if no usable locator is found.
"""
def build_target_spec(el: dict[str, any], for_click: bool) -> dict[str, any] | None {
    label: str = str(el.get("label", ""));
    inner_text: str = str(el.get("innerText", ""));
    placeholder: str = str(el.get("placeholder", ""));
    name: str = str(el.get("name", ""));
    test_id: str = str(el.get("testId", ""));
    el_id: str = str(el.get("id", ""));
    css_selector: str = str(el.get("cssSelector", ""));

    primary: dict[str, any] | None = None;
    if label {
        primary = {"kind": "label", "label": label};
    } elif for_click and inner_text {
        primary = {"kind": "text", "text": inner_text[:60]};
    } elif placeholder {
        primary = {"kind": "placeholder", "placeholder": placeholder};
    } elif name {
        primary = {"kind": "name", "name": name};
    } elif test_id {
        primary = {"kind": "testid", "testId": test_id};
    } elif el_id {
        primary = {"kind": "css", "selector": "#" + el_id};
    } elif css_selector {
        primary = {"kind": "css", "selector": css_selector};
    }

    if primary is None { return None; }

    spec: dict[str, any] = {"primary": primary};
    hints: dict[str, any] = {};
    nearby: any = el.get("nearbyText", None);
    if nearby and isinstance(nearby, list) { hints["nearbyText"] = nearby; }
    heading: str = str(el.get("sectionHeading", ""));
    if heading { hints["sectionHeading"] = heading; }
    form_name: str = str(el.get("formName", ""));
    if form_name { hints["formName"] = form_name; }
    if hints { spec["resolutionHints"] = hints; }
    return spec;
}

"""Map a single cleaned event to its workflow step dict.
navigation → goto | click → click | input/change → fill | annotation → None
Returns None when no valid locator exists or the event type produces no step.
"""
def event_to_step(event: dict[str, any]) -> dict[str, any] | None {
    if not isinstance(event, dict) { return None; }
    etype: str = str(event.get("type", ""));
    step_id: str = new_step_id();

    if etype == "navigation" {
        url: str = str(event.get("url", ""));
        if not url { return None; }
        return {"id": step_id, "type": "goto", "url": url};
    }

    if etype == "click" {
        el: any = event.get("element", {});
        if not isinstance(el, dict) { return None; }
        target: dict[str, any] | None = build_target_spec(el, True);
        if target is None { return None; }
        return {"id": step_id, "type": "click", "target": target};
    }

    if etype == "input" or etype == "change" {
        el = event.get("element", {});
        if not isinstance(el, dict) { return None; }
        target = build_target_spec(el, False);
        if target is None { return None; }
        masked: bool = bool(event.get("masked", False));
        value_spec: dict[str, any];
        if masked {
            secret_key: str = str(el.get("name", "") or el.get("label", "") or "unknown");
            value_spec = {"kind": "secret", "secretKey": secret_key};
        } else {
            literal_val: str = str(event.get("value", ""));
            value_spec = {"kind": "literal", "value": literal_val};
        }
        return {"id": step_id, "type": "fill", "target": target, "value": value_spec};
    }

    # annotation and unrecognized types produce no step
    return None;
}

"""Collect unique domain hostnames from all event URLs."""
def collect_domains(events: list[any]) -> list[str] {
    seen: set[str] = set();
    domains: list[str] = [];
    for evt in events {
        if not isinstance(evt, dict) { continue; }
        url: str = str(evt.get("url", ""));
        if url {
            host: str = extract_hostname(url);
            if host and host not in seen {
                seen.add(host);
                domains.append(host);
            }
        }
    }
    return domains;
}

"""Compile a cleaned trace into a partial Workflow IR using heuristics only.
Does not call any model. Assembles steps, asserts, inputs, safety, and metadata.
"""
def heuristic_compile(
    session: dict[str, any],
    cleaned: dict[str, any],
    options: dict[str, any]
) -> dict[str, any] {
    clean_events: list[any] = [];
    candidate: any = cleaned.get("events", []);
    if isinstance(candidate, list) { clean_events = candidate; }

    step_origins: list[any] = [];
    steps: list[any] = [];

    for evt in clean_events {
        step: any = event_to_step(evt);
        if step is not None {
            steps.append(step);
            step_origins.append({
                "stepId": str(step.get("id", "")),
                "sourceEventIds": [str(evt.get("id", ""))]
            });
        }
    }

    # Append inferred assertion steps after all action steps
    for a in infer_assertions(clean_events) {
        steps.append(a);
    }

    inferred_inputs: list[any] = infer_inputs(clean_events);
    inferred_rules: list[any] = infer_safety_rules(steps);
    domains: list[str] = collect_domains(clean_events);

    session_id: str = str(session.get("id", ""));
    goal: str = str(session.get("goalContext", ""));
    user_explanation: str = str(session.get("userExplanation", ""));
    start_url: str = str(session.get("startUrl", ""));
    created_by: str = str(options.get("createdByUserId", ""));
    privacy: any = options.get("privacy", {});
    if not isinstance(privacy, dict) { privacy = {}; }
    now: str = timestamp_now();
    user_context: list[any] = [];
    if goal { user_context.append(goal); }
    if user_explanation and user_explanation != goal { user_context.append(user_explanation); }

    safety: dict[str, any] = {
        "allowedDomains": domains,
        "requireApprovalFor": ["final_submit", "delete", "purchase"],
        "customRules": inferred_rules
    };

    return {
        "version": "1.0",
        "id": new_workflow_id(),
        "name": goal if goal else "Untitled workflow",
        "metadata": {
            "createdAt": now,
            "updatedAt": now,
            "createdByUserId": created_by,
            "source": {
                "recordingSessionId": session_id,
                "origin": "browser-recording",
                "startUrl": start_url,
                "domains": domains
            }
        },
        "context": {
            "goal": goal,
            "userProvidedContext": user_context
        },
        "inputs": inferred_inputs,
        "steps": steps,
        "safety": safety,
        "privacy": privacy,
        "compileInfo": {
            "compilerVersion": COMPILER_VERSION,
            "compiledAt": now,
            "sourceTraceId": session_id,
            "stepOrigins": step_origins
        }
    };
}

"""R: Build compile privacy settings with optional Kimi enrichment enabled.
M: Reads the local Kimi provider config and toggles compile-time LLM usage when credentials are available.
E: Falls back to deterministic-only compilation when the provider is not configured.
"""
def build_privacy_settings(privacy_mode: str = "local") -> dict[str, any] {
    runtime_state: dict[str, any] = current_runtime_state();
    kimi_config: dict[str, any] = resolve_kimi_compile_config();
    allow_compile: bool = bool(runtime_state.get("active", False));

    return {
        "mode": privacy_mode,
        "llmUsage": {
            "provider": str(runtime_state.get("provider", kimi_config.get("provider", ""))),
            "model": str(runtime_state.get("model", kimi_config.get("model", ""))),
            "allowDuringCompile": allow_compile,
            "allowDuringRepair": False,
            "allowRawDomInRepair": False
        }
    };
}

"""R: Attach the default provider-backed model hook to compile options when available.
M: Injects the Jac-native Kimi adapter into `model_fn` only if the caller did not already provide one.
E: Leaves options untouched when compile-time LLM use is disabled.
"""
def prepare_compile_options(options: dict[str, any]) -> dict[str, any] {
    prepared: dict[str, any] = dict(options);
    privacy: any = prepared.get("privacy", {});
    llm_usage: any = privacy.get("llmUsage", {}) if isinstance(privacy, dict) else {};
    allow_compile: bool = bool(llm_usage.get("allowDuringCompile", False)) if isinstance(llm_usage, dict) else False;

    if allow_compile and prepared.get("model_fn") is None {
        prepared["model_fn"] = kimi_compile_enrichment;
    }

    return prepared;
}

"""Merge an optional model-enriched partial workflow into the heuristic result.
Model fills gaps only — it never overwrites heuristic-derived structure.
Enrichment: context.summary, context.successCriteria, step name, step confidence.
"""
def merge_model_result(
    partial: dict[str, any],
    model_result: dict[str, any]
) -> dict[str, any] {
    if not isinstance(model_result, dict) { return partial; }

    ctx: dict[str, any] = dict(partial.get("context", {}));
    model_ctx: any = model_result.get("context", {});
    if isinstance(model_ctx, dict) {
        if not ctx.get("summary") and model_ctx.get("summary") {
            ctx["summary"] = str(model_ctx["summary"]);
        }
        if not ctx.get("successCriteria") and model_ctx.get("successCriteria") {
            ctx["successCriteria"] = model_ctx["successCriteria"];
        }
    }

    heuristic_steps: list[any] = list(partial.get("steps", []));
    model_steps: any = model_result.get("steps", []);
    merged_steps: list[any] = [];

    for (i, step) in enumerate(heuristic_steps) {
        if not isinstance(step, dict) {
            merged_steps.append(step);
            continue;
        }
        if isinstance(model_steps, list) and i < len(model_steps) {
            model_step: any = model_steps[i];
            if (isinstance(model_step, dict) and
                model_step.get("type") == step.get("type")) {
                merged: dict[str, any] = dict(step);
                if not merged.get("name") and model_step.get("name") {
                    merged["name"] = str(model_step["name"]);
                }
                if (merged.get("confidence") is None and
                    model_step.get("confidence") is not None) {
                    merged["confidence"] = model_step["confidence"];
                }
                merged_steps.append(merged);
                continue;
            }
        }
        merged_steps.append(step);
    }

    compile_info: dict[str, any] = dict(partial.get("compileInfo", {}));
    model_meta: any = model_result.get("model", {});
    if isinstance(model_meta, dict) {
        compile_info["modelEnrichment"] = {
            "provider": str(model_meta.get("provider", "")),
            "model": str(model_meta.get("model", "")),
            "thinking_mode": str(model_meta.get("thinking_mode", ""))
        };
    }

    return {
        **partial,
        "context": ctx,
        "steps": merged_steps,
        "compileInfo": compile_info
    };
}

# ============================================================
# VALIDATION
# ============================================================

"""Validate a compiled workflow dict against the required structural contract.
Returns {ok: True, workflow: ...} or {ok: False, errors: [...]}.
Checks: required top-level fields, version string, metadata sub-fields,
context.goal, inputs/steps are lists, compileInfo sub-fields.
"""
def validate_workflow(candidate: dict[str, any]) -> dict[str, any] {
    if not isinstance(candidate, dict) {
        return {"ok": False, "errors": ["workflow must be a dict"]};
    }
    errors: list[str] = [];

    required_top: list[str] = [
        "version", "id", "name", "metadata", "context",
        "inputs", "steps", "safety", "privacy", "compileInfo"
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
        for mf in ["createdAt", "updatedAt", "createdByUserId", "source"] {
            if mf not in metadata {
                errors.append("metadata." + mf + ": required field is missing");
            }
        }
        source: any = metadata.get("source", {});
        if isinstance(source, dict) {
            for sf in ["recordingSessionId", "origin", "domains"] {
                if sf not in source {
                    errors.append("metadata.source." + sf + ": required field is missing");
                }
            }
        }
    }

    context: any = candidate.get("context", {});
    if isinstance(context, dict) and "goal" not in context {
        errors.append("context.goal: required field is missing");
    }

    if not isinstance(candidate.get("inputs"), list) {
        errors.append("inputs: must be a list");
    }
    if not isinstance(candidate.get("steps"), list) {
        errors.append("steps: must be a list");
    }

    compile_info: any = candidate.get("compileInfo", {});
    if isinstance(compile_info, dict) {
        for cf in ["compilerVersion", "compiledAt", "sourceTraceId"] {
            if cf not in compile_info {
                errors.append("compileInfo." + cf + ": required field is missing");
            }
        }
    }

    if errors {
        return {"ok": False, "errors": errors};
    }
    return {"ok": True, "workflow": candidate};
}

# ============================================================
# SEGMENTED VALIDATION
# ============================================================

"""R: Validate a compiled segmented artifact against the required structural contract.
M: Checks required top-level fields, segment blocks, continuation, stop_policy, compileInfo.
E: Returns {ok: True, artifact} or {ok: False, errors: []}.
   Does not validate event semantics — structural requirements only.
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
        for mf in ["createdAt", "updatedAt", "createdByUserId", "source"] {
            if mf not in metadata {
                errors.append("metadata." + mf + ": required field is missing");
            }
        }
        source: any = metadata.get("source", {});
        if isinstance(source, dict) {
            for sf in ["recordingId", "origin", "domains"] {
                if sf not in source {
                    errors.append("metadata.source." + sf + ": required field is missing");
                }
            }
        }
    }

    for seg_name in ["one_time", "repeated"] {
        seg: any = candidate.get(seg_name, {});
        if not isinstance(seg, dict) {
            errors.append(seg_name + ": must be a dict");
        } else {
            if not isinstance(seg.get("inputs"), list) {
                errors.append(seg_name + ".inputs: must be a list");
            }
            if not isinstance(seg.get("steps"), list) {
                errors.append(seg_name + ".steps: must be a list");
            }
            if not isinstance(seg.get("annotations"), list) {
                errors.append(seg_name + ".annotations: must be a list");
            }
        }
    }

    cont: any = candidate.get("continuation", {});
    if not isinstance(cont, dict) {
        errors.append("continuation: must be a dict");
    } elif not isinstance(cont.get("strategy"), list) {
        errors.append("continuation.strategy: must be a list");
    }

    sp: any = candidate.get("stop_policy", {});
    if not isinstance(sp, dict) {
        errors.append("stop_policy: must be a dict");
    } else {
        if "mode" not in sp {
            errors.append("stop_policy.mode: required field is missing");
        }
        if "options" not in sp {
            errors.append("stop_policy.options: required field is missing");
        }
    }

    ci: any = candidate.get("compileInfo", {});
    if isinstance(ci, dict) {
        for cf in ["compilerVersion", "compiledAt", "sourceRecordingId"] {
            if cf not in ci {
                errors.append("compileInfo." + cf + ": required field is missing");
            }
        }
    }

    if errors {
        return {"ok": False, "errors": errors};
    }
    return {"ok": True, "artifact": candidate};
}

# ============================================================
# SEGMENTED COMPILER
# ============================================================

"""R: Compile one recording segment into a compiled block using existing heuristics.
M: Cleans events independently, maps to steps, infers inputs/assertions/safety.
E: Empty events produce a structurally valid block with empty lists.
   label ("one_time" or "repeated") is used only in warning messages.
"""
def compile_one_segment(
    events: list[any],
    annotations: list[any],
    label: str
) -> dict[str, any] {
    clean_result: dict[str, any] = clean_segment_events(events);
    clean_events: list[any] = clean_result["events"];
    removed: list[any] = clean_result["removed"];

    steps: list[any] = [];
    step_origins: list[any] = [];

    for evt in clean_events {
        step: any = event_to_step(evt);
        if step is not None {
            steps.append(step);
            step_origins.append({
                "stepId": str(step.get("id", "")),
                "sourceEventIds": [str(evt.get("id", ""))]
            });
        }
    }

    for a in infer_assertions(clean_events) {
        steps.append(a);
    }

    seg_inputs: list[any] = infer_inputs(clean_events);
    seg_safety: list[any] = infer_safety_rules(steps);

    seg_warnings: list[str] = [];
    for r in removed {
        if isinstance(r, dict) {
            seg_warnings.append(
                label + ": removed event " + str(r.get("id", "")) +
                ": " + str(r.get("reason", ""))
            );
        }
    }

    safe_anns: list[any] = [];
    if isinstance(annotations, list) {
        safe_anns = annotations;
    }

    return {
        "inputs": seg_inputs,
        "steps": steps,
        "annotations": safe_anns,
        "safety_rules": seg_safety,
        "step_origins": step_origins,
        "warnings": seg_warnings
    };
}

"""R: Compile a finished segmented recording into a CompiledArtifact.
M: Compiles one_time and repeated segments independently, carries through
   continuation and stop_policy unchanged, validates the assembled artifact.
E: Recordings not in 'finished' state produce a warning but still compile.
   Empty segments produce structurally valid empty blocks.
   Returns {ok, artifact, warnings} or {ok: False, errors, warnings}.
"""
def compile_segmented_recording(
    recording: dict[str, any],
    options: dict[str, any]
) -> dict[str, any] {
    warnings: list[str] = [];

    recording_id: str = str(recording.get("recording_id", ""));
    task_name: str = str(recording.get("task_name", ""));
    state: str = str(recording.get("state", ""));

    if state != "finished" {
        warnings.append("recording state is '" + state + "' (expected 'finished')");
    }

    segments: any = recording.get("segments", {});
    if not isinstance(segments, dict) { segments = {}; }

    one_time_seg: any = segments.get("one_time", {});
    if not isinstance(one_time_seg, dict) { one_time_seg = {}; }
    ot_events: list[any] = [];
    raw_ot: any = one_time_seg.get("events", []);
    if isinstance(raw_ot, list) { ot_events = raw_ot; }
    ot_anns: list[any] = [];
    raw_ot_anns: any = one_time_seg.get("annotations", []);
    if isinstance(raw_ot_anns, list) { ot_anns = raw_ot_anns; }

    repeated_seg: any = segments.get("repeated", {});
    if not isinstance(repeated_seg, dict) { repeated_seg = {}; }
    rep_events: list[any] = [];
    raw_rep: any = repeated_seg.get("events", []);
    if isinstance(raw_rep, list) { rep_events = raw_rep; }
    rep_anns: list[any] = [];
    raw_rep_anns: any = repeated_seg.get("annotations", []);
    if isinstance(raw_rep_anns, list) { rep_anns = raw_rep_anns; }

    compiled_ot: dict[str, any] = compile_one_segment(ot_events, ot_anns, "one_time");
    compiled_rep: dict[str, any] = compile_one_segment(rep_events, rep_anns, "repeated");

    for w in compiled_ot.get("warnings", []) { warnings.append(w); }
    for w in compiled_rep.get("warnings", []) { warnings.append(w); }

    continuation: any = recording.get("continuation", {"strategy": []});
    if not isinstance(continuation, dict) {
        continuation = {"strategy": []};
        warnings.append("continuation was not a dict; replaced with empty strategy");
    }

    stop_policy: any = recording.get("stop_policy", {"mode": "", "options": {}});
    if not isinstance(stop_policy, dict) {
        stop_policy = {"mode": "", "options": {}};
        warnings.append("stop_policy was not a dict; replaced with empty policy");
    }

    meta: any = recording.get("meta", {});
    if not isinstance(meta, dict) { meta = {}; }
    start_url: str = str(meta.get("start_url", ""));
    domains: list[any] = [];
    raw_domains: any = meta.get("domains", []);
    if isinstance(raw_domains, list) { domains = raw_domains; }
    user_goal: str = str(meta.get("user_goal", ""));

    if not domains {
        all_events: list[any] = ot_events + rep_events;
        domains = collect_domains(all_events);
    }

    created_by: str = str(options.get("createdByUserId", ""));
    now: str = timestamp_now();

    wf_name: str = task_name;
    if not wf_name { wf_name = user_goal; }
    if not wf_name { wf_name = "Untitled workflow"; }

    artifact: dict[str, any] = {
        "version": "1.0",
        "id": new_workflow_id(),
        "name": wf_name,
        "recording_id": recording_id,
        "metadata": {
            "createdAt": now,
            "updatedAt": now,
            "createdByUserId": created_by,
            "source": {
                "recordingId": recording_id,
                "origin": "segmented-recording",
                "startUrl": start_url,
                "domains": domains
            }
        },
        "one_time": {
            "inputs": compiled_ot["inputs"],
            "steps": compiled_ot["steps"],
            "annotations": compiled_ot["annotations"],
            "safety_rules": compiled_ot["safety_rules"]
        },
        "repeated": {
            "inputs": compiled_rep["inputs"],
            "steps": compiled_rep["steps"],
            "annotations": compiled_rep["annotations"],
            "safety_rules": compiled_rep["safety_rules"]
        },
        "continuation": continuation,
        "stop_policy": stop_policy,
        "compileInfo": {
            "compilerVersion": COMPILER_VERSION,
            "compiledAt": now,
            "sourceRecordingId": recording_id,
            "stepOrigins": {
                "one_time": compiled_ot.get("step_origins", []),
                "repeated": compiled_rep.get("step_origins", [])
            },
            "warnings": warnings
        }
    };

    validation: dict[str, any] = validate_compiled_artifact(artifact);
    if not bool(validation.get("ok", False)) {
        return {
            "ok": False,
            "errors": validation.get("errors", []),
            "warnings": warnings
        };
    }

    return {"ok": True, "artifact": artifact, "warnings": warnings};
}

# ============================================================
# SESSION ORCHESTRATOR
# ============================================================

"""Compile a recording session dict into a validated Workflow IR.
Pipeline: clean → heuristic compile → optional model hook → validate.
Model hook: set options['model_fn'] = fn(raw_session, session, cleaned, partial, options) -> dict
           and options['privacy']['llmUsage']['allowDuringCompile'] = True.
Returns {ok, workflow, warnings} or {ok, errors, warnings}.
"""
def compile_session(
    raw_session: dict[str, any],
    options: dict[str, any]
) -> dict[str, any] {
    warnings: list[str] = [];
    prepared_options: dict[str, any] = prepare_compile_options(options);

    normalized_session: dict[str, any] = normalize_compiler_session(raw_session);
    if not normalized_session {
        return {
            "ok": False,
            "errors": ["session normalization failed"],
            "warnings": warnings
        };
    }

    # 1. Clean
    cleaned: dict[str, any] = clean_trace(normalized_session);
    for r in cleaned.get("removedEventIds", []) {
        if isinstance(r, dict) {
            warnings.append(
                "Removed event " + str(r.get("id", "")) + ": " + str(r.get("reason", ""))
            );
        }
    }

    # 2. Heuristic compile
    partial: dict[str, any] = heuristic_compile(normalized_session, cleaned, options);

    # 3. Optional model enrichment (caller injects via model_fn)
    model_fn: any = prepared_options.get("model_fn", None);
    privacy: any = prepared_options.get("privacy", {});
    llm_usage: any = privacy.get("llmUsage", {}) if isinstance(privacy, dict) else {};
    allow_llm: bool = bool(llm_usage.get("allowDuringCompile", False)) if isinstance(llm_usage, dict) else False;

    if model_fn is not None and allow_llm {
        try {
            model_result: any = model_fn(raw_session, normalized_session, cleaned, partial, prepared_options);
            if isinstance(model_result, dict) {
                partial = merge_model_result(partial, model_result);
                model_warning: str = str(model_result.get("_warning", ""));
                if model_warning {
                    warnings.append(model_warning);
                }
            }
        } except Exception as e {
            warnings.append("Model enrichment failed: " + str(e));
        }
    }

    # 4. Validate
    validation: dict[str, any] = validate_workflow(partial);
    if not bool(validation.get("ok", False)) {
        return {
            "ok": False,
            "errors": validation.get("errors", []),
            "warnings": warnings
        };
    }

    return {"ok": True, "workflow": validation["workflow"], "warnings": warnings};
}

# ============================================================
# CLI HANDLERS
# ============================================================

"""Build command: load a trace, compile it, and persist the resulting workflow.
Payload keys: session_id (required), created_by (default: 'cli'),
              privacy_mode (default: 'local').
"""
def build_workflow(payload: dict[str, any]) -> dict[str, any] {
    ensure_workflow_dir();

    session_id: str = str(payload.get("session_id", ""));
    if not session_id {
        return {"ok": False, "error": "session_id is required"};
    }

    trace_data: dict[str, any] = read_json(trace_file(session_id));
    if not trace_data {
        return {"ok": False, "error": "trace not found", "session_id": session_id};
    }

    user_explanation: str = str(payload.get("user_explanation", "") or "").strip();
    if user_explanation {
        trace_data["userExplanation"] = user_explanation;
        current_goal: str = str(trace_data.get("goalContext", "") or "").strip();
        current_title: str = str(trace_data.get("title", "") or "").strip();
        if not current_goal and (not current_title or current_title == "Manual Trace") {
            trace_data["goalContext"] = user_explanation;
        }
    }

    created_by: str = str(payload.get("created_by", "cli"));
    privacy_mode: str = str(payload.get("privacy_mode", "local"));

    options: dict[str, any] = {
        "createdByUserId": created_by,
        "privacy": build_privacy_settings(privacy_mode)
    };

    result: dict[str, any] = compile_session(trace_data, options);
    if not bool(result.get("ok", False)) {
        return {
            "ok": False,
            "error": "compilation failed",
            "errors": result.get("errors", []),
            "warnings": result.get("warnings", [])
        };
    }

    workflow: dict[str, any] = result["workflow"];
    workflow_id: str = str(workflow.get("id", "wf_unknown"));
    wf_path: str = workflow_file(workflow_id);
    write_json(wf_path, workflow);

    return {
        "ok": True,
        "workflow_id": workflow_id,
        "workflow_file": wf_path,
        "step_count": len(workflow.get("steps", [])),
        "input_count": len(workflow.get("inputs", [])),
        "warnings": result.get("warnings", [])
    };
}

"""Get command: retrieve a compiled workflow JSON by workflow_id."""
def get_workflow(payload: dict[str, any]) -> dict[str, any] {
    workflow_id: str = str(payload.get("workflow_id", ""));
    if not workflow_id {
        return {"ok": False, "error": "workflow_id is required"};
    }
    data: dict[str, any] = read_json(workflow_file(workflow_id));
    if not data {
        return {"ok": False, "error": "workflow not found", "workflow_id": workflow_id};
    }
    return {"ok": True, "workflow": data};
}

"""Dry-run command: compile a session from an inline trace dict without persisting.
Payload key: session (dict with id, events, etc.)
"""
def dry_run_compile(payload: dict[str, any]) -> dict[str, any] {
    session: any = payload.get("session", {});
    if not isinstance(session, dict) or not session.get("id") {
        return {"ok": False, "error": "payload.session with id is required"};
    }

    options: dict[str, any] = {
        "createdByUserId": str(payload.get("created_by", "dry_run")),
        "privacy": build_privacy_settings("local")
    };

    result: dict[str, any] = compile_session(session, options);
    return result;
}

"""R: Dry-run compile a segmented recording from an inline dict without persisting.
M: Expects payload.recording with recording_id and segments; delegates to compile_segmented_recording.
E: Returns {ok, artifact, warnings} or {ok: False, error}.
"""
def dry_run_compile_segmented(payload: dict[str, any]) -> dict[str, any] {
    recording: any = payload.get("recording", {});
    if not isinstance(recording, dict) or not recording.get("recording_id") {
        return {"ok": False, "error": "payload.recording with recording_id is required"};
    }

    options: dict[str, any] = {
        "createdByUserId": str(payload.get("created_by", "dry_run")),
        "privacy": {
            "mode": "local",
            "llmUsage": {
                "allowDuringCompile": False,
                "allowDuringRepair": False,
                "allowRawDomInRepair": False
            }
        }
    };

    return compile_segmented_recording(recording, options);
}

"""R: Build command for segmented recordings: load from disk, compile, and persist the artifact.
M: Reads recording JSON from RECORDING_DIR, compiles via compile_segmented_recording, writes artifact to WORKFLOW_DIR.
E: Fails if recording_id is missing or the recording file is not found.
"""
def build_segmented(payload: dict[str, any]) -> dict[str, any] {
    ensure_workflow_dir();

    recording_id: str = str(payload.get("recording_id", ""));
    if not recording_id {
        return {"ok": False, "error": "recording_id is required"};
    }

    rec_path: str = RECORDING_DIR + "/" + recording_id + ".json";
    recording_data: dict[str, any] = read_json(rec_path);
    if not recording_data {
        return {"ok": False, "error": "recording not found", "recording_id": recording_id};
    }

    created_by: str = str(payload.get("created_by", "cli"));
    options: dict[str, any] = {
        "createdByUserId": created_by,
        "privacy": {
            "mode": "local",
            "llmUsage": {
                "allowDuringCompile": False,
                "allowDuringRepair": False,
                "allowRawDomInRepair": False
            }
        }
    };

    result: dict[str, any] = compile_segmented_recording(recording_data, options);
    if not bool(result.get("ok", False)) {
        return {
            "ok": False,
            "error": "segmented compilation failed",
            "errors": result.get("errors", []),
            "warnings": result.get("warnings", [])
        };
    }

    artifact: dict[str, any] = result["artifact"];
    artifact_id: str = str(artifact.get("id", "wf_unknown"));
    artifact_path: str = workflow_file(artifact_id);
    write_json(artifact_path, artifact);

    return {
        "ok": True,
        "artifact_id": artifact_id,
        "artifact_file": artifact_path,
        "one_time_step_count": len(artifact.get("one_time", {}).get("steps", [])),
        "repeated_step_count": len(artifact.get("repeated", {}).get("steps", [])),
        "warnings": result.get("warnings", [])
    };
}

"""Route a CLI command to the appropriate handler."""
def dispatch(command: str, payload: dict[str, any]) -> dict[str, any] {
    if command == "build" { return build_workflow(payload); }
    if command == "get" { return get_workflow(payload); }
    if command == "dry_run" { return dry_run_compile(payload); }
    if command == "build_segmented" { return build_segmented(payload); }
    if command == "dry_run_segmented" { return dry_run_compile_segmented(payload); }
    return {
        "ok": False,
        "error": "unknown command",
        "valid_commands": ["build", "get", "dry_run", "build_segmented", "dry_run_segmented"]
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

# ============================================================
# ENTRY POINT
# ============================================================

with entry {
    command: str = "";
    if len(sys.argv) > 1 {
        command = str(sys.argv[1]);
    }
    if should_dispatch_cli(command) {
        payload: dict[str, any] = parse_payload();
        result: dict[str, any] = dispatch(command, payload);
        print(json.dumps(result));
    }
}
