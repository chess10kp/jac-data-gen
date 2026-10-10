"""Family tree: ParentOf edges point from parent to child."""

node Person {
    has name: str;
    has born: int = 0;
}

edge ParentOf: Person --> Person {}

"""Create a child and link the given parents to it."""
def child_of(name: str, parents: list[Person]) -> Person {
    kid = Person(name=name);
    if not parents {
        root ++> kid;
    }
    for p in parents {
        p +>:ParentOf():+> kid;
    }
    return kid;
}
