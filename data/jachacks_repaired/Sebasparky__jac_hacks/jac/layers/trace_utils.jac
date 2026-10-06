import os;
import json;

glob DATA_ROOT: str = "./jac/layer_data";
glob TRACE_DIR: str = DATA_ROOT + "/traces";

"""R: Build the persisted observation trace file path for one session id.
M: Joins the shared trace directory with the session id and `.json` suffix.
E: Caller is responsible for passing a valid session id string.
"""
def trace_file(session_id: str) -> str {
    return TRACE_DIR + "/" + session_id + ".json";
}

"""R: Read one persisted observation trace from disk without triggering any CLI entrypoints.
M: Loads the trace JSON file and returns it only when the parsed payload is a dict.
E: Missing files, invalid JSON, and filesystem read errors all return an empty dict.
"""
def read_trace(session_id: str) -> dict[str, any] {
    path = trace_file(session_id);
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
