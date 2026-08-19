node Runner {}
node Result { has name: str, status: str; }

walker FailTail {
    has k: int;
    has fails: list = [], tail: list = [];
    can start with Runner entry { visit [-->][?:Result]; }
    can check with Result entry {
        if here.status != "ok" { self.fails.append(here.name); }
        visit [-->][?:Result];
    }
    can trim with exit {
        if self.k > 0 {
            start = len(self.fails) - self.k;
            if start < 0 { start = 0; }
            self.tail = self.fails[start:];
        }
    }
}

def failure_tail(spec: dict) -> list {
    runner = Runner();
    prev = runner;
    for r in spec["results"] {
        res = Result(name=str(r["name"]), status=str(r["status"]));
        prev ++> res;
        prev = res;
    }
    return (runner spawn FailTail(k=int(spec["k"]))).tail;
}

with entry {
    print(failure_tail({'results': [{'name': 'boot', 'status': 'fail'}, {'name': 'draw', 'status': 'ok'}, {'name': 'input', 'status': 'timeout'}, {'name': 'audio', 'status': 'fail'}, {'name': 'quit', 'status': 'fail'}], 'k': 2}));
}
