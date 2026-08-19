node LabelNode {
    has label: str;
}

walker Concat {
    has out: str = "";

    can grab with LabelNode entry {
        self.out += here.label;
        visit [-->];
    }
}

with entry {
    a = LabelNode(label="a");
    b = LabelNode(label="b");
    c = LabelNode(label="c");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn Concat();
    print(w.out);
}
