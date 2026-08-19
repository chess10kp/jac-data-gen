edge Follows {}
edge Blocks {}
node Member { has name: str; has reached: bool = False; }

walker FollowSweep {
    can step with Member entry {
        if not here.reached {
            here.reached = True;
            visit [->:Follows:->];
        }
    }
}

def unblocked_follower_count(spec: dict) -> int {
    reg: dict = {};
    reg[spec["start"]] = Member(name=spec["start"]);
    for pr in spec["follows"] { for nm in pr { if nm not in reg { reg[nm] = Member(name=nm); } } }
    for pr in spec["blocks"] { for nm in pr { if nm not in reg { reg[nm] = Member(name=nm); } } }
    for pr in spec["follows"] { reg[pr[0]] +>:Follows:+> reg[pr[1]]; }
    for pr in spec["blocks"] { reg[pr[0]] +>:Blocks:+> reg[pr[1]]; }
    base = reg[spec["start"]];
    wk = base spawn FollowSweep();
    blocked: list = [];
    for nb in [base ->:Blocks:->] { blocked.append(nb.name); }
    count: int = 0;
    for nd in reg.values() {
        if nd.reached and nd.name != spec["start"] and nd.name not in blocked { count += 1; }
    }
    return count;
}

with entry {
    print(unblocked_follower_count({'follows': [['a', 'b'], ['b', 'c'], ['a', 'd']], 'blocks': [['a', 'c']], 'start': 'a'}));
}
