node User { has name: str; }
node Post { has id: str; }
edge Wrote {}
edge Like {}

walker LikeSum {
    has total: int = 0;
    can seek with User entry { visit [->:Wrote:->][?:Post]; }
    can tally with Post entry { self.total += len([<-:Like:<-][?:User]); }
}

def engagement_report(spec: dict) -> str {
    names: list = sorted(set(list(spec["users"])));
    unodes: dict = {};
    for nm in names { unodes[nm] = User(name=str(nm)); }
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
    pairs: list = [];
    for u in names {
        w = unodes[u] spawn LikeSum();
        pairs.append((-w.total, u));
    }
    pairs.sort();
    return ",".join([p[1] + "=" + str(-p[0]) for p in pairs]);
}

with entry {
    print(engagement_report({'users': ['ava', 'ben', 'cleo'], 'posts': [{'id': 'p1', 'author': 'ava'}, {'id': 'p2', 'author': 'ben'}, {'id': 'p3', 'author': 'ava'}], 'likes': [['ben', 'p1'], ['cleo', 'p1'], ['cleo', 'p3'], ['ava', 'p2']]}));
}
