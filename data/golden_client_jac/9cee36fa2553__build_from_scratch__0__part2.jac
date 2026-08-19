def _status_mark(status: str) -> str {
    return "ok  " if status == "ok" else ("skip" if status == "skip" else "FAIL");
}

with entry {
    for s in ["ok", "skip", "fail", "error", "OK", ""] {
        print("[" + _status_mark(s) + "] " + s);
    }
}
