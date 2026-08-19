node User { has name: str; }
node Post {
    has flagged: bool;
    can confess with ModScan entry {
        visitor.total += 1;
        if self.flagged { visitor.flagged += 1; }
    }
}

walker ModScan {
    has total: int = 0;
    has flagged: int = 0;
    can seek with User entry { visit [-->][?:Post]; }
}

def suspended_users(spec: dict) -> list {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for p in list(spec["posts"]) {
        if p["author"] in unodes { unodes[p["author"]] ++> Post(flagged=bool(p["flagged"])); }
    }
    out: list = [];
    for u in sorted(unodes.keys()) {
        w = unodes[u] spawn ModScan();
        if w.total > 0 and 2 * w.flagged >= w.total { out.append(u); }
    }
    return out;
}

with entry {
    print(suspended_users({'users': ['ana', 'bob'], 'posts': [{'author': 'ana', 'flagged': True}, {'author': 'ana', 'flagged': False}, {'author': 'bob', 'flagged': False}]}));
}
