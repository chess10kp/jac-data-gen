node TreeNode {
    has name: str;
}

edge Left {}
edge Right {}

walker InvertPreorder {
    has order: list = [];

    can start with Root entry {
        visit [-->];
    }

    can walk with TreeNode entry {
        self.order.append(here.name);
        # Mirroring a tree = visiting the RIGHT subtree before the LEFT.
        # Front-insert for DFS: queue Left first, then Right, so Right
        # ends up at the front of the queue and is explored first.
        visit :0: [->:Left:->];
        visit :0: [->:Right:->];
    }
}

with entry {
    a = TreeNode(name="A");
    b = TreeNode(name="B");
    c = TreeNode(name="C");
    d = TreeNode(name="D");
    e = TreeNode(name="E");
    f = TreeNode(name="F");

    root ++> a;
    a +>:Left:+> b;
    a +>:Right:+> c;
    b +>:Left:+> d;
    b +>:Right:+> e;
    c +>:Right:+> f;

    w = root spawn InvertPreorder();
    print(w.order);
}
