node BTNode {
    has pos: int;
    has val: int;
}

edge Left {}
edge Right {}

walker Collector {
    has vals: dict = {};

    can grab with BTNode entry {
        self.vals[here.pos] = here.val;
        visit [->:Left:->];
        visit [->:Right:->];
    }
}

walker MergeWalker {
    has other: dict;
    has result: dict = {};

    can grab with BTNode entry {
        self.result[here.pos] = here.val + self.other[here.pos];
        visit [->:Left:->];
        visit [->:Right:->];
    }
}

with entry {
    # Tree 1 (values 1..7), level-order positions 0..6
    a0 = BTNode(pos=0, val=1);
    a1 = BTNode(pos=1, val=2);
    a2 = BTNode(pos=2, val=3);
    a3 = BTNode(pos=3, val=4);
    a4 = BTNode(pos=4, val=5);
    a5 = BTNode(pos=5, val=6);
    a6 = BTNode(pos=6, val=7);
    a0 +>:Left:+> a1;
    a0 +>:Right:+> a2;
    a1 +>:Left:+> a3;
    a1 +>:Right:+> a4;
    a2 +>:Left:+> a5;
    a2 +>:Right:+> a6;

    # Tree 2 (values 10..70), same shape
    b0 = BTNode(pos=0, val=10);
    b1 = BTNode(pos=1, val=20);
    b2 = BTNode(pos=2, val=30);
    b3 = BTNode(pos=3, val=40);
    b4 = BTNode(pos=4, val=50);
    b5 = BTNode(pos=5, val=60);
    b6 = BTNode(pos=6, val=70);
    b0 +>:Left:+> b1;
    b0 +>:Right:+> b2;
    b1 +>:Left:+> b3;
    b1 +>:Right:+> b4;
    b2 +>:Left:+> b5;
    b2 +>:Right:+> b6;

    # Traverse tree 2 to collect its values by position
    t2 = b0 spawn Collector();

    # Traverse tree 1, summing in the overlapping tree-2 values
    m = a0 spawn MergeWalker(other=t2.vals);

    print([m.result[p] for p in sorted(m.result)]);
}
