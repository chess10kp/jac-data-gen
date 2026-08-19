node BNode {
    has name: str;
}

walker CountLeaves {
    has count: int = 0;

    can chk with BNode entry {
        if not [-->] { self.count += 1; }
        visit [-->];
    }
}

with entry {
    r1 = BNode(name="r1");
    r2 = BNode(name="r2");
    r3 = BNode(name="r3");
    r4 = BNode(name="r4");
    root ++> r1;
    r1 ++> r2;
    r1 ++> r3;
    r2 ++> r4;
    w = r1 spawn CountLeaves();
    print(w.count);
}
