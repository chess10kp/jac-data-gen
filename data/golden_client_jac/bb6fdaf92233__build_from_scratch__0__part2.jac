import json;

obj CaptureRunner {
    has results: list[dict] = [];

    def record(name: str, status: str, detail: str) -> None {
        self.results.append({"step": name, "status": status, "detail": detail});
        mark = "ok  " if status == "ok" else ("skip" if status == "skip" else "FAIL");
        print(f"  [{mark}] {name}: {detail}");
    }
}

with entry {
    runner = CaptureRunner();
    runner.record("benchmark", "ok", "Jac 120 / Zig 130");
    runner.record("shooter_jac.png", "skip", "no display");
    runner.record("shooter_zig.png", "fail", "crashed");
    print(json.dumps(runner.results, sort_keys=True));
}
