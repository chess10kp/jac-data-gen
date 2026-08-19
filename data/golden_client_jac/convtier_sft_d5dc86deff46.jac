node GNode {
    has name: str;
}

walker CountChildren {
    has count: int = 0;

    can chk with GNode entry {
        self.count = len([-->]);
        disengage;
    }
}

with entry {
    a = GNode(name="a");
    b = GNode(name="b");
    c = GNode(name="c");
    d = GNode(name="d");
    root ++> a;
    a ++> b;
    a ++> c;
    a ++> d;
    w = a spawn CountChildren();
    print(w.count);
}
