node Post {}
edge Road { has dist: int; }

walker HeavyCount {
    has limit: int;
    has n: int = 0;
    can check with Road entry {
        if here.dist >= self.limit { self.n += 1; }
    }
    can advance with Post entry { visit [edge -->]; }
}

def count_heavy_roads(spec: dict) -> int {
    dists: list = list(spec["dists"]);
    posts: list = [Post() for _ in range(len(dists) + 1)];
    for (i, d) in enumerate(dists) {
        posts[i] +>:Road(dist=int(d)):+> posts[i + 1];
    }
    return (posts[0] spawn HeavyCount(limit=int(spec["limit"]))).n;
}

with entry {
    print(count_heavy_roads({'dists': [3, 7, 5], 'limit': 5}));
}
