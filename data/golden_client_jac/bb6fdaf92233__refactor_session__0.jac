def _status_mark(status: str) -> str {
    return "ok  " if status == "ok" else ("skip" if status == "skip" else "FAIL");
}

obj CaptureRunner {
    has results: list[dict] = [];
    def record(name: str, status: str, detail: str) -> None;
}

impl record {
    self.results.append({"step": name, "status": status, "detail": detail});
    print(f"  [{_status_mark(status)}] {name}: {detail}");
}
