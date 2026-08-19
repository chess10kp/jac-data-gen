node Labelled {
    has name: str;
}

walker SumNameLen {
    has total: int = 0;

    can chk with Labelled entry {
        self.total += len(here.name);
        visit [-->];
    }
}

with entry {
    a = Labelled(name="ab");
    b = Labelled(name="cde");
    c = Labelled(name="f");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn SumNameLen();
    print(w.total);
}
