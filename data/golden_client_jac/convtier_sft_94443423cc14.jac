node User { has name: str; }
node Post { has id: str; }
edge Wrote {}
edge Like {}

walker LikeTally {
    has total: int = 0;
    can seek with User entry { visit [->:Wrote:->][?:Post]; }
    can tally with Post entry { self.total += len([<-:Like:<-][?:User]); }
}

def post_like_total(spec: dict) -> int {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    pnodes: dict = {};
    for p in list(spec["posts"]) {
        if p["author"] in unodes {
            pn = Post(id=str(p["id"]));
            pnodes[p["id"]] = pn;
            unodes[p["author"]] +>:Wrote:+> pn;
        }
    }
    for l in list(spec["likes"]) {
        if l[0] in unodes and l[1] in pnodes { unodes[l[0]] +>:Like:+> pnodes[l[1]]; }
    }
    who: str = str(spec["who"]);
    if who not in unodes { return 0; }
    return (unodes[who] spawn LikeTally()).total;
}

with entry {
    print(post_like_total({'users': ['ava', 'ben', 'cleo'], 'posts': [{'id': 'p1', 'author': 'ava'}, {'id': 'p2', 'author': 'ava'}, {'id': 'p3', 'author': 'ben'}], 'likes': [['ben', 'p1'], ['cleo', 'p1'], ['cleo', 'p2'], ['ava', 'p3']], 'who': 'ava'}));
}
