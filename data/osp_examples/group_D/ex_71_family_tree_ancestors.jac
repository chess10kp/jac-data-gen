"""Family-tree ancestor query walking against edge direction.

ParentOf edges point from parent to child, so finding someone's ancestors
means traversing backwards. A hop walker starts at the child and spawns
itself on every parent, tagging each reached person with its generation
distance; the driver groups the tagged people into generations.
"""

node Person {
    has name: str;
    has gen_label: int = -1;  # distance from the query person; -1 = untouched
}

edge ParentOf: Person --> Person {}

walker AncestorHop {
    has gen: int;

    can climb with Person entry {
        if here.gen_label != -1 {
            skip;  # reached through another branch already
        }
        here.gen_label = self.gen;

        # Walk backwards along ParentOf to reach the parents.
        for parent in [<-:ParentOf:<-] {
            parent spawn AncestorHop(gen=self.gen + 1);
        }
    }
}

with entry {
    # Reset leftovers from any previous run of this demo.
    for stale in [root -->][?:Person] {
        del stale;
    }

    george = Person(name="George");
    gloria = Person(name="Gloria");
    frank = Person(name="Frank");
    frida = Person(name="Frida");
    henry = Person(name="Henry");
    helena = Person(name="Helena");
    ivy = Person(name="Ivy");

    george +>: ParentOf() :+> henry;
    gloria +>: ParentOf() :+> henry;
    frank +>: ParentOf() :+> helena;
    frida +>: ParentOf() :+> helena;
    henry +>: ParentOf() :+> ivy;
    helena +>: ParentOf() :+> ivy;

    ivy spawn AncestorHop(gen=0);

    # Group everyone the walker touched into generations.
    gen_people: list[list[str]] = [];
    family = [george, gloria, frank, frida, henry, helena, ivy];
    for p in family {
        if p.gen_label < 0 {
            continue;
        }
        g = p.gen_label;
        while len(gen_people) <= g {
            gen_people.append([]);
        }
        row = gen_people[g];
        row.append(p.name);
    }

    labels = [
        "the person",
        "parents",
        "grandparents",
        "great-grandparents",
    ];
    for g in range(len(gen_people)) {
        label = labels[g] if g < len(labels) else f"generation {g}";
        names = ", ".join(gen_people[g]);
        print(f"Generation {g} ({label}): {names}");
    }
}
