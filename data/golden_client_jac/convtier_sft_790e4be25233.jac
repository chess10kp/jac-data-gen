node DNode {
    has val: int;
}

walker AnyNegative {
    has found: bool = False;

    can chk with DNode entry {
        if here.val < 0 {
            self.found = True;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = DNode(val=1);
    b = DNode(val=-2);
    c = DNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn AnyNegative();
    print(w.found);
}
