node Post { has label: str; has done: bool = False; }

walker Scout {
    has goal: str;
    has hit: bool = False;
    can probe with Post entry {
        if here.done { return; }
        here.done = True;
        if here.label == self.goal { self.hit = True; disengage; }
        visit [-->(?done == False)];
    }
}

def can_reach(spec: dict) -> bool {
    reg: dict = {};
    for pr in list(spec["edges"]) {
        u: str = str(pr[0]); v: str = str(pr[1]);
        if u not in reg { reg[u] = Post(label=u); }
        if v not in reg { reg[v] = Post(label=v); }
        reg[u] ++> reg[v];
    }
    start: str = str(spec["start"]);
    if start not in reg { reg[start] = Post(label=start); }
    w = Scout(goal=str(spec["target"])) spawn reg[start];
    return w.hit;
}

with entry {
    print(can_reach({'edges': [['a', 'b'], ['b', 'c']], 'start': 'a', 'target': 'c'}));
}
