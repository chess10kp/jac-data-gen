node GNode {
    has name: str;
}

walker CollectNames {
    has names: list[str] = [];

    can grab with GNode entry {
        self.names.append(here.name);
        visit [-->];
    }
}

with entry {
    a = GNode(name="a");
    b = GNode(name="b");
    c = GNode(name="c");
    root ++> a;
    a ++> b;
    a ++> c;
    w = a spawn CollectNames();
    print(sorted(w.names));
}
