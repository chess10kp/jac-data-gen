node Person { has name: str; }
edge Friend { has since: int = 2020; }
edge Colleague { has department: str = ""; }

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");

    # Untyped (generic edge)
    alice ++> bob;

    # Typed edge
    alice +>: Friend(since=2020) :+> bob;

    # Bidirectional typed
    alice <+: Colleague(department="Engineering") :+> bob;
}
