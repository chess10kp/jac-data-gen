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

"""Spawn on a Person: report their first cousins (shared grandparent, no shared parent)."""
walker Cousins {
    has found: list[str] = [];

    can find with Person entry {
        me = here;
        parents = [me <-:ParentOf:<-];
        grandparents = [me <-:ParentOf:<- <-:ParentOf:<-];
        names: set[str] = set();
        for kin in [grandparents ->:ParentOf:-> ->:ParentOf:->] {
            if kin == me {
                continue;
            }
            shared = [p for p in [kin <-:ParentOf:<-] if p in parents];
            if len(shared) < len(parents) {
                names.add(kin.name);
            }
        }
        self.found = sorted(names);
        report self.found;
    }
}
