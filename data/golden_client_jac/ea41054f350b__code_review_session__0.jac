node Person {
    has name: str;
}
edge Friend {
    has since: int = 2020;
}
with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    root ++> alice;
    alice ++> bob;
    alice +>: Friend() :+> bob;
}
