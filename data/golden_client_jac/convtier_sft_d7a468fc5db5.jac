node Log {}
node LogLine { has text: str; }

walker FindBench {
    has payload: str = "none";
    can start with Log entry { visit [-->]; }
    can scan with LogLine entry {
        s = here.text.strip();
        if s.startswith("BENCH_JSON ") {
            self.payload = s[11:];
            disengage;
        }
        visit [-->];
    }
}

def bench_payload(spec: dict) -> str {
    log = Log();
    prev = log;
    for line in spec["lines"] { nxt = LogLine(text=str(line)); prev ++> nxt; prev = nxt; }
    return (log spawn FindBench()).payload;
}

with entry {
    print(bench_payload({'lines': ['starting run', '  BENCH_JSON {"jac": 120}', 'done']}));
}
