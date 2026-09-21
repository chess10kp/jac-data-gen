"""List every sibling for each person in a family tree.

Finding siblings reverses direction mid-chain: walk backwards up to
the shared parents, then forwards down again.
"""

node Person {
    has name: str;
    has birth_year: int;
}

edge ParentOf: Person --> Person {}

walker SiblingFinder {
    has reports: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can check with Person entry {
        # Up to parents, then back down to their other children
        siblings = [here <-:ParentOf:<- ->:ParentOf:->];

        found = 0;
        for s in siblings {
            if s.name != here.name {
                self.reports.append(f"{here.name} ({here.birth_year}) has sibling {s.name} ({s.birth_year})");
                found += 1;
            }
        }
        if found == 0 {
            print(f"{here.name} is an only child");
        } else {
            print(f"{here.name}: {found} sibling(s)");
        }
        visit [->:ParentOf:->];
    }

    can finish with Root exit {
        print("-- Sibling report --");
        for line in self.reports {
            print(line);
        }
    }
}

with entry {
    hana = Person(name="Hana", birth_year=1960);
    luis = Person(name="Luis", birth_year=1962);
    mia = Person(name="Mia", birth_year=1988);
    noah = Person(name="Noah", birth_year=1991);
    ivy = Person(name="Ivy", birth_year=1995);

    hana +>: ParentOf() :+> mia;
    hana +>: ParentOf() :+> noah;
    luis +>: ParentOf() :+> noah;
    luis +>: ParentOf() :+> ivy;

    root ++> hana ++> luis;
    root spawn SiblingFinder();
}
