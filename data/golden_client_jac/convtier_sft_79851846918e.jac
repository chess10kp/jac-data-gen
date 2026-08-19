node Pipeline {}
node BuildStep { has name: str; has status: str; has detail: str; }

walker MarkLines {
    has lines: list = [];
    can start with Pipeline entry { visit [-->]; }
    can mark with BuildStep entry {
        if here.status == "ok" { m = "ok  "; }
        elif here.status == "skip" { m = "skip"; }
        else { m = "FAIL"; }
        self.lines.append("  [" + m + "] " + here.name + ": " + here.detail);
        visit [-->];
    }
}

def step_marks(spec: dict) -> list {
    pipe = Pipeline();
    prev = pipe;
    for s in spec["steps"] {
        nxt = BuildStep(name=str(s["name"]), status=str(s["status"]), detail=str(s["detail"]));
        prev ++> nxt;
        prev = nxt;
    }
    return (pipe spawn MarkLines()).lines;
}

with entry {
    print(step_marks({'steps': [{'name': 'benchmark', 'status': 'ok', 'detail': '120ms'}, {'name': 'shot.png', 'status': 'skip', 'detail': 'no display'}, {'name': 'deploy', 'status': 'fail', 'detail': 'crashed'}]}));
}
