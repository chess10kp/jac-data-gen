node Task { has name: str; has days: int; }

walker OverdueProbe {
    has limit: int;
    has found: bool = False;
    can scan with Root entry { visit [-->][?:Task]; }
    can check with Task entry {
        if here.days > self.limit { self.found = True; }
    }
}

def any_overdue(spec: dict) -> bool {
    for old in [root -->] { root del --> old; }
    for t in list(spec["tasks"]) {
        root ++> Task(name=str(t["name"]), days=int(t["days"]));
    }
    return (root spawn OverdueProbe(limit=int(spec["limit"]))).found;
}

with entry {
    print(any_overdue({'tasks': [{'name': 'pay rent', 'days': 12}, {'name': 'email', 'days': 2}], 'limit': 7}));
}
