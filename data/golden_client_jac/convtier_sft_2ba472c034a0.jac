node Person {
    has name: str;
}

edge Friend {}

walker FoF {
    has origin: str = "";
    has direct: list[str] = [];
    has result: list[str] = [];

    can collect with Person entry {
        if self.origin == "" {
            self.origin = here.name;
            self.direct = [p.name for p in [-->]];
            visit [-->];
        } else {
            for p in [-->] {
                if p.name != self.origin
                   and p.name not in self.direct
                   and p.name not in self.result {
                    self.result.append(p.name);
                }
            }
        }
    }
}

with entry {
    alice = Person(name="alice");
    bob = Person(name="bob");
    carol = Person(name="carol");
    dave = Person(name="dave");
    root ++> alice;
    alice +>:Friend:+> bob;
    alice +>:Friend:+> carol;
    bob +>:Friend:+> dave;
    carol +>:Friend:+> dave;
    w = alice spawn FoF();
    print(sorted(w.result));
}
