node Hub {}
node User { has name: str; }
node Post { has id: str; }
edge Wrote {}
edge Like {}

walker BestPost {
    has best_id: str = "";
    has best_likes: int = -1;
    can fan with Hub entry { visit [-->][?:User]; }
    can seek with User entry { visit [->:Wrote:->][?:Post]; }
    can judge with Post entry {
        likes: int = len([<-:Like:<-][?:User]);
        if likes > self.best_likes or (likes == self.best_likes and here.id < self.best_id) {
            self.best_likes = likes;
            self.best_id = here.id;
        }
    }
}

def top_liked_post(spec: dict) -> str {
    hub = Hub();
    unodes: dict = {};
    for nm in list(spec["users"]) {
        unodes[nm] = User(name=str(nm));
        hub ++> unodes[nm];
    }
    pnodes: dict = {};
    for p in list(spec["posts"]) {
        if p["author"] in unodes {
            pn = Post(id=str(p["id"]));
            pnodes[p["id"]] = pn;
            unodes[p["author"]] +>:Wrote:+> pn;
        }
    }
    if not pnodes { return ""; }
    for l in list(spec["likes"]) {
        if l[0] in unodes and l[1] in pnodes { unodes[l[0]] +>:Like:+> pnodes[l[1]]; }
    }
    return (hub spawn BestPost()).best_id;
}

with entry {
    print(top_liked_post({'users': ['ava', 'ben', 'cleo'], 'posts': [{'id': 'p1', 'author': 'ava'}, {'id': 'p2', 'author': 'ben'}, {'id': 'p3', 'author': 'cleo'}], 'likes': [['ben', 'p2'], ['ava', 'p2'], ['cleo', 'p1']]}));
}
