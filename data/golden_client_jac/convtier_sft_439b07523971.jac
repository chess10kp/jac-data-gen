node CNode {
    has val: int;
}

walker CollectAll {
    has out: list[int] = [];

    can grab with CNode entry {
        self.out.append(here.val);
        visit [-->];
    }
}

with entry {
    a = CNode(val=3);
    b = CNode(val=1);
    c = CNode(val=2);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn CollectAll();
    print(sorted(w.out));
}
