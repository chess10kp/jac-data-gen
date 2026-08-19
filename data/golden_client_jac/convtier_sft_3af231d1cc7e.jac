node User { has name: str; }
node Post {}
edge Follows {}

walker FanCount {
    has moved: bool = False;
    has count: int = 0;
    can seek with User entry {
        if not self.moved {
            self.moved = True;
            visit [->:Follows:->][?:User];
        } else {
            visit [-->][?:Post];
        }
    }
    can tally with Post entry { self.count += 1; }
}

def fan_post_count(spec: dict) -> int {
    who: str = str(spec["who"]);
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for (src, tgts) in dict(spec["follows"]).items() {
        for t in list(tgts) {
            if src in unodes and t in unodes { unodes[src] +>:Follows:+> unodes[t]; }
        }
    }
    for p in list(spec["posts"]) {
        if p["author"] in unodes { unodes[p["author"]] ++> Post(); }
    }
    if who not in unodes { return 0; }
    return (unodes[who] spawn FanCount()).count;
}

with entry {
    print(fan_post_count({'users': ['a', 'b', 'c'], 'follows': {'a': ['b', 'c']}, 'posts': [{'author': 'a'}, {'author': 'b'}, {'author': 'b'}, {'author': 'c'}], 'who': 'a'}));
}
