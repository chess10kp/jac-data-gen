node NNode {
    has val: int;
}

walker MaxVal {
    has best: int = -2147483648;

    can chk with NNode entry {
        if here.val > self.best { self.best = here.val; }
        visit [-->];
    }
}

with entry {
    a = NNode(val=3);
    b = NNode(val=9);
    c = NNode(val=5);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn MaxVal();
    print(w.best);
}
