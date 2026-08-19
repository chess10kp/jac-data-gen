node Pin { has name: str; has hit: bool = False; }

walker Linker {
    has want: str;
    has joined: bool = False;
    can seek with Pin entry {
        if here.hit { return; }
        here.hit = True;
        if here.name == self.want {
            self.joined = True;
            disengage;
        }
        visit [-->];
    }
}

def same_component(spec: dict) -> bool {
    reg: dict = {};
    for nm in list(spec["nodes"]) { reg[nm] = Pin(name=str(nm)); }
    for pr in list(spec["links"]) { reg[pr[0]] <++> reg[pr[1]]; }
    w = reg[spec["u"]] spawn Linker(want=str(spec["v"]));
    return w.joined;
}

with entry {
    print(same_component({'nodes': ['a', 'b', 'c', 'd'], 'links': [['a', 'b'], ['c', 'd']], 'u': 'a', 'v': 'd'}));
}
