def _summary_code(results: list) -> int {
    oks = len([r for r in results if r["status"] == "ok"]);
    return 0 if oks > 0 else 1;
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
