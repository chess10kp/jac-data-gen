node Runner {}
node Result { has name: str, status: str; }

walker FirstFail {
    has found: str = "PASS";
    can start with Runner entry { visit [-->][?:Result]; }
    can check with Result entry {
        if self.found == "PASS" {
            if here.status != "ok" { self.found = here.name; }
            else { visit [-->][?:Result]; }
        }
    }
}

def first_fail(spec: dict) -> str {
    runner = Runner();
    prev = runner;
    for r in spec["results"] {
        res = Result(name=str(r["name"]), status=str(r["status"]));
        prev ++> res;
        prev = res;
    }
    return (runner spawn FirstFail()).found;
}

with entry {
    print(first_fail({'results': [{'name': 'core_draw', 'status': 'ok'}, {'name': 'core_input', 'status': 'fail'}, {'name': 'core_audio', 'status': 'fail'}]}));
}
