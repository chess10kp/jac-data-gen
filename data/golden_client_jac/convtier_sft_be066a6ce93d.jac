node BNode {
    has val: int;
}

walker CountBelow {
    has threshold: int;
    has count: int = 0;

    can chk with BNode entry {
        if here.val < self.threshold { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = BNode(val=3);
    b = BNode(val=7);
    c = BNode(val=2);
    d = BNode(val=9);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CountBelow(threshold=5);
    print(w.count);
}
