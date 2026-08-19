node MNode {
    has val: int;
}

walker MinVal {
    has best: int = 2147483647;

    can chk with MNode entry {
        if here.val < self.best { self.best = here.val; }
        visit [-->];
    }
}

with entry {
    a = MNode(val=5);
    b = MNode(val=2);
    c = MNode(val=8);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn MinVal();
    print(w.best);
}
