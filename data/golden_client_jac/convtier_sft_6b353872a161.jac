node User { has name: str; }
node Post { has likes: int; }

walker LoyalCheck {
    has low: int;
    has total: int = 0;
    has bad: int = 0;
    can seek with User entry { visit [-->][?:Post]; }
    can judge with Post entry {
        self.total += 1;
        if here.likes < self.low { self.bad += 1; }
    }
}

def loyal_users(spec: dict) -> list {
    low: int = int(spec["min"]);
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for p in list(spec["posts"]) {
        if p["author"] in unodes { unodes[p["author"]] ++> Post(likes=int(p["likes"])); }
    }
    out: list = [];
    for u in sorted(unodes.keys()) {
        w = unodes[u] spawn LoyalCheck(low=low);
        if w.total > 0 and w.bad == 0 { out.append(u); }
    }
    return out;
}

with entry {
    print(loyal_users({'users': ['ana', 'bob', 'cara'], 'posts': [{'author': 'ana', 'likes': 8}, {'author': 'ana', 'likes': 5}, {'author': 'bob', 'likes': 2}, {'author': 'cara', 'likes': 9}], 'min': 5}));
}
