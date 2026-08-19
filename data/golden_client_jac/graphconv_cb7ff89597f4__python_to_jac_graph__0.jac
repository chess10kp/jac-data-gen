node Person { has name: str; }
edge Sire {}

walker ClimbUp {
    has steps: int;
    has answer: str = "none";

    can climb with Person entry {
        if self.steps == 0 {
            self.answer = here.name;
        } else {
            ups = [->:Sire:->];
            if ups {
                self.steps -= 1;
                visit ups[0];
            }
        }
    }
}

with entry {
    a = Person(name="A"); b = Person(name="B"); c = Person(name="C");
    d = Person(name="D"); e = Person(name="E");
    e +>:Sire:+> d;
    d +>:Sire:+> c;
    c +>:Sire:+> b;
    b +>:Sire:+> a;
    w = e spawn ClimbUp(steps=2);
    print(f"kth ancestor = {w.answer}");
}
