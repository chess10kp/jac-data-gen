node Person {
    has name: str;
}

edge Friend {
    has since: int;  # Year they became friends
}

edge Coworker {
    has department: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");

    # Different types of relationships
    alice +>:Friend(since=2015):+> bob;
    alice +>:Coworker(department="Engineering"):+> charlie;
}
