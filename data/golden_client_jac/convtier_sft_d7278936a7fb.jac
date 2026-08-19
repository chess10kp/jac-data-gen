node ENode {
    has val: int;
}

walker AllEven {
    has ok: bool = True;

    can chk with ENode entry {
        if here.val % 2 != 0 {
            self.ok = False;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = ENode(val=2);
    b = ENode(val=4);
    c = ENode(val=6);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn AllEven();
    print(w.ok);
}
