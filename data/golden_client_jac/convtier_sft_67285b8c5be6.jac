node Named {
    has name: str;
}

walker CountPrefix {
    has prefix: str;
    has count: int = 0;

    can chk with Named entry {
        if here.name.startswith(self.prefix) { self.count += 1; }
        visit [-->];
    }
}

with entry {
    a = Named(name="alice");
    b = Named(name="bob");
    c = Named(name="amy");
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn CountPrefix(prefix="a");
    print(w.count);
}
