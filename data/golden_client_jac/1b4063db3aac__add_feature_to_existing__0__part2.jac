node Person {
    has name: str;
}

edge Friend {
    has since: int;
}

edge Coworker {
    has department: str;
}

# New edge type added
edge Family {
    has relation: str;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    charlie = Person(name="Charlie");
    diana = Person(name="Diana");

    alice +>:Friend(since=2015):+> bob;
    alice +>:Coworker(department="Engineering"):+> charlie;
    alice +>:Family(relation="sister"):+> diana;
}
