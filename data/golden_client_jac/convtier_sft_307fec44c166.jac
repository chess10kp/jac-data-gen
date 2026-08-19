node Fork { has tag: str; has met: bool = False; }

walker LeafSeek {
    has answer: str = "none";
    can inspect with Fork entry {
        if here.met { return; }
        here.met = True;
        if len([-->]) == 0 { self.answer = here.tag; disengage; }
        visit [-->];
    }
}

def first_leaf_name(spec: dict) -> str {
    base: str = str(spec["root"]);
    forks: dict = {base: Fork(tag=base)};
    for (c, p) in dict(spec["parent"]).items() {
        if p not in forks { forks[p] = Fork(tag=str(p)); }
        if c not in forks { forks[c] = Fork(tag=str(c)); }
        forks[p] ++> forks[c];
    }
    w = forks[base] spawn LeafSeek();
    return w.answer;
}

with entry {
    print(first_leaf_name({'parent': {'b': 'a', 'c': 'a', 'd': 'b'}, 'root': 'a'}));
}
