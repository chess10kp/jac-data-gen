node Stop {
    has name: str;
}

edge Road {
    has weight: float = 0.0;
}

walker SumWeights {
    has total: float = 0.0;

    can step with Stop entry {
        for e in [edge -->] {
            self.total += e.weight;
        }
        visit [-->];
    }
}

with entry {
    a = Stop(name="a");
    b = Stop(name="b");
    c = Stop(name="c");
    root ++> a;
    a +>:Road(weight=2.0):+> b;
    b +>:Road(weight=4.0):+> c;
    w = a spawn SumWeights();
    print(w.total);
}
