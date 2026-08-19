node RNode {
    has name: str;
}

walker Reach {
    has target: str;
    has found: bool = False;

    can look with RNode entry {
        if here.name == self.target {
            self.found = True;
            disengage;
        }
        visit [-->];
    }
}

with entry {
    a = RNode(name="a");
    b = RNode(name="b");
    c = RNode(name="c");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Reach(target="c");
    print(w.found);
}
