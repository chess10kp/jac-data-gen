node Post { has id: str; }
edge Repost {}

walker ChainWalk {
    has path: list = [];
    has seen: dict = {};
    can step with Post entry {
        if here.id not in self.seen {
            self.seen[here.id] = True;
            self.path.append(here.id);
            best_id: str = "";
            for k in [->:Repost:->][?:Post] {
                if k.id not in self.seen and (best_id == "" or k.id < best_id) { best_id = k.id; }
            }
            if best_id != "" {
                for k in [->:Repost:->][?:Post] {
                    if k.id == best_id { visit [k]; }
                }
            }
        }
    }
}

def repost_chain(spec: dict) -> str {
    pnodes: dict = {};
    for pid in list(spec["posts"]) { pnodes[pid] = Post(id=str(pid)); }
    for r in list(spec["reposts"]) {
        if r[0] in pnodes and r[1] in pnodes { pnodes[r[1]] +>:Repost:+> pnodes[r[0]]; }
    }
    start: str = str(spec["start"]);
    if start not in pnodes { return ""; }
    w = pnodes[start] spawn ChainWalk();
    return ">".join(w.path);
}

with entry {
    print(repost_chain({'posts': ['p1', 'p2', 'p3', 'p4'], 'reposts': [['p2', 'p1'], ['p3', 'p2'], ['p4', 'p3']], 'start': 'p1'}));
}
