import json;

def _parse_bench_json(text: str) -> any {
    marker = "BENCH_JSON ";
    for line in text.splitlines() {
        s = line.strip();
        if s.startswith(marker) {
            return json.loads(s[len(marker):]);
        }
    }
    return None;
}
