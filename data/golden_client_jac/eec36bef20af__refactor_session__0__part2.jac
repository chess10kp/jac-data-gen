"""count_ok: list comprehension rewritten as an explicit counting loop."""

def count_ok(results: list[dict]) -> int {
    n = 0;
    for r in results {
        if r["status"] == "ok" {
            n += 1;
        }
    }
    return n;
}

with entry {
    results = [
        {"step": "benchmark", "status": "ok", "detail": "a"},
        {"step": "shooter_jac.png", "status": "skip", "detail": "b"},
        {"step": "shooter_zig.png", "status": "fail", "detail": "c"},
        {"step": "manifest", "status": "ok", "detail": "d"}
    ];
    print(str(count_ok(results)));
}
