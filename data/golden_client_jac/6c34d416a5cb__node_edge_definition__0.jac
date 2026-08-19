node Person {
    has name: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    # Bidirectional connection (mutual friendship)
    alice <++> bob;
}
