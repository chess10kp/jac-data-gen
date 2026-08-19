node TNode {
    has name: str;
}

edge Kid {}

walker Measure {
    has height: int = 0;
    has diameter: int = 0;

    can go with TNode entry {
        tops = [0, 0];
        best = 0;
        for c in [->:Kid:->] {
            sub = c spawn Measure();
            best = max(best, sub.diameter);
            h = sub.height + 1;
            if h > tops[0] {
                tops[1] = tops[0];
                tops[0] = h;
            } elif h > tops[1] {
                tops[1] = h;
            }
        }
        through = tops[0] + tops[1];
        self.diameter = max(best, through);
        self.height = tops[0];
    }
}

with entry {
    a = TNode(name="A");
    b = TNode(name="B");
    c = TNode(name="C");
    d = TNode(name="D");
    e = TNode(name="E");
    f = TNode(name="F");
    g = TNode(name="G");

    root ++> a;
    a +>:Kid:+> b;
    a +>:Kid:+> c;
    b +>:Kid:+> d;
    b +>:Kid:+> e;
    d +>:Kid:+> f;
    c +>:Kid:+> g;

    res = a spawn Measure();
    print(f"diameter = {res.diameter}");
}
