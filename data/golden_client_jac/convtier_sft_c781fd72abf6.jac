node User { has name: str; }
edge Follow {}

walker Suggest {
    has base: str;
    has direct: list = [];
    has cands: list = [];
    can seek with User entry {
        if here.name == self.base {
            for f in [->:Follow:->][?:User] { self.direct.append(f.name); }
            visit [->:Follow:->][?:User];
        } else {
            for f in [->:Follow:->][?:User] { self.cands.append(f.name); }
        }
    }
}

def fof_suggestions(spec: dict) -> list {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
    who: str = str(spec["who"]);
    if who not in unodes { return []; }
    w = unodes[who] spawn Suggest(base=who);
    uniq: dict = {};
    for c in w.cands { uniq[c] = True; }
    return [c for c in sorted(uniq.keys()) if c != who and c not in w.direct];
}

with entry {
    print(fof_suggestions({'users': ['ava', 'ben', 'cleo', 'dan', 'eve'], 'follows': [['ava', 'ben'], ['ava', 'cleo'], ['ben', 'dan'], ['cleo', 'dan'], ['cleo', 'eve'], ['dan', 'ava']], 'who': 'ava'}));
}
