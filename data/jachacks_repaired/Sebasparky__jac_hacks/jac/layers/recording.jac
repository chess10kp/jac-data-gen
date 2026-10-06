"""
Jac-native recording layer.

State machine:
  idle -> recording_one_time | recording_repeated
  recording_one_time -> recording_repeated | finished
  recording_repeated -> recording_one_time | repeated_example_complete
  repeated_example_complete -> configuring_continuation
  configuring_continuation -> finished

Data model: segmented event capture with explicit one_time and repeated segments.
Continuation strategy and stop_policy are validated and stored; compiler handoff is the next pass.
"""

import os;
import sys;
import json;
import time;
import uuid;

# ============================================================
# CONSTANTS
# ============================================================

glob DATA_ROOT: str = "./jac/layer_data";
glob RECORDING_DIR: str = DATA_ROOT + "/recordings";

glob STATE_IDLE: str = "idle";
glob STATE_RECORDING_ONE_TIME: str = "recording_one_time";
glob STATE_RECORDING_REPEATED: str = "recording_repeated";
glob STATE_REPEATED_EXAMPLE_COMPLETE: str = "repeated_example_complete";
glob STATE_CONFIGURING_CONTINUATION: str = "configuring_continuation";
glob STATE_FINISHED: str = "finished";

# Allowed continuation strategy modes
glob VALID_CONTINUATION_MODES: list[str] = [
    "next_similar_item", "scroll_for_more", "next_page", "manual_pick_next", "stop"
];

# Allowed scroll_style values for scroll_for_more mode
glob VALID_SCROLL_STYLES: list[str] = ["partial", "viewport", "until_new_items"];

# Allowed stop policy modes
glob VALID_STOP_MODES: list[str] = [
    "no_more_items", "after_n_successes", "after_n_reviews", "ask_before_continue"
];

# Stop modes that require a count in options
glob COUNT_REQUIRED_STOP_MODES: list[str] = ["after_n_successes", "after_n_reviews"];

# Allowed transitions: from_state -> list of valid to_states
glob ALLOWED_TRANSITIONS: dict[str, any] = {
    "idle": ["recording_one_time", "recording_repeated"],
    "recording_one_time": ["recording_repeated", "finished"],
    "recording_repeated": ["recording_one_time", "repeated_example_complete"],
    "repeated_example_complete": ["configuring_continuation"],
    "configuring_continuation": ["finished"]
};

# ============================================================
# UTILITIES
# ============================================================

"""Generate a prefixed random ID from a UUID v4."""
def new_id(prefix: str) -> str {
    uid: str = str(uuid.uuid4()).replace("-", "");
    return prefix + uid[:16];
}

def new_recording_id() -> str { return new_id("rec_"); }

"""Return current UTC time as ISO-8601 string (seconds precision)."""
def timestamp_now() -> str {
    t: any = time.gmtime();
    result: str = time.strftime("%Y-%m-%dT%H:%M:%SZ", t);
    return result;
}

"""R: Ensure recording storage path exists.
M: Creates `jac/layer_data/recordings` recursively.
E: Safe to call repeatedly.
"""
def ensure_recording_dir() {
    os.makedirs(RECORDING_DIR, exist_ok=True);
}

"""R: Build recording file path for one session.
M: Joins recording dir with `<recording_id>.json`.
E: Caller validates recording id shape.
"""
def recording_file(recording_id: str) -> str {
    return RECORDING_DIR + "/" + recording_id + ".json";
}

"""R: Read one persisted recording session from disk.
M: Loads JSON and returns dict payload when valid.
E: Missing/invalid files map to empty dict.
"""
def read_recording(recording_id: str) -> dict[str, any] {
    path = recording_file(recording_id);
    if not os.path.exists(path) {
        return {};
    }

    try {
        with open(path, "r") as f {
            parsed = json.load(f);
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

"""R: Load the recording referenced by a command payload.
M: Extracts `recording_id`, reads the stored session, and returns both on success.
E: Missing ids and unknown sessions map to stable `ok: false` errors.
"""
def load_recording_from_payload(payload: dict[str, any]) -> dict[str, any] {
    recording_id: str = str(payload.get("recording_id", ""));
    if not recording_id {
        return {"ok": False, "error": "recording_id is required"};
    }

    rec: dict[str, any] = read_recording(recording_id);
    if not rec {
        return {"ok": False, "error": "recording not found", "recording_id": recording_id};
    }

    return {"ok": True, "recording_id": recording_id, "recording": rec};
}

"""R: Persist one recording session JSON record.
M: Writes formatted JSON to the session file path.
E: Propagates filesystem errors to caller.
"""
def write_recording(recording_id: str, rec: dict[str, any]) {
    ensure_recording_dir();
    with open(recording_file(recording_id), "w") as f {
        json.dump(rec, f, indent=2);
    }
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

# ============================================================
# CONTINUATION VALIDATION
# ============================================================

"""R: Validate options dict for a scroll_for_more strategy entry.
M: Checks scroll_style (if present) is in VALID_SCROLL_STYLES; max_scrolls (if present) is a positive int.
E: Empty options dict is valid. Booleans are rejected for numeric fields.
"""
def validate_scroll_for_more_options(options: dict[str, any]) -> dict[str, any] {
    scroll_style = options.get("scroll_style", None);
    if scroll_style is not None {
        if not isinstance(scroll_style, str) {
            return {"ok": False, "error": "scroll_style must be a string"};
        }
        if not (scroll_style in VALID_SCROLL_STYLES) {
            return {"ok": False, "error": "invalid scroll_style: " + str(scroll_style)};
        }
    }

    max_scrolls = options.get("max_scrolls", None);
    if max_scrolls is not None {
        if isinstance(max_scrolls, bool) or not isinstance(max_scrolls, int) {
            return {"ok": False, "error": "max_scrolls must be an integer"};
        }
        if max_scrolls <= 0 {
            return {"ok": False, "error": "max_scrolls must be a positive integer"};
        }
    }

    return {"ok": True};
}

"""R: Validate options dict for a next_page strategy entry.
M: Checks button_hint (if present) is a string; max_pages (if present) is a positive int.
E: Empty options dict is valid. Booleans are rejected for numeric fields.
"""
def validate_next_page_options(options: dict[str, any]) -> dict[str, any] {
    button_hint = options.get("button_hint", None);
    if button_hint is not None and not isinstance(button_hint, str) {
        return {"ok": False, "error": "button_hint must be a string"};
    }

    max_pages = options.get("max_pages", None);
    if max_pages is not None {
        if isinstance(max_pages, bool) or not isinstance(max_pages, int) {
            return {"ok": False, "error": "max_pages must be an integer"};
        }
        if max_pages <= 0 {
            return {"ok": False, "error": "max_pages must be a positive integer"};
        }
    }

    return {"ok": True};
}

"""R: Validate a single continuation strategy item.
M: Checks required keys (mode, options), validates mode is known, delegates mode-specific options validation.
E: Returns the first validation failure encountered; item must be a dict with non-empty string mode.
"""
def validate_strategy_item(item: any) -> dict[str, any] {
    if not isinstance(item, dict) {
        return {"ok": False, "error": "strategy entry must be a dict"};
    }

    mode = item.get("mode", None);
    if mode is None {
        return {"ok": False, "error": "strategy entry missing mode"};
    }
    if not isinstance(mode, str) or mode == "" {
        return {"ok": False, "error": "strategy entry mode must be a non-empty string"};
    }
    if not (mode in VALID_CONTINUATION_MODES) {
        return {"ok": False, "error": "unknown continuation mode: " + str(mode)};
    }

    if not ("options" in item) {
        return {"ok": False, "error": "strategy entry missing options"};
    }
    options = item.get("options", {});
    if not isinstance(options, dict) {
        return {"ok": False, "error": "strategy entry options must be a dict"};
    }

    if mode == "scroll_for_more" {
        return validate_scroll_for_more_options(options);
    }
    if mode == "next_page" {
        return validate_next_page_options(options);
    }

    # next_similar_item, manual_pick_next, stop: options may be empty in v1
    return {"ok": True};
}

"""R: Validate a full continuation strategy list.
M: Checks the value is a list, then validates each entry; returns first failure with its index.
E: Empty list is valid. Index is included in error messages for debuggability.
"""
def validate_continuation_strategy(strategy: any) -> dict[str, any] {
    if not isinstance(strategy, list) {
        return {"ok": False, "error": "continuation strategy must be a list"};
    }

    for (i, item) in enumerate(strategy) {
        result = validate_strategy_item(item);
        if not result.get("ok", False) {
            return {
                "ok": False,
                "error": "strategy[" + str(i) + "]: " + str(result.get("error", "invalid"))
            };
        }
    }

    return {"ok": True};
}

# ============================================================
# STOP POLICY VALIDATION
# ============================================================

"""R: Validate a stop policy dict.
M: Checks required keys (mode, options), validates mode is known, enforces count for count-based modes.
E: count must be a positive integer (not a boolean) for after_n_successes and after_n_reviews.
"""
def validate_stop_policy(stop_policy: any) -> dict[str, any] {
    if not isinstance(stop_policy, dict) {
        return {"ok": False, "error": "stop_policy must be a dict"};
    }

    mode = stop_policy.get("mode", None);
    if mode is None {
        return {"ok": False, "error": "stop_policy missing mode"};
    }
    if not isinstance(mode, str) or mode == "" {
        return {"ok": False, "error": "stop_policy mode must be a non-empty string"};
    }
    if not (mode in VALID_STOP_MODES) {
        return {"ok": False, "error": "unknown stop_policy mode: " + str(mode)};
    }

    if not ("options" in stop_policy) {
        return {"ok": False, "error": "stop_policy missing options"};
    }
    options = stop_policy.get("options", {});
    if not isinstance(options, dict) {
        return {"ok": False, "error": "stop_policy options must be a dict"};
    }

    if mode in COUNT_REQUIRED_STOP_MODES {
        count = options.get("count", None);
        if count is None {
            return {"ok": False, "error": "stop_policy " + mode + " requires options.count"};
        }
        if isinstance(count, bool) or not isinstance(count, int) {
            return {"ok": False, "error": "stop_policy options.count must be an integer"};
        }
        if count <= 0 {
            return {"ok": False, "error": "stop_policy options.count must be positive"};
        }
    }

    return {"ok": True};
}

# ============================================================
# STATE MACHINE
# ============================================================

"""R: Check whether a state transition is allowed.
M: Looks up the from_state in ALLOWED_TRANSITIONS and checks to_state is in the valid list.
E: any unknown from_state has no valid transitions (returns False).
"""
def transition_allowed(from_state: str, to_state: str) -> bool {
    allowed: list[any] = ALLOWED_TRANSITIONS.get(from_state, []);
    return to_state in allowed;
}

"""R: Apply a state transition to a recording session dict in place.
M: Validates the transition is allowed, then mutates state and updated_at on the dict.
E: Returns error dict if the transition is not allowed; on success returns ok dict.
"""
def apply_transition(rec: dict[str, any], to_state: str) -> dict[str, any] {
    from_state: str = str(rec.get("state", ""));
    if not transition_allowed(from_state, to_state) {
        return {
            "ok": False,
            "error": "transition not allowed",
            "from": from_state,
            "to": to_state
        };
    }
    rec["state"] = to_state;
    rec["updated_at"] = timestamp_now();
    return {"ok": True};
}

# ============================================================
# SEGMENTED RECORDING DATA MODEL
# ============================================================

"""R: Build the initial segmented recording session structure in idle state.
M: Creates one_time and repeated segments (each with empty events/annotations),
   plus stub continuation and stop_policy for use in the next pass.
E: No mode is auto-selected; state starts at idle.
"""
def new_recording_session(task_name: str, meta: dict[str, any]) -> dict[str, any] {
    domains: list[any] = [];
    raw_domains = meta.get("domains", []);
    if isinstance(raw_domains, list) {
        domains = raw_domains;
    }
    now: str = timestamp_now();

    return {
        "recording_id": new_recording_id(),
        "task_name": task_name,
        "created_at": now,
        "updated_at": now,
        "state": STATE_IDLE,
        "segments": {
            "one_time": {
                "events": [],
                "annotations": []
            },
            "repeated": {
                "events": [],
                "annotations": []
            }
        },
        "continuation": {
            "strategy": []
        },
        "stop_policy": {
            "mode": "",
            "options": {}
        },
        "meta": {
            "start_url": str(meta.get("start_url", "")),
            "domains": domains,
            "user_goal": str(meta.get("user_goal", ""))
        }
    };
}

"""R: Determine which segment name the current state writes to.
M: Maps recording_one_time -> one_time, recording_repeated -> repeated.
E: Returns empty string when not in an active recording state.
"""
def active_segment(state: str) -> str {
    if state == STATE_RECORDING_ONE_TIME {
        return "one_time";
    }
    if state == STATE_RECORDING_REPEATED {
        return "repeated";
    }
    return "";
}

"""R: Append one stamped payload item to the active recording segment.
M: Resolves the active segment, adds timestamp and segment metadata, then appends into the target list.
E: Returns `ok: false` when the recording is not actively capturing a segment.
"""
def append_to_active_segment(
    rec: dict[str, any],
    item: dict[str, any],
    collection_key: str,
    stamp_key: str
) -> dict[str, any] {
    state: str = str(rec.get("state", ""));
    seg_name: str = active_segment(state);
    if not seg_name {
        return {
            "ok": False,
            "error": "no active recording segment in state: " + state
        };
    }

    segments: dict[str, any] = rec.get("segments", {});
    seg: dict[str, any] = segments.get(seg_name, {});

    items: list[any] = [];
    raw_items = seg.get(collection_key, []);
    if isinstance(raw_items, list) {
        items = raw_items;
    }

    now: str = timestamp_now();
    stamped: dict[str, any] = dict(item);
    stamped[stamp_key] = now;
    stamped["segment"] = seg_name;
    items.append(stamped);

    seg[collection_key] = items;
    segments[seg_name] = seg;
    rec["segments"] = segments;
    rec["updated_at"] = now;

    return {"ok": True, "segment": seg_name, "count": len(items)};
}

"""R: Append one event to the correct segment based on current session state.
M: Resolves segment via active_segment, stamps with recorded_at and segment name, appends.
E: Returns error if session is not in an active recording state.
"""
def append_event_to_segment(rec: dict[str, any], event: dict[str, any]) -> dict[str, any] {
    result: dict[str, any] = append_to_active_segment(rec, event, "events", "recorded_at");
    if not result.get("ok", False) {
        return result;
    }

    return {"ok": True, "segment": result["segment"], "event_count": result["count"]};
}

"""R: Append one annotation to the correct segment based on current session state.
M: Resolves segment via active_segment, stamps with annotated_at and segment name, appends.
E: Returns error if session is not in an active recording state.
"""
def append_annotation_to_segment(rec: dict[str, any], annotation: dict[str, any]) -> dict[str, any] {
    result: dict[str, any] = append_to_active_segment(rec, annotation, "annotations", "annotated_at");
    if not result.get("ok", False) {
        return result;
    }

    return {"ok": True, "segment": result["segment"], "annotation_count": result["count"]};
}

"""R: Apply one state transition command to a stored recording.
M: Loads the target recording, performs the transition, and persists the updated state.
E: Missing recordings and invalid transitions return the original error payloads unchanged.
"""
def transition_recording_command(payload: dict[str, any], to_state: str) -> dict[str, any] {
    loaded: dict[str, any] = load_recording_from_payload(payload);
    if not loaded.get("ok", False) {
        return loaded;
    }

    recording_id: str = str(loaded.get("recording_id", ""));
    rec: dict[str, any] = loaded.get("recording", {});

    result: dict[str, any] = apply_transition(rec, to_state);
    if not result.get("ok", False) {
        return result;
    }

    write_recording(recording_id, rec);
    return {"ok": True, "recording_id": recording_id, "state": rec["state"]};
}

# ============================================================
# COMMAND HANDLERS
# ============================================================

"""R: Create a new recording session in idle state.
M: Builds default segmented session, persists to disk, returns recording_id.
E: Optional task_name and meta fields; defaults are empty/minimal.
"""
def cmd_create(payload: dict[str, any]) -> dict[str, any] {
    task_name: str = str(payload.get("task_name", ""));
    meta: dict[str, any] = {};
    raw_meta = payload.get("meta", {});
    if isinstance(raw_meta, dict) {
        meta = raw_meta;
    }

    rec = new_recording_session(task_name, meta);
    rec_id: str = str(rec["recording_id"]);
    write_recording(rec_id, rec);

    return {
        "ok": True,
        "recording_id": rec_id,
        "state": rec["state"],
        "recording_file": recording_file(rec_id)
    };
}

"""R: Transition to recording_one_time from idle or recording_repeated.
M: Loads session, applies transition, persists.
E: Fails if current state does not allow this transition.
"""
def cmd_enter_one_time(payload: dict[str, any]) -> dict[str, any] {
    return transition_recording_command(payload, STATE_RECORDING_ONE_TIME);
}

"""R: Transition to recording_repeated from idle or recording_one_time.
M: Loads session, applies transition, persists.
E: Fails if current state does not allow this transition.
"""
def cmd_enter_repeated(payload: dict[str, any]) -> dict[str, any] {
    return transition_recording_command(payload, STATE_RECORDING_REPEATED);
}

"""R: Append one event to the active recording segment.
M: Resolves segment from current state, appends event with timestamp, persists.
E: Fails if session is not in an active recording state.
"""
def cmd_append_event(payload: dict[str, any]) -> dict[str, any] {
    loaded: dict[str, any] = load_recording_from_payload(payload);
    if not loaded.get("ok", False) {
        return loaded;
    }
    recording_id: str = str(loaded.get("recording_id", ""));
    rec: dict[str, any] = loaded.get("recording", {});

    event: dict[str, any] = {};
    raw_event = payload.get("event", {});
    if isinstance(raw_event, dict) {
        event = raw_event;
    }

    result = append_event_to_segment(rec, event);
    if not result.get("ok", False) {
        return result;
    }

    write_recording(recording_id, rec);
    return {
        "ok": True,
        "recording_id": recording_id,
        "segment": result["segment"],
        "event_count": result["event_count"]
    };
}

"""R: Append one annotation to the active recording segment.
M: Resolves segment from current state, appends annotation with timestamp, persists.
E: Fails if session is not in an active recording state.
"""
def cmd_append_annotation(payload: dict[str, any]) -> dict[str, any] {
    loaded: dict[str, any] = load_recording_from_payload(payload);
    if not loaded.get("ok", False) {
        return loaded;
    }
    recording_id: str = str(loaded.get("recording_id", ""));
    rec: dict[str, any] = loaded.get("recording", {});

    annotation: dict[str, any] = {};
    raw_ann = payload.get("annotation", {});
    if isinstance(raw_ann, dict) {
        annotation = raw_ann;
    }

    result = append_annotation_to_segment(rec, annotation);
    if not result.get("ok", False) {
        return result;
    }

    write_recording(recording_id, rec);
    return {
        "ok": True,
        "recording_id": recording_id,
        "segment": result["segment"],
        "annotation_count": result["annotation_count"]
    };
}

"""R: Mark the repeated example as complete and advance state.
M: Transitions recording_repeated -> repeated_example_complete.
E: Fails if not currently in recording_repeated state.
"""
def cmd_finish_repeated_example(payload: dict[str, any]) -> dict[str, any] {
    return transition_recording_command(payload, STATE_REPEATED_EXAMPLE_COMPLETE);
}

"""R: Move to configuring_continuation and store a validated strategy list.
M: Validates the strategy before touching state; transitions repeated_example_complete ->
   configuring_continuation, or stays in configuring_continuation (allows re-configure).
E: Validation errors return ok:false without mutating stored state.
   Re-calling while already in configuring_continuation replaces the strategy in place.
"""
def cmd_configure_continuation(payload: dict[str, any]) -> dict[str, any] {
    loaded: dict[str, any] = load_recording_from_payload(payload);
    if not loaded.get("ok", False) {
        return loaded;
    }
    recording_id: str = str(loaded.get("recording_id", ""));
    rec: dict[str, any] = loaded.get("recording", {});

    # Validate before mutating anything
    raw_strategy = payload.get("strategy", []);
    validation = validate_continuation_strategy(raw_strategy);
    if not validation.get("ok", False) {
        return {"ok": False, "error": validation.get("error", "invalid strategy")};
    }

    state: str = str(rec.get("state", ""));
    if state == STATE_REPEATED_EXAMPLE_COMPLETE {
        result = apply_transition(rec, STATE_CONFIGURING_CONTINUATION);
        if not result.get("ok", False) {
            return result;
        }
    } elif state != STATE_CONFIGURING_CONTINUATION {
        return {
            "ok": False,
            "error": "configure_continuation not allowed in state: " + state
        };
    }

    strategy: list[any] = [];
    if isinstance(raw_strategy, list) {
        strategy = raw_strategy;
    }

    rec["continuation"] = {"strategy": strategy};
    write_recording(recording_id, rec);
    return {"ok": True, "recording_id": recording_id, "state": rec["state"]};
}

"""R: Store a validated stop policy on the recording.
M: Validates the stop_policy structure and mode-specific options, then writes to recording.
E: Only allowed in configuring_continuation state. No state transition occurs.
   Validation errors return ok:false without mutating stored data.
"""
def cmd_configure_stop_policy(payload: dict[str, any]) -> dict[str, any] {
    loaded: dict[str, any] = load_recording_from_payload(payload);
    if not loaded.get("ok", False) {
        return loaded;
    }
    recording_id: str = str(loaded.get("recording_id", ""));
    rec: dict[str, any] = loaded.get("recording", {});

    state: str = str(rec.get("state", ""));
    if state != STATE_CONFIGURING_CONTINUATION {
        return {
            "ok": False,
            "error": "configure_stop_policy not allowed in state: " + state
        };
    }

    raw_sp = payload.get("stop_policy", {});
    validation = validate_stop_policy(raw_sp);
    if not validation.get("ok", False) {
        return {"ok": False, "error": validation.get("error", "invalid stop_policy")};
    }

    sp: dict[str, any] = {};
    if isinstance(raw_sp, dict) {
        sp = raw_sp;
    }

    rec["stop_policy"] = sp;
    write_recording(recording_id, rec);
    return {"ok": True, "recording_id": recording_id, "state": rec["state"]};
}

"""R: Mark a recording session as finished.
M: Transitions current state -> finished, persists.
E: Fails if current state does not allow transition to finished.
"""
def cmd_finish(payload: dict[str, any]) -> dict[str, any] {
    return transition_recording_command(payload, STATE_FINISHED);
}

"""R: Fetch a stored recording session by recording_id.
M: Loads recording JSON and returns the parsed dict.
E: Missing sessions return explicit errors.
"""
def cmd_get(payload: dict[str, any]) -> dict[str, any] {
    loaded: dict[str, any] = load_recording_from_payload(payload);
    if not loaded.get("ok", False) {
        return loaded;
    }

    return {"ok": True, "recording": loaded["recording"]};
}

# ============================================================
# DISPATCH
# ============================================================

"""R: Route a layer command to its recording operation.
M: Maps command text to recording state machine handlers.
E: Unknown commands return a usage payload with valid command list.
"""
def dispatch(command: str, payload: dict[str, any]) -> dict[str, any] {
    if command == "create" {
        return cmd_create(payload);
    }
    if command == "enter_one_time" {
        return cmd_enter_one_time(payload);
    }
    if command == "enter_repeated" {
        return cmd_enter_repeated(payload);
    }
    if command == "append_event" {
        return cmd_append_event(payload);
    }
    if command == "append_annotation" {
        return cmd_append_annotation(payload);
    }
    if command == "finish_repeated_example" {
        return cmd_finish_repeated_example(payload);
    }
    if command == "configure_continuation" {
        return cmd_configure_continuation(payload);
    }
    if command == "configure_stop_policy" {
        return cmd_configure_stop_policy(payload);
    }
    if command == "finish" {
        return cmd_finish(payload);
    }
    if command == "get" {
        return cmd_get(payload);
    }

    return {
        "ok": False,
        "error": "unknown command",
        "valid_commands": [
            "create", "enter_one_time", "enter_repeated",
            "append_event", "append_annotation",
            "finish_repeated_example", "configure_continuation",
            "configure_stop_policy", "finish", "get"
        ]
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
