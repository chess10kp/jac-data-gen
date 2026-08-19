node TreeNode {
    has name: str;
    has depth: int = 0;
}

edge Child {}

walker LeafCounter {
    has depths: list = [];

    can start with Root entry {
        visit [-->];
    }

    can walk with TreeNode entry {
        children = [->:Child:->];
        if len(children) == 0 {
            self.depths.append(here.depth);
        }
        for c in children {
            c.depth = here.depth + 1;
        }
        visit children;
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
    d +>:Child:+> g;

    w = root spawn LeafCounter();
    counts = {};
    for dep in sorted(w.depths) {
        counts[dep] = counts.get(dep, 0) + 1;
    }
    print(sorted(counts.items()));
}
