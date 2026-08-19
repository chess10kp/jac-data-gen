node TreeNode {
    has name: str;
    has depth: int = 0;
}

edge Child {}

walker DepthWalker {
    has result: list = [];

    can start with Root entry {
        visit [-->];
    }

    can walk with TreeNode entry {
        self.result.append((here.name, here.depth));
        for c in [->:Child:->] {
            c.depth = here.depth + 1;
        }
        visit [->:Child:->];
    }
}

with entry {
    a = TreeNode(name="A");
    b = TreeNode(name="B");
    c = TreeNode(name="C");
    d = TreeNode(name="D");
    e = TreeNode(name="E");
    f = TreeNode(name="F");
    g = TreeNode(name="G");

    root ++> a;
    a +>:Child:+> b;
    a +>:Child:+> c;
    b +>:Child:+> d;
    b +>:Child:+> e;
    c +>:Child:+> f;
    c +>:Child:+> g;

    w = root spawn DepthWalker();
    for (name, depth) in sorted(w.result) {
        print(f"{name}: {depth}");
    }
}
