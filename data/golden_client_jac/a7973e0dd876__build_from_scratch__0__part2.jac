"""Scan text for the first 'BENCH_JSON ' line and return the decoded JSON after it, or None (on no match or a decode error)."""

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
