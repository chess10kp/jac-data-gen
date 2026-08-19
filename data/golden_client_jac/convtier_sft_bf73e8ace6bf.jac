node MNode {
    has val: int;
}

walker ProductPositive {
    has result: int = 1;

    can chk with MNode entry {
        if here.val > 0 { self.result *= here.val; }
        visit [-->];
    }
}

with entry {
    a = MNode(val=2);
    b = MNode(val=-1);
    c = MNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn ProductPositive();
    print(w.result);
}
