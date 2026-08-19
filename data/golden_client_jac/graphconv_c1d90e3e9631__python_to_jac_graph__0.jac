node TreeNode {
    has name: str;
}

edge Child {}

walker Ancestors {
    has names: list = [];

    can up with TreeNode entry {
        self.names.append(here.name);
        visit [<-:Child:<-];
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
    h = TreeNode(name="H");

    root ++> a;
    a +>:Child:+> b;
    a +>:Child:+> c;
    b +>:Child:+> d;
    b +>:Child:+> e;
    c +>:Child:+> f;
    e +>:Child:+> g;
    e +>:Child:+> h;

    # Walk upward from each target, collecting its ancestor chain.
    anc1 = (g spawn Ancestors()).names;
    anc2 = set((h spawn Ancestors()).names);

    lca = None;
    for n in anc1 {
        if n in anc2 {
            lca = n;
            break;
        }
    }
    print(lca);
}
