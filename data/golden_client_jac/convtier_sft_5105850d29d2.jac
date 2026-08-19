node Leaf {
    has val: int;
}

walker SumLeaves {
    has total: int = 0;

    can chk with Leaf entry {
        if not [-->] { self.total += here.val; }
        visit [-->];
    }
}

with entry {
    r1 = Leaf(val=1);
    r2 = Leaf(val=2);
    r3 = Leaf(val=3);
    r4 = Leaf(val=4);
    root ++> r1;
    r1 ++> r2;
    r1 ++> r3;
    r2 ++> r4;
    w = r1 spawn SumLeaves();
    print(w.total);
}
