node Runner {}
node Result { has name: str, status: str; }

walker OkCount {
    has n: int = 0;
    can start with Runner entry { visit [-->][?:Result]; }
    can check with Result entry {
        if here.status == "ok" { self.n += 1; }
    }
}

def ok_count(spec: dict) -> int {
    runner = Runner();
    for r in spec["results"] {
        runner ++> Result(name=str(r["name"]), status=str(r["status"]));
    }
    return (runner spawn OkCount()).n;
}

with entry {
    print(ok_count({'results': [{'name': 'core_draw', 'status': 'ok'}, {'name': 'core_input', 'status': 'fail'}, {'name': 'core_audio', 'status': 'ok'}, {'name': 'shapes_rect', 'status': 'ok'}]}));
}
