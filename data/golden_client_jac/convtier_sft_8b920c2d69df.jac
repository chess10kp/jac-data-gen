node PNode {
    has val: int;
}

walker AllPositive {
    has ok: bool = True;

    can chk with PNode entry {
        if here.val <= 0 {
            self.ok = False;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = PNode(val=1);
    b = PNode(val=2);
    c = PNode(val=3);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn AllPositive();
    print(w.ok);
}
