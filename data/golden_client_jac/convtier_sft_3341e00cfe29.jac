node Runner {}
node Step { has status: str; }

walker ExitCode {
    has oks: int = 0, code: int = 1;
    can start with Runner entry { visit [-->]; }
    can tally with Step entry {
        if here.status == "ok" { self.oks += 1; }
    }
    can decide with exit {
        if self.oks > 0 { self.code = 0; }
    }
}

def pipeline_exit(spec: dict) -> int {
    runner = Runner();
    for s in spec["statuses"] { runner ++> Step(status=str(s)); }
    return (runner spawn ExitCode()).code;
}

with entry {
    print(pipeline_exit({'statuses': ['fail', 'ok', 'skip']}));
}
