node Item { has name: str; }
edge Link {}

walker Counter {
    has count: int = 0;

    can start with Root entry {
        visit [-->];
    }
    can step with Item entry {
        self.count += 1;
        visit [-->];
    }
}

with entry {
    root ++> (a := Item(name="a"));
    root ++> (b := Item(name="b"));
    root ++> (c := Item(name="c"));
    a +>:Link:+> b;
    b +>:Link:+> c;
    c +>:Link:+> a;   # cycle a->b->c->a
    w = root spawn Counter();
    print("entries:", w.count);   # once-per-node => 3; else >3 or hang
}
