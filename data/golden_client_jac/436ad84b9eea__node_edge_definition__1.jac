node Person {
    has name: str;
}

edge Knows {
    has since: int;      # Year they met
    has strength: str;   # "close", "acquaintance"
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    # Connect with a typed edge
    alice +>: Knows(since=2020, strength="close") :+> bob;
}
