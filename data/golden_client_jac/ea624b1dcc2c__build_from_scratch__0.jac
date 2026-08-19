node Person {
    has name: str;
}

edge Friend {
    has since: int;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    alice +>:Friend(since=2015):+> bob;
}
