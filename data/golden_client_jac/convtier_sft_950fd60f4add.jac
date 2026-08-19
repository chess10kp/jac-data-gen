node ENode {
    has val: int;
}

walker CountEven {
    has count: int = 0;

    can chk with ENode entry {
        if here.val % 2 == 0 { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = ENode(val=1);
    b = ENode(val=2);
    c = ENode(val=4);
    d = ENode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    c ++> d;
    w = a spawn CountEven();
    print(w.count);
}
