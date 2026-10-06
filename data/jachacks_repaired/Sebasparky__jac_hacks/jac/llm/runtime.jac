"""
Jac-native Kimi runtime lifecycle CLI.

Purpose:
- Provide `start`, `stop`, and `status` commands for the browser process.
- Delegate all reusable logic to `runtime_state.jac` so imports stay side-effect free.
"""

import sys;
import json;
import from jac.llm.runtime_state {
    current_runtime_state,
    start_runtime,
    stop_runtime
}

"""R: Parse CLI JSON payload passed after the command token.
M: Joins argv entries from index 2 and attempts one JSON object decode.
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
    } except json.JSONDecodeError {
        return {};
    }
    return {};
}

"""R: Route one runtime lifecycle command to its implementation.
M: Supports `start`, `stop`, and `status`.
E: Unknown commands return a usage payload instead of raising.
"""
def dispatch(command: str, payload: dict[str, any]) -> dict[str, any] {
    if command == "start" {
        return start_runtime(payload);
    }
    if command == "stop" {
        return stop_runtime(payload);
    }
    if command == "status" {
        return {"ok": True, "runtime": current_runtime_state()};
    }

    return {
        "ok": False,
        "error": "unknown command",
        "valid_commands": ["start", "stop", "status"]
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
        payload: dict[str, any] = parse_payload();
        result: dict[str, any] = dispatch(command, payload);
        print(json.dumps(result));
    }
}
