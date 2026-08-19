node Person {
    has name: str;
}

edge Friend {
    has since: int = 2020;
}

with entry {
    node1 = Person(name="Alice");
    node2 = Person(name="Bob");

    # Untyped connections
    node1 ++> node2;         # Forward
    node1 <++ node2;         # Backward
    node1 <++> node2;        # Bidirectional

    # Typed connections
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    alice +>: Friend(since=2020) :+> bob;
}
