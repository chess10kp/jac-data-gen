"""RL driver (pure-lib): capture._parse_bench_json.

Origin: this_is_jac/capture.jac. Deterministic: scans text lines for the first
one whose stripped form starts with 'BENCH_JSON ', JSON-decodes the remainder,
and returns the decoded value (or None). The marked body is the unit the policy
must regenerate; the `with entry` block exercises it on fixed inputs and prints
a deterministic projection.
"""

import json;

def _parse_bench_json(text: str) -> any {
    marker = "BENCH_JSON ";
    for line in text.splitlines() {
        s = line.strip();
        if s.startswith(marker) {
            try {
                return json.loads(s[len(marker):]);
            } except Exception as e {
                return None;
            }
        }
    }
    return None;
}

with entry {
    cases = [
        "noise\n  BENCH_JSON {\"jac\": {\"avg\": 120}, \"zig\": {\"avg\": 240}}\nmore",
        "BENCH_JSON [1, 2, 3]",
        "no marker here\nstill nothing",
        "   BENCH_JSON {bad json}",
        "BENCH_JSON 42"
    ];
    for c in cases {
        r = _parse_bench_json(c);
        print(str(r));
    }
}
