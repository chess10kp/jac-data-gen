node User { has name: str; }
edge Follow {}

walker BackScan {
    has base: str;
    has moved: bool = False;
    has hits: list = [];
    can seek with User entry {
        if not self.moved { self.moved = True; visit [->:Follow:->][?:User]; }
        elif here.name > self.base {
            for f in [->:Follow:->][?:User] {
                if f.name == self.base { self.hits.append(self.base + "|" + here.name); }
            }
        }
    }
}

def mutual_follow_pairs(spec: dict) -> list {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
    out: list = [];
    for u in sorted(unodes.keys()) {
        w = unodes[u] spawn BackScan(base=u);
        out.extend(w.hits);
    }
    return sorted(out);
}

with entry {
    print(mutual_follow_pairs({'users': ['ava', 'ben', 'cleo'], 'follows': [['ava', 'ben'], ['ben', 'ava'], ['ben', 'cleo'], ['cleo', 'ben'], ['cleo', 'ava']]}));
}
