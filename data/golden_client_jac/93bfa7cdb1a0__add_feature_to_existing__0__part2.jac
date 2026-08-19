node Person {
    has name: str;
}

walker Explorer {
    has visited: list = [];

    can explore with Person entry {
        # New: skip nodes we've already seen to avoid re-processing
        if here.name in self.visited {
            return;
        }
        self.visited.append(here.name);
        print(f"Visiting {here.name}");
        visit [-->];
    }
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    root ++> alice ++> bob;
    alice ++> bob;
    root spawn Explorer();
}
