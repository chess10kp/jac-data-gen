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

def parents_of(p: Person) -> list[Person] {
    return [p <-:ParentOf:<-];
}

def children_of(p: Person) -> list[Person] {
    return [p ->:ParentOf:->];
}

walker Cousins {
    has origin: Person | None = None;

    can find with Person entry {
        if self.origin is not None {
            return;
        }
        self.origin = here;
        my_parents = {jid(p) for p in parents_of(here)};
        cousin_ids: dict[str, str] = {};
        for parent in parents_of(here) {
            for gp in parents_of(parent) {
                for aunt_uncle in children_of(gp) {
                    for c in children_of(aunt_uncle) {
                        their_parents = {jid(x) for x in parents_of(c)};
                        if jid(c) != jid(here) and len(their_parents & my_parents) == 0 {
                            cousin_ids[jid(c)] = c.name;
                        }
                    }
                }
            }
        }
        report sorted(cousin_ids.values());
    }
}
