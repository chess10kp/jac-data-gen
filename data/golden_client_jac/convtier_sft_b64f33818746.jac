edge Follows {}
edge Blocks {}
node User { has name: str; has val: int; has seen: bool = False; }

walker FollowSum {
    has total: int = 0;
    can step with User entry {
        if not here.seen {
            here.seen = True;
            self.total += here.val;
            visit [->:Follows:->];
        }
    }
}

def sum_follow_values(spec: dict) -> int {
    reg: dict = {};
    for (nm, v) in spec["vals"].items() { reg[nm] = User(name=nm, val=int(v)); }
    for pr in spec["follows"] { reg[pr[0]] +>:Follows:+> reg[pr[1]]; }
    for pr in spec["blocks"] { reg[pr[0]] +>:Blocks:+> reg[pr[1]]; }
    wk = reg[spec["start"]] spawn FollowSum();
    return wk.total;
}

with entry {
    print(sum_follow_values({'follows': [['a', 'b'], ['b', 'c']], 'blocks': [['a', 'd']], 'vals': {'a': 1, 'b': 2, 'c': 3, 'd': 50}, 'start': 'a'}));
}
