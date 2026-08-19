node Stop3 {
    has name: str;
}

edge Link {
    has weight: float = 0.0;
}

walker MaxWeight {
    has best: float = 0.0;

    can step with Stop3 entry {
        for e in [edge -->] {
            if e.weight > self.best { self.best = e.weight; }
        }
        visit [-->];
    }
}

with entry {
    a = Stop3(name="a");
    b = Stop3(name="b");
    c = Stop3(name="c");
    root ++> a;
    a +>:Link(weight=2.0):+> b;
    b +>:Link(weight=5.0):+> c;
    w = a spawn MaxWeight();
    print(w.best);
}
