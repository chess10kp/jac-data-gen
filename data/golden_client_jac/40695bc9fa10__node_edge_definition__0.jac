node Person {
    has name: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    carol = Person(name="Carol");

    # Connect to root (the default starting node)
    root ++> alice;
    root ++> bob;

    # Connect alice to carol
    alice ++> carol;
}
