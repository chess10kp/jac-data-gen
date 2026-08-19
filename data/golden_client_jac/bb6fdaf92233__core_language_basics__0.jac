"""RL driver (pure-lib): capture.CaptureRunner.record (append result + print marked line).

Origin: this_is_jac/capture.jac (the CaptureRunner.record logic, isolated from any
io/time/subprocess machinery). Deterministic: record is called on three FIXED triples
covering all three status branches; the printed lines and the json projection of the
appended dicts are byte-identical every run. The marked body is the unit the policy must
regenerate; the with entry block exercises it on fixed inputs and prints a deterministic
projection.
"""

import json;

obj CaptureRunner {
    has results: list[dict] = [];

    def record(name: str, status: str, detail: str) -> None {
        # >>>HOLE id="lib_capture_record_line" instruction="Append a dict to self.results with keys 'step' (the name arg), 'status' (the status arg), and 'detail' (the detail arg). Then compute a 4-character mark string: 'ok  ' when status equals 'ok', else 'skip' when status equals 'skip', else 'FAIL'. Finally print a line formatted as two spaces, then the mark in square brackets, a space, the name, a colon, a space, and the detail."
        self.results.append({"step": name, "status": status, "detail": detail});
        mark = "ok  " if status == "ok" else ("skip" if status == "skip" else "FAIL");
        print(f"  [{mark}] {name}: {detail}");
        # <<<HOLE
    }
}

with entry {
    runner = CaptureRunner();
    runner.record("benchmark", "ok", "Jac 120 / Zig 130");
    runner.record("shooter_jac.png", "skip", "no display");
    runner.record("shooter_zig.png", "fail", "crashed");
    print(json.dumps(runner.results, sort_keys=True));
}
