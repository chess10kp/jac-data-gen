node Leaf3 {
    has val: int;
}

walker ProductLeaves {
    has result: int = 1;

    can chk with Leaf3 entry {
        if not [-->] { self.result *= here.val; }
        visit [-->];
    }
}

with entry {
    r1 = Leaf3(val=1);
    r2 = Leaf3(val=2);
    r3 = Leaf3(val=3);
    r4 = Leaf3(val=4);
    root ++> r1;
    r1 ++> r2;
    r1 ++> r3;
    r2 ++> r4;
    w = r1 spawn ProductLeaves();
    print(w.result);
}
