node User {
    has name: str;
    has dist: int = 99;
    has expanded: bool = False;
}
edge Follow {}

walker ReachScan {
    can roam with User entry {
        if not here.expanded and here.dist < 2 {
            here.expanded = True;
            for nxt in [->:Follow:->][?:User] {
                if here.dist + 1 < nxt.dist { nxt.dist = here.dist + 1; }
            }
            visit [->:Follow:->][?:User];
        }
    }
}

def follower_reach(spec: dict) -> list {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
    who: str = str(spec["who"]);
    if who not in unodes { return []; }
    unodes[who].dist = 0;
    unodes[who] spawn ReachScan();
    return [u for u in sorted(unodes.keys()) if unodes[u].dist >= 1 and unodes[u].dist <= 2];
}

with entry {
    print(follower_reach({'users': ['ava', 'ben', 'cleo', 'dan', 'eve'], 'follows': [['ava', 'ben'], ['ben', 'cleo'], ['cleo', 'dan'], ['ben', 'eve']], 'who': 'ava'}));
}
