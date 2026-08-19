"""RL driver (pure-lib): capture.CaptureRunner.summary (exit-code logic).

Origin: this_is_jac/capture.jac (the ok-count + exit-code computation inside
`summary`). Deterministic: counts results whose 'status' is 'ok' and returns 0
when at least one is ok, else 1. The marked body is the unit the policy must
regenerate; the `with entry` block exercises it on fixed inputs and prints a
deterministic projection.
"""

def _summary_code(results: list) -> int {
    # >>>HOLE id="lib_capture_summary_code" instruction="Implement _summary_code(results): given a list of result dicts each with a 'status' key, count how many have status equal to 'ok'; return 0 if that count is greater than zero, otherwise return 1."
    oks = len([r for r in results if r["status"] == "ok"]);
    return 0 if oks > 0 else 1;
    # <<<HOLE
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
