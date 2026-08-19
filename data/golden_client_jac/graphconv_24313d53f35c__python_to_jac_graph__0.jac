node City {
    has name: str;
}

edge Road {
    has dist: int;
}

walker Longest {
    has best: int = 0;

    can go with City entry {
        b = 0;
        for tgt in [->:Road:->] {
            link = [edge here ->:Road:-> tgt][0];
            sub = tgt spawn Longest();
            b = max(b, link.dist + sub.best);
        }
        self.best = b;
    }
}

with entry {
    a = City(name="A");
    b = City(name="B");
    c = City(name="C");
    d = City(name="D");
    e = City(name="E");
    nodes = [a, b, c, d, e];

    a +>:Road(dist=3):+> b;
    a +>:Road(dist=2):+> c;
    b +>:Road(dist=4):+> d;
    c +>:Road(dist=1):+> d;
    c +>:Road(dist=5):+> e;
    d +>:Road(dist=2):+> e;

    answer = 0;
    for n in nodes {
        r = n spawn Longest();
        answer = max(answer, r.best);
    }
    print(f"longest weighted path = {answer}");
}
