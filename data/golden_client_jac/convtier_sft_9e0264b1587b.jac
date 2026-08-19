node CNode {
    has val: int;
}

walker CollectEven {
    has out: list[int] = [];

    can chk with CNode entry {
        if here.val % 2 == 0 { self.out.append(here.val); }
        visit [-->];
    }
}

with entry {
    a = CNode(val=1);
    b = CNode(val=2);
    c = CNode(val=3);
    d = CNode(val=4);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CollectEven();
    print(sorted(w.out));
}
