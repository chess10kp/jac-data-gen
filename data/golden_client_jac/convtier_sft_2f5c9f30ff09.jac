node Stop { has name: str; }

walker Tracer {
    has path: list = [];
    can log with Stop entry { self.path.append(here.name); visit [-->]; }
}

def trace_route(spec: dict) -> str {
    nxt: dict = dict(spec["next"]);
    cur: str = str(spec["start"]);
    first = Stop(name=cur);
    tip = first;
    while nxt.get(cur, "") != "" {
        cur = str(nxt[cur]);
        hop = Stop(name=cur);
        tip ++> hop;
        tip = hop;
    }
    return "/".join((first spawn Tracer()).path);
}

with entry {
    print(trace_route({'next': {'dock': 'gate', 'gate': 'hall', 'hall': ''}, 'start': 'dock'}));
}
