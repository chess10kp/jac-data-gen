node TreeNode {
    has val: int;
}

walker NodeCounter {
    has count: int = 0;

    can tally with TreeNode entry {
        self.count += 1;
        visit [-->];
    }
}

with entry {
    r1 = TreeNode(val=1);
    r2 = TreeNode(val=2);
    r3 = TreeNode(val=3);
    r4 = TreeNode(val=4);
    root ++> r1;
    r1 ++> r2;
    r1 ++> r3;
    r2 ++> r4;
    w = r1 spawn NodeCounter();
    print(w.count);
}
