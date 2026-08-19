node LNode {
    has label: str;
}

walker MaxLen {
    has best: int = 0;

    can chk with LNode entry {
        if len(here.label) > self.best { self.best = len(here.label); }
        visit [-->];
    }
}

with entry {
    a = LNode(label="a");
    b = LNode(label="bbb");
    c = LNode(label="cc");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn MaxLen();
    print(w.best);
}
