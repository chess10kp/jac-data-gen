node User { has name: str; }
edge Follow {}

walker FanCount {
    has moved: bool = False;
    has count: int = 0;
    can roam with User entry {
        if not self.moved { self.moved = True; visit [<-:Follow:<-][?:User]; }
        else { self.count += 1; }
    }
}

def follower_count(spec: dict) -> int {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
    who: str = str(spec["who"]);
    if who not in unodes { return 0; }
    return (unodes[who] spawn FanCount()).count;
}

with entry {
    print(follower_count({'users': ['ava', 'ben', 'cleo'], 'follows': [['ben', 'ava'], ['cleo', 'ava'], ['ava', 'ben']], 'who': 'ava'}));
}
