import json;

def parse_bench_json(text: str) -> dict | None {
    for line in text.splitlines() {
        s = line.strip();
        if s.startswith("BENCH_JSON ") {
            try {
                return json.loads(s[len("BENCH_JSON "):]);
            } except Exception as e {
                return None;
            }
        }
    }
    return None;
}

with entry {
    print(parse_bench_json('warmup\nBENCH_JSON {"fps": 60, "frames": 900}\ndone'));
}
