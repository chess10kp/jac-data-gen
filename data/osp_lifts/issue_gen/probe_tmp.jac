node N { has name: str; }
edge E { has k: str; }
walker W {
    has claimed: dict[str, bool] = {};
    has steps: list[str] = [];
    can step with N entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.steps.append(here.name);
        visit [-->];
        visit [<--];
    }
}
walker WB {
    has claimed: dict[str, bool] = {};
    has steps: list[str] = [];
    can step with N entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.steps.append(here.name);
        visit [<-->] else { disengage; }
    }
}
with entry {
    a = N(name="a"); b = N(name="b"); c = N(name="c");
    root ++> a; root ++> b; root ++> c;
    a +>:E(k="1"):+> b;
    a +>:E(k="2"):+> b;
    b +>:E(k="3"):+> c;
    w = a spawn W();
    print("W steps:", w.steps);
    w2 = a spawn WB();
    print("WB steps:", w2.steps);
    names: list[str] = [];
    for nb in [b <-->] {
        if nb is N {
            names.append(nb.name);
        }
    }
    print("b undirected <--> filtered:", sorted(names));
    print("PROBE DONE");
}
