node Place {
    has name: str;
    has dist: int = -1;
}

edge Route {}

walker ReachWalker {
    has max_hops: int;
    has result: list = [];

    can start with Root entry {
        visit [-->];
    }

    can walk with Place entry {
        self.result.append(here.name);
        for nb in [->:Route:->] {
            if nb.dist == -1 and here.dist + 1 <= self.max_hops {
                nb.dist = here.dist + 1;
                visit nb;
            }
        }
    }
}

with entry {
    s = Place(name="S", dist=0);
    a = Place(name="A");
    b = Place(name="B");
    c = Place(name="C");
    d = Place(name="D");
    e = Place(name="E");

    root ++> s;
    s +>:Route:+> a;
    s +>:Route:+> b;
    a +>:Route:+> c;
    b +>:Route:+> c;
    c +>:Route:+> d;
    d +>:Route:+> e;

    w = root spawn ReachWalker(max_hops=2);
    print(sorted(w.result));
}
