node PNode {
    has val: int;
}

walker SumPositive {
    has total: int = 0;

    can chk with PNode entry {
        if here.val > 0 { self.total += here.val; }
        visit [-->];
    }
}

with entry {
    a = PNode(val=1);
    b = PNode(val=-2);
    c = PNode(val=3);
    d = PNode(val=4);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn SumPositive();
    print(w.total);
}
