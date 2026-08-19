node Person {
    has name: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    # Bidirectional connection (mutual friendship)
    alice <++> bob;

    # New mutual friendships added
    bob <++> charlie;
    alice <++> charlie;
}
