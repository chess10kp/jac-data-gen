node Employee {
    has name: str;
}

walker CountReports {
    has count: int = 0;
    has started: bool = False;

    can tally with Employee entry {
        if self.started { self.count += 1; } else { self.started = True; }
        visit [-->];
    }
}

with entry {
    ceo = Employee(name="ceo");
    a = Employee(name="a");
    b = Employee(name="b");
    c = Employee(name="c");
    root ++> ceo;
    ceo ++> a;
    ceo ++> b;
    a ++> c;
    w = ceo spawn CountReports();
    print(w.count);
}
