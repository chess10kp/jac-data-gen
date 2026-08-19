"""_summary_code: ok-count extracted into a reusable count_ok helper."""

def count_ok(results: list) -> int {
    return len([r for r in results if r["status"] == "ok"]);
}

def _summary_code(results: list) -> int {
    return 0 if count_ok(results) > 0 else 1;
}

with entry {
    cases = [
        [],
        [{"status": "fail"}, {"status": "skip"}],
        [{"status": "ok"}, {"status": "fail"}],
        [{"status": "ok"}, {"status": "ok"}, {"status": "skip"}]
    ];
    for c in cases {
        print(str(_summary_code(c)));
    }
}
