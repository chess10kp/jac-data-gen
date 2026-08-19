"""RL driver (pure-lib): capture._parse_bench_json.

Origin: this_is_jac/capture.jac. Deterministic: scans text lines for the first
one whose stripped form starts with 'BENCH_JSON ', JSON-decodes the remainder,
and returns the decoded value (or None). The marked body is the unit the policy
must regenerate; the `with entry` block exercises it on fixed inputs and prints
a deterministic projection.
"""

import json;

def _parse_bench_json(text: str) -> any {
    # >>>HOLE id="lib_parse_bench_json" instruction="Implement _parse_bench_json(text): split text into lines; for each line, strip it; if the stripped line starts with the marker 'BENCH_JSON ' (note trailing space), try to json.loads the substring after the marker and return the decoded value, returning None if decoding raises; if no marked line is found, return None."
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
    # <<<HOLE
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
