"""_status_mark: nested ternary rewritten as explicit if/elif/else branches."""

def _status_mark(status: str) -> str {
    if status == "ok" {
        return "ok  ";
    } elif status == "skip" {
        return "skip";
    }
    return "FAIL";
}

with entry {
    for s in ["ok", "skip", "fail", "error", "OK", ""] {
        print("[" + _status_mark(s) + "] " + s);
    }
}
