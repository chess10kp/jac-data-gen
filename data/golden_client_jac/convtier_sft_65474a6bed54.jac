node User { has name: str; }
node Post {}
edge Follow {}

walker FeedCount {
    has base: str;
    has count: int = 0;
    can seek with User entry {
        if here.name == self.base {
            visit [-->][?:Post];
            visit [->:Follow:->][?:User];
        } else { visit [-->][?:Post]; }
    }
    can tally with Post entry { self.count += 1; }
}

def feed_size(spec: dict) -> int {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
    for p in list(spec["posts"]) {
        if p["author"] in unodes { unodes[p["author"]] ++> Post(); }
    }
    who: str = str(spec["who"]);
    if who not in unodes { return 0; }
    return (unodes[who] spawn FeedCount(base=who)).count;
}

with entry {
    print(feed_size({'users': ['ava', 'ben', 'cleo'], 'follows': [['ava', 'ben']], 'posts': [{'author': 'ava'}, {'author': 'ben'}, {'author': 'ben'}, {'author': 'cleo'}], 'who': 'ava'}));
}
