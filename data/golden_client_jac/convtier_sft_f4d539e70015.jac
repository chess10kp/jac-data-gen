node VNode {
    has val: int;
}

walker CountAbove {
    has threshold: int;
    has count: int = 0;

    can chk with VNode entry {
        if here.val > self.threshold { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = VNode(val=3);
    b = VNode(val=7);
    c = VNode(val=9);
    d = VNode(val=2);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CountAbove(threshold=5);
    print(w.count);
}
