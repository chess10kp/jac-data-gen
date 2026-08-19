node User { has name: str; }
node Post { has id: str; }
edge Follow {}
edge Wrote {}
edge Like {}

walker FeedRank {
    has base: str;
    has pairs: list = [];
    can seek with User entry {
        if here.name == self.base {
            visit [->:Wrote:->][?:Post];
            visit [->:Follow:->][?:User];
        } else { visit [->:Wrote:->][?:Post]; }
    }
    can weigh with Post entry {
        self.pairs.append((-len([<-:Like:<-][?:User]), here.id));
    }
}

def feed_ranking(spec: dict) -> str {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
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
    if who not in unodes { return ""; }
    w = unodes[who] spawn FeedRank(base=who);
    w.pairs.sort();
    return ",".join([p[1] for p in w.pairs]);
}

with entry {
    print(feed_ranking({'users': ['ava', 'ben', 'cleo'], 'follows': [['ava', 'ben']], 'posts': [{'id': 'p1', 'author': 'ava'}, {'id': 'p2', 'author': 'ben'}, {'id': 'p3', 'author': 'ben'}, {'id': 'p4', 'author': 'cleo'}], 'likes': [['cleo', 'p2'], ['ava', 'p2'], ['ben', 'p1'], ['cleo', 'p4']], 'who': 'ava'}));
}
