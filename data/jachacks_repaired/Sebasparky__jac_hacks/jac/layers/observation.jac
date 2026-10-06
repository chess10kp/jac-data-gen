import os;
import sys;
import json;
import time;
import from jac.layers.trace_utils { trace_file, read_trace }

glob DATA_ROOT: str = "./jac/layer_data";
glob TRACE_DIR: str = DATA_ROOT + "/traces";
glob DEDUPE_WINDOW_SECONDS: float = 0.7;

glob ALLOWED_EVENT_TYPES: list[str] = [
    "navigate",
    "click",
    "input",
    "submit",
    "network",
    "scroll",
    "session_state",
    "page_semantic",
    "dom_snapshot",
    "screenshot",
    "page_ready",
    "tab_created",
    "tab_closed",
    "tab_switched",
    "unknown"
];

glob SENSITIVE_HINTS: list[str] = [
    "password",
    "passcode",
    "token",
    "secret",
    "auth",
    "session",
    "cookie",
    "credit",
    "card",
    "ssn"
];

"""R: Return a timestamp string for persisted layer records.
M: Uses `time.time()` and string-casts for broad Jac compatibility.
E: Resolution is seconds with fractional precision.
"""
def timestamp_now() -> str {
    return str(time.time());
}

"""R: Coerce values to bounded strings for safe trace persistence.
M: String-casts, trims, and caps length to avoid oversized events.
E: None maps to empty string.
"""
def safe_str(value: any, max_len: int) -> str {
    text = str(value or "").strip();
    if len(text) > max_len {
        return text[:max_len];
    }
    return text;
}

"""R: Parse a float from arbitrary input.
M: Attempts `float(raw)` and falls back to zero on invalid values.
E: Invalid numbers return 0.0.
"""
def safe_float(raw: any) -> float {
    try {
        return float(raw);
    } except ValueError {
        return 0.0;
    } except TypeError {
        return 0.0;
    }
}

"""R: Parse an int from arbitrary input.
M: Attempts `int(raw)` and falls back to zero on invalid values.
E: Invalid numbers return 0.
"""
def safe_int(raw: any) -> int {
    try {
        return int(raw);
    } except ValueError {
        return 0;
    } except TypeError {
        return 0;
    }
}

"""R: Recursively sanitize JSON-like values for trace persistence.
M: Bounds nesting depth, collection size, and string length.
E: Unsupported values are string-cast and truncated.
"""
def sanitize_json_value(raw: any, depth: int, max_items: int, max_len: int) -> any {
    if depth <= 0 {
        return safe_str(raw, max_len);
    }

    if isinstance(raw, dict) {
        normalized: dict[str, any] = {};
        count: int = 0;
        for key in raw {
            if count >= max_items {
                break;
            }
            safe_key: str = safe_str(key, 80);
            normalized[safe_key] = sanitize_json_value(raw[key], depth - 1, max_items, max_len);
            count += 1;
        }
        return normalized;
    }

    if isinstance(raw, list) {
        normalized_list: list[any] = [];
        count: int = 0;
        for item in raw {
            if count >= max_items {
                break;
            }
            normalized_list.append(sanitize_json_value(item, depth - 1, max_items, max_len));
            count += 1;
        }
        return normalized_list;
    }

    if isinstance(raw, bool) or isinstance(raw, int) or isinstance(raw, float) {
        return raw;
    }

    return safe_str(raw, max_len);
}

"""R: Ensure observation trace storage path exists.
M: Creates `jac/layer_data/traces` recursively.
E: Safe to call repeatedly.
"""
def ensure_trace_dir() {
    os.makedirs(TRACE_DIR, exist_ok=True);
}

"""R: Validate session id format for filesystem-safe trace names.
M: Allows letters, digits, `_`, and `-`.
E: Empty ids are invalid.
"""
def is_valid_session_id(session_id: str) -> bool {
    if not session_id {
        return False;
    }

    for char in session_id {
        is_lower = (char >= "a") and (char <= "z");
        is_upper = (char >= "A") and (char <= "Z");
        is_digit = (char >= "0") and (char <= "9");
        if not (is_lower or is_upper or is_digit or char == "_" or char == "-") {
            return False;
        }
    }
    return True;
}

"""R: Parse JSON payload passed via CLI args.
M: Joins argv entries from index 2 and decodes JSON.
E: Invalid JSON returns an empty dict.
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

"""R: Persist one observation trace JSON record.
M: Writes formatted JSON to the session file path.
E: Propagates filesystem errors to caller.
"""
def write_trace(session_id: str, trace_data: dict[str, any]) {
    ensure_trace_dir();
    with open(trace_file(session_id), "w") as file {
        json.dump(trace_data, file, indent=2);
    }
}

"""R: Create deterministic session ids for trace files.
M: Prefixes a time-derived numeric stamp with `sess_`.
E: Collisions are unlikely but possible under extreme concurrency.
"""
def new_session_id() -> str {
    return "sess_" + str(time.time()).replace(".", "");
}

"""R: Check whether an event type is in the allowed schema.
M: Uses fixed allow-list used by the observation layer.
E: Unknown types are treated as invalid.
"""
def is_allowed_event_type(event_type: str) -> bool {
    return event_type in ALLOWED_EVENT_TYPES;
}

"""R: Normalize target payload to stable string fields.
M: Copies supported target keys with bounded string lengths.
E: Missing/non-dict targets produce empty defaults.
"""
def normalize_target(raw_target: any) -> dict[str, str] {
    target: dict[str, str] = {
        "tag": "",
        "id": "",
        "name": "",
        "role": "",
        "type": "",
        "label": "",
        "text": "",
        "placeholder": "",
        "class_name": "",
        "path": ""
    };

    if not isinstance(raw_target, dict) {
        return target;
    }

    target["tag"] = safe_str(raw_target.get("tag", ""), 60).lower();
    target["id"] = safe_str(raw_target.get("id", ""), 120);
    target["name"] = safe_str(raw_target.get("name", ""), 120);
    target["role"] = safe_str(raw_target.get("role", ""), 80).lower();
    target["type"] = safe_str(raw_target.get("type", ""), 40).lower();
    target["label"] = safe_str(raw_target.get("label", ""), 140);
    target["text"] = safe_str(raw_target.get("text", ""), 180);
    target["placeholder"] = safe_str(raw_target.get("placeholder", ""), 140);
    target["class_name"] = safe_str(raw_target.get("class_name", ""), 220);
    target["path"] = safe_str(raw_target.get("path", ""), 300);

    return target;
}

"""R: Normalize metadata payload for consistent analytics fields.
M: Copies known metadata keys and string/number coercions.
E: Unknown metadata keys are dropped for schema stability.
"""
def normalize_meta(raw_meta: any) -> dict[str, any] {
    normalized: dict[str, any] = {
        "source": "",
        "trigger": "",
        "tab_id": "",
        "kind": "",
        "method": "",
        "request_url": "",
        "initiator_type": "",
        "content_type": "",
        "status": 0,
        "ok": False,
        "duration_ms": 0,
        "error": ""
    };

    if not isinstance(raw_meta, dict) {
        return normalized;
    }

    normalized["source"] = safe_str(raw_meta.get("source", ""), 60);
    normalized["trigger"] = safe_str(raw_meta.get("trigger", ""), 60);
    normalized["tab_id"] = safe_str(raw_meta.get("tab_id", ""), 80);
    normalized["kind"] = safe_str(raw_meta.get("kind", ""), 40);
    normalized["method"] = safe_str(raw_meta.get("method", ""), 20).upper();
    normalized["request_url"] = safe_str(raw_meta.get("request_url", ""), 300);
    normalized["initiator_type"] = safe_str(raw_meta.get("initiator_type", ""), 40);
    normalized["content_type"] = safe_str(raw_meta.get("content_type", ""), 120);
    normalized["status"] = safe_int(raw_meta.get("status", 0));
    normalized["ok"] = bool(raw_meta.get("ok", False));
    normalized["duration_ms"] = safe_int(raw_meta.get("duration_ms", 0));
    normalized["error"] = safe_str(raw_meta.get("error", ""), 160);

    return normalized;
}

"""R: Normalize viewport/scroll telemetry for safe persistence.
M: Keeps common numeric viewport fields and truncates extra data conservatively.
E: Missing/non-dict payloads return empty defaults.
"""
def normalize_viewport(raw_viewport: any) -> dict[str, any] {
    normalized: dict[str, any] = {
        "scroll_x": 0,
        "scroll_y": 0,
        "viewport_width": 0,
        "viewport_height": 0,
        "document_width": 0,
        "document_height": 0,
        "scroll_progress": 0.0
    };

    if not isinstance(raw_viewport, dict) {
        return normalized;
    }

    normalized["scroll_x"] = safe_int(raw_viewport.get("scroll_x", 0));
    normalized["scroll_y"] = safe_int(raw_viewport.get("scroll_y", 0));
    normalized["viewport_width"] = safe_int(raw_viewport.get("viewport_width", 0));
    normalized["viewport_height"] = safe_int(raw_viewport.get("viewport_height", 0));
    normalized["document_width"] = safe_int(raw_viewport.get("document_width", 0));
    normalized["document_height"] = safe_int(raw_viewport.get("document_height", 0));
    normalized["scroll_progress"] = safe_float(raw_viewport.get("scroll_progress", 0));

    return normalized;
}

"""R: Normalize DOM snapshot payloads with bounded nested structure.
M: Preserves headings, form summaries, active element metadata, and HTML excerpts.
E: Large strings and lists are truncated for trace stability.
"""
def normalize_dom_snapshot(raw_snapshot: any) -> dict[str, any] {
    if not isinstance(raw_snapshot, dict) {
        return {};
    }
    return sanitize_json_value(raw_snapshot, 4, 16, 2800);
}

"""R: Normalize page/session introspection payloads with bounded nested structure.
M: Preserves cookies, storage previews, navigator info, and routing context.
E: Only page-visible/session-readable state can be captured.
"""
def normalize_session_state(raw_state: any) -> dict[str, any] {
    if not isinstance(raw_state, dict) {
        return {};
    }
    return sanitize_json_value(raw_state, 4, 18, 700);
}

"""R: Normalize semantic workflow/page descriptors.
M: Preserves lightweight heuristic context such as page kind, stage, actions, and headings.
E: Unknown/non-dict payloads map to empty dict.
"""
def normalize_semantic(raw_semantic: any) -> dict[str, any] {
    if not isinstance(raw_semantic, dict) {
        return {};
    }
    return sanitize_json_value(raw_semantic, 4, 18, 240);
}

"""R: Normalize network telemetry payloads for safe persistence.
M: Preserves request/response metadata, headers, sizes, and timing with bounded fields.
E: Payloads remain metadata-only; response bodies are not persisted.
"""
def normalize_network(raw_network: any) -> dict[str, any] {
    if not isinstance(raw_network, dict) {
        return {};
    }
    return sanitize_json_value(raw_network, 4, 18, 320);
}

"""R: Normalize screenshot telemetry payloads.
M: Preserves mime, dimensions, trigger, and one small captured image data URL.
E: Empty/non-dict payloads map to empty dict; image size is bounded.
"""
def normalize_screenshot(raw_screenshot: any) -> dict[str, any] {
    normalized: dict[str, any] = {
        "mime": "",
        "trigger": "",
        "width": 0,
        "height": 0,
        "data_url": "",
        "capture_error": ""
    };

    if not isinstance(raw_screenshot, dict) {
        return {};
    }

    normalized["mime"] = safe_str(raw_screenshot.get("mime", ""), 40);
    normalized["trigger"] = safe_str(raw_screenshot.get("trigger", ""), 40);
    normalized["width"] = safe_int(raw_screenshot.get("width", 0));
    normalized["height"] = safe_int(raw_screenshot.get("height", 0));
    normalized["data_url"] = safe_str(raw_screenshot.get("data_url", ""), 220000);
    normalized["capture_error"] = safe_str(raw_screenshot.get("capture_error", ""), 200);

    return normalized;
}

"""R: Determine if target hints suggest sensitive field content.
M: Checks target type and common secret-related label/name patterns.
E: Heuristic may over-redact ambiguous fields.
"""
def is_sensitive_target(target: dict[str, str]) -> bool {
    if target["type"] == "password" {
        return True;
    }

    haystack = (
        target["label"] + " " + target["name"] + " " + target["id"] + " " + target["placeholder"]
    ).lower();

    for hint in SENSITIVE_HINTS {
        if hint in haystack {
            return True;
        }
    }

    return False;
}

"""R: Convert untyped payloads into normalized observation events.
M: Enforces schema for type/url/target/meta and redacts sensitive values.
E: Unknown types are stored as `unknown`.
"""
def normalize_event(raw_event: any, default_url: str) -> dict[str, any] {
    event_type: str = "unknown";
    event_url: str = safe_str(default_url, 300);
    event_value: str = "";
    target: dict[str, str] = normalize_target({});
    meta: dict[str, any] = normalize_meta({});
    viewport: dict[str, any] = normalize_viewport({});
    dom_snapshot: dict[str, any] = {};
    session_state: dict[str, any] = {};
    semantic: dict[str, any] = {};
    network: dict[str, any] = {};
    screenshot: dict[str, any] = {};

    if isinstance(raw_event, dict) {
        event_type_candidate = safe_str(raw_event.get("type", ""), 40).lower();
        if is_allowed_event_type(event_type_candidate) {
            event_type = event_type_candidate;
        }

        raw_url = safe_str(raw_event.get("url", ""), 300);
        if raw_url {
            event_url = raw_url;
        }

        target = normalize_target(raw_event.get("target", {}));
        meta = normalize_meta(raw_event.get("meta", {}));
        viewport = normalize_viewport(raw_event.get("viewport", {}));
        dom_snapshot = normalize_dom_snapshot(raw_event.get("dom_snapshot", {}));
        session_state = normalize_session_state(raw_event.get("session_state", {}));
        semantic = normalize_semantic(raw_event.get("semantic", {}));
        network = normalize_network(raw_event.get("network", {}));
        screenshot = normalize_screenshot(raw_event.get("screenshot", {}));

        if "value" in raw_event {
            event_value = safe_str(raw_event.get("value", ""), 300);
        }
    }

    if is_sensitive_target(target) {
        event_value = "__redacted__";
    }

    return {
        "type": event_type,
        "url": event_url,
        "value": event_value,
        "target": target,
        "meta": meta,
        "viewport": viewport,
        "dom_snapshot": dom_snapshot,
        "session_state": session_state,
        "semantic": semantic,
        "network": network,
        "screenshot": screenshot,
        "recorded_at": timestamp_now()
    };
}

"""R: Build a stable comparison signature for event dedupe.
M: Concatenates key event fields likely to indicate duplicate actions.
E: Signature intentionally ignores timestamp and minor non-core metadata.
"""
def event_signature(event_data: dict[str, any]) -> str {
    target: dict[str, any] = event_data.get("target", {}) if isinstance(event_data.get("target", {}), dict) else {};
    meta: dict[str, any] = event_data.get("meta", {}) if isinstance(event_data.get("meta", {}), dict) else {};
    viewport: dict[str, any] = event_data.get("viewport", {}) if isinstance(event_data.get("viewport", {}), dict) else {};
    semantic: dict[str, any] = event_data.get("semantic", {}) if isinstance(event_data.get("semantic", {}), dict) else {};
    network: dict[str, any] = event_data.get("network", {}) if isinstance(event_data.get("network", {}), dict) else {};
    dom_snapshot: dict[str, any] = event_data.get("dom_snapshot", {}) if isinstance(event_data.get("dom_snapshot", {}), dict) else {};

    return (
        safe_str(event_data.get("type", ""), 40) + "|" +
        safe_str(event_data.get("url", ""), 300) + "|" +
        safe_str(event_data.get("value", ""), 300) + "|" +
        safe_str(target.get("tag", ""), 60) + "|" +
        safe_str(target.get("id", ""), 120) + "|" +
        safe_str(target.get("name", ""), 120) + "|" +
        safe_str(target.get("role", ""), 80) + "|" +
        safe_str(target.get("type", ""), 40) + "|" +
        safe_str(target.get("label", ""), 140) + "|" +
        safe_str(target.get("text", ""), 180) + "|" +
        safe_str(meta.get("source", ""), 60) + "|" +
        safe_str(meta.get("trigger", ""), 60) + "|" +
        safe_str(meta.get("tab_id", ""), 80) + "|" +
        safe_str(meta.get("kind", ""), 40) + "|" +
        safe_str(meta.get("method", ""), 20) + "|" +
        safe_str(meta.get("request_url", ""), 300) + "|" +
        str(safe_int(meta.get("status", 0))) + "|" +
        str(safe_int(viewport.get("scroll_y", 0))) + "|" +
        str(safe_float(viewport.get("scroll_progress", 0))) + "|" +
        safe_str(semantic.get("page_kind", ""), 80) + "|" +
        safe_str(semantic.get("workflow_stage", ""), 80) + "|" +
        safe_str(network.get("request_url", ""), 300) + "|" +
        safe_str(network.get("kind", ""), 40) + "|" +
        safe_str(dom_snapshot.get("target_path", ""), 300)
    );
}

"""R: Detect near-identical adjacent events to reduce trace noise.
M: Compares normalized signatures and timestamp delta.
E: Returns false when timestamps are missing or unparsable.
"""
def is_duplicate_event(last_event: dict[str, any], new_event: dict[str, any]) -> bool {
    last_time = safe_float(last_event.get("recorded_at", "0"));
    new_time = safe_float(new_event.get("recorded_at", "0"));
    if last_time <= 0.0 or new_time <= 0.0 {
        return False;
    }

    if abs(new_time - last_time) > DEDUPE_WINDOW_SECONDS {
        return False;
    }

    return event_signature(last_event) == event_signature(new_event);
}

"""R: Start a new observation recording session.
M: Builds initial trace payload and persists it to disk.
E: Optional `session_id` can overwrite an existing session file.
"""
def start_trace(payload: dict[str, any]) -> dict[str, any] {
    ensure_trace_dir();

    session_id = safe_str(payload.get("session_id", ""), 120);
    if not session_id {
        session_id = new_session_id();
    }

    if not is_valid_session_id(session_id) {
        return {"ok": False, "error": "invalid session_id format"};
    }

    title = safe_str(payload.get("title", "Manual Trace"), 140);
    source_url = safe_str(payload.get("url", ""), 300);
    now: str = timestamp_now();

    trace_data = {
        "session_id": session_id,
        "title": title,
        "source_url": source_url,
        "status": "recording",
        "started_at": now,
        "updated_at": now,
        "telemetry_counts": {},
        "events": []
    };

    write_trace(session_id, trace_data);

    return {
        "ok": True,
        "session_id": session_id,
        "trace_file": trace_file(session_id)
    };
}

"""R: Append one event to an active observation session.
M: Loads trace file, normalizes payload, dedupes noise, and rewrites JSON.
E: Missing session id or trace file returns explicit errors.
"""
def append_trace_event(payload: dict[str, any]) -> dict[str, any] {
    session_id = safe_str(payload.get("session_id", ""), 120);
    if not session_id {
        return {"ok": False, "error": "session_id is required"};
    }
    if not is_valid_session_id(session_id) {
        return {"ok": False, "error": "invalid session_id format"};
    }

    trace_data = read_trace(session_id);
    if not trace_data {
        return {"ok": False, "error": "trace not found", "session_id": session_id};
    }

    events: list[any] = [];
    raw_events = trace_data.get("events", []);
    if isinstance(raw_events, list) {
        events = raw_events;
    }

    normalized = normalize_event(payload.get("event", {}), safe_str(trace_data.get("source_url", ""), 300));

    if events and isinstance(events[-1], dict) and is_duplicate_event(events[-1], normalized) {
        trace_data["updated_at"] = timestamp_now();
        write_trace(session_id, trace_data);
        return {
            "ok": True,
            "session_id": session_id,
            "event_count": len(events),
            "deduped": True
        };
    }

    events.append(normalized);
    trace_data["events"] = events;
    trace_data["updated_at"] = timestamp_now();

    event_type = safe_str(normalized.get("type", "unknown"), 40);
    telemetry_counts: dict[str, any] = {};
    raw_counts = trace_data.get("telemetry_counts", {});
    if isinstance(raw_counts, dict) {
        telemetry_counts = raw_counts;
    }
    telemetry_counts[event_type] = safe_int(telemetry_counts.get(event_type, 0)) + 1;
    trace_data["telemetry_counts"] = telemetry_counts;

    if normalized.get("viewport", {}) {
        trace_data["latest_viewport"] = normalized["viewport"];
    }
    if normalized.get("semantic", {}) {
        trace_data["latest_semantic"] = normalized["semantic"];
    }
    if normalized.get("session_state", {}) {
        trace_data["latest_session_state"] = normalized["session_state"];
    }
    if normalized.get("dom_snapshot", {}) {
        trace_data["latest_dom_snapshot"] = normalized["dom_snapshot"];
    }
    if normalized.get("screenshot", {}) {
        trace_data["latest_screenshot"] = normalized["screenshot"];
    }

    write_trace(session_id, trace_data);

    return {
        "ok": True,
        "session_id": session_id,
        "event_count": len(events),
        "deduped": False
    };
}

"""R: Mark an observation session as stopped.
M: Loads trace by id, updates status fields, and saves file.
E: Safe to call more than once for the same session.
"""
def stop_trace(payload: dict[str, any]) -> dict[str, any] {
    session_id = safe_str(payload.get("session_id", ""), 120);
    if not session_id {
        return {"ok": False, "error": "session_id is required"};
    }
    if not is_valid_session_id(session_id) {
        return {"ok": False, "error": "invalid session_id format"};
    }

    trace_data = read_trace(session_id);
    if not trace_data {
        return {"ok": False, "error": "trace not found", "session_id": session_id};
    }

    now: str = timestamp_now();
    trace_data["status"] = "stopped";
    trace_data["stopped_at"] = now;
    trace_data["updated_at"] = now;
    write_trace(session_id, trace_data);

    events: list[any] = [];
    raw_events = trace_data.get("events", []);
    if isinstance(raw_events, list) {
        events = raw_events;
    }

    return {
        "ok": True,
        "session_id": session_id,
        "event_count": len(events)
    };
}

"""R: Fetch one stored observation trace by session id.
M: Loads trace JSON and returns the parsed dict.
E: Missing sessions return explicit errors.
"""
def get_trace(payload: dict[str, any]) -> dict[str, any] {
    session_id = safe_str(payload.get("session_id", ""), 120);
    if not session_id {
        return {"ok": False, "error": "session_id is required"};
    }
    if not is_valid_session_id(session_id) {
        return {"ok": False, "error": "invalid session_id format"};
    }

    trace_data = read_trace(session_id);
    if not trace_data {
        return {"ok": False, "error": "trace not found", "session_id": session_id};
    }

    return {
        "ok": True,
        "trace": trace_data
    };
}

"""R: Route a layer command to its observation operation.
M: Maps command text to start/append/stop/get handlers.
E: Unknown commands return a usage payload.
"""
def dispatch(command: str, payload: dict[str, any]) -> dict[str, any] {
    if command == "start" {
        return start_trace(payload);
    }

    if command == "append" {
        return append_trace_event(payload);
    }

    if command == "stop" {
        return stop_trace(payload);
    }

    if command == "get" {
        return get_trace(payload);
    }

    return {
        "ok": False,
        "error": "unknown command",
        "valid_commands": ["start", "append", "stop", "get"]
    };
}

"""R: Decide whether this module should execute its CLI entrypoint.
M: Treats non-empty, non-path-like argv values as commands and ignores import-time script paths.
E: Unknown direct commands still dispatch so the caller receives the usual usage payload.
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
