node User { has name: str; }
node Post {}

walker TallyPosts {
    has count: int = 0;
    can seek with User entry { visit [-->][?:Post]; }
    can tally with Post entry { self.count += 1; }
}

def posts_per_user(spec: dict) -> str {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for p in list(spec["posts"]) {
        if p["author"] in unodes { unodes[p["author"]] ++> Post(); }
    }
    parts: list = [];
    for u in sorted(unodes.keys()) {
        parts.append(u + "=" + str((unodes[u] spawn TallyPosts()).count));
    }
    return ",".join(parts);
}

with entry {
    print(posts_per_user({'users': ['bob', 'alice'], 'posts': [{'author': 'alice'}, {'author': 'alice'}, {'author': 'bob'}]}));
}
