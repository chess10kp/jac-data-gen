node Person {
    has name: str;
}

walker FindPerson {
    has target: str;
    has found: bool = False;

    can start with Root entry {
        visit [-->];
    }

    can search with Person entry {
        if here.name == self.target {
            print(f"Found {here.name}!");
            self.found = True;
            disengage;  # Stop immediately
        }
        visit [-->];
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    root ++> alice ++> bob ++> charlie;

    finder = FindPerson(target="Bob");
    root spawn finder;

    print(f"Found: {finder.found}");
}
