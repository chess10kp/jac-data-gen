node User { has name: str; }
node Post {}

walker PostCount {
    has count: int = 0;
    can seek with User entry { visit [-->][?:Post]; }
    can tally with Post entry { self.count += 1; }
}

def count_user_posts(spec: dict) -> int {
    who: str = str(spec["who"]);
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for p in list(spec["posts"]) {
        if p["author"] in unodes { unodes[p["author"]] ++> Post(); }
    }
    if who not in unodes { return 0; }
    return (unodes[who] spawn PostCount()).count;
}

with entry {
    print(count_user_posts({'users': ['alice', 'bob'], 'posts': [{'author': 'alice'}, {'author': 'bob'}, {'author': 'alice'}], 'who': 'alice'}));
}
