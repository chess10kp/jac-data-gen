node ConfigEntry { has key: str; has raw: str; }
edge RefTo {}

walker ResolveWalk {
    has path: dict[str, bool] = {};
    has result: str = "";
    has cyclic: bool = False;
    can step with ConfigEntry entry {
        print("at", here.key);
        if here.key in self.path { self.cyclic = True; skip; }
        self.path[here.key] = True;
        if not (here.raw.startswith("[ref:") and here.raw.endswith("]")) {
            self.result = here.raw;
            disengage;
        }
        tgt = here.raw[5:-1];
        if tgt in self.path { self.cyclic = True; disengage; }
        visit [->:RefTo:->][?:ConfigEntry];
    }
}

with entry {
    a = ConfigEntry(key="A", raw="[ref:B]");
    b = ConfigEntry(key="B", raw="ok");
    root ++> a;
    root ++> b;
    a +>:RefTo:+> b;
    w = a spawn ResolveWalk(path={}, result="", cyclic=False);
    print("linear result", w.result);
    a2 = ConfigEntry(key="A", raw="[ref:B]");
    b2 = ConfigEntry(key="B", raw="[ref:A]");
    root ++> a2;
    root ++> b2;
    a2 +>:RefTo:+> b2;
    b2 +>:RefTo:+> a2;
    w2 = a2 spawn ResolveWalk(path={}, result="", cyclic=False);
    print("cycle cyclic", w2.cyclic);
}
