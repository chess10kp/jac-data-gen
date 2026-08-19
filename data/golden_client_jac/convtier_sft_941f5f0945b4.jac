node VNode {
    has val: int;
}

walker SumEven {
    has total: int = 0;

    can add with VNode entry {
        if here.val % 2 == 0 { self.total += here.val; }
        visit [-->];
    }
}

with entry {
    a = VNode(val=1);
    b = VNode(val=2);
    c = VNode(val=3);
    d = VNode(val=4);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn SumEven();
    print(w.total);
}
