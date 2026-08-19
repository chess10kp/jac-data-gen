node Room { has name: str; has worth: int; has locked: bool; has opened: bool = False; }

walker Looter {
    has haul: int = 0;
    can raid with Room entry {
        if here.locked or here.opened { return; }
        here.opened = True;
        self.haul += here.worth;
        visit [-->];
    }
}

def sum_unlocked(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    shut: list = list(spec["locked"]);
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Room(name=str(src), worth=int(vals[src]), locked=(src in shut)); }
        for dst in outs { if dst not in reg { reg[dst] = Room(name=str(dst), worth=int(vals[dst]), locked=(dst in shut)); } }
    }
    for (src, outs) in adj.items() { for dst in outs { reg[src] ++> reg[dst]; } }
    w = reg[spec["start"]] spawn Looter();
    return w.haul;
}

with entry {
    print(sum_unlocked({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': [], 'd': []}, 'vals': {'a': 1, 'b': 2, 'c': 4, 'd': 8}, 'locked': ['b'], 'start': 'a'}));
}
