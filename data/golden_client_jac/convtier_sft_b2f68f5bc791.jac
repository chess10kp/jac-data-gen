node RNode {
    has val: int;
}

walker Span {
    has lo: int = 2147483647;
    has hi: int = -2147483648;

    can chk with RNode entry {
        if here.val < self.lo { self.lo = here.val; }
        if here.val > self.hi { self.hi = here.val; }
        visit [-->];
    }
}

with entry {
    a = RNode(val=5);
    b = RNode(val=2);
    c = RNode(val=8);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Span();
    print(w.hi - w.lo);
}
