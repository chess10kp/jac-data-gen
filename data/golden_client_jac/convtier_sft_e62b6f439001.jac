node User { has name: str; }
edge Follow {}

walker MutualCheck {
    has other: str;
    has ab: bool = False;
    has ba: bool = False;
    can scan with User entry {
        for f in [->:Follow:->][?:User] { if f.name == self.other { self.ab = True; } }
        for f in [<-:Follow:<-][?:User] { if f.name == self.other { self.ba = True; } }
    }
}

def mutual_follow(spec: dict) -> bool {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
    a: str = str(spec["pair"][0]);
    b: str = str(spec["pair"][1]);
    if a not in unodes or b not in unodes { return False; }
    w = unodes[a] spawn MutualCheck(other=b);
    return w.ab and w.ba;
}

with entry {
    print(mutual_follow({'users': ['ava', 'ben', 'cleo'], 'follows': [['ava', 'ben'], ['ben', 'ava'], ['cleo', 'ava']], 'pair': ['ava', 'ben']}));
}
