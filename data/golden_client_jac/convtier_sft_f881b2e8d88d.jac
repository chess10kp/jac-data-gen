edge Parent {}
edge Mentor {}
node Person { has name: str; has d: int = -1; has seen: bool = False; }

walker MentorDepth {
    has best: int = 0;
    can step with Person entry {
        if not here.seen {
            here.seen = True;
            if here.d > self.best { self.best = here.d; }
            for nxt in [->:Mentor:->] { if nxt.d == -1 { nxt.d = here.d + 1; } }
            visit [->:Mentor:->];
        }
    }
}

def mentor_chain_depth(spec: dict) -> int {
    reg: dict = {};
    reg[spec["start"]] = Person(name=spec["start"]);
    for pr in spec["parents"] { for nm in pr { if nm not in reg { reg[nm] = Person(name=nm); } } }
    for pr in spec["mentors"] { for nm in pr { if nm not in reg { reg[nm] = Person(name=nm); } } }
    for pr in spec["parents"] { reg[pr[0]] +>:Parent:+> reg[pr[1]]; }
    for pr in spec["mentors"] { reg[pr[0]] +>:Mentor:+> reg[pr[1]]; }
    reg[spec["start"]].d = 0;
    wk = reg[spec["start"]] spawn MentorDepth();
    return wk.best;
}

with entry {
    print(mentor_chain_depth({'parents': [['a', 'b']], 'mentors': [['a', 'c'], ['c', 'd']], 'start': 'a'}));
}
