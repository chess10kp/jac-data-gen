def _status_mark(status: str) -> str {
    if status == "ok" { return "ok"; }
    elif status == "skip" { return "skip"; }
    return "FAIL";
}
