node Person {
    has name: str;
    has birth_year: int;
    has depth: int = 0;  # Tracks depth in the ancestry tree
}

edge Parent {
    # No extra properties needed
}

walker FindAncestors {
    has max_generations: int = 3;

    can start with Root entry {
        visit [-->];
    }

    can explore with Person entry {
        print(f"{'  ' * here.depth}{here.name} (born {here.birth_year})");

        if here.depth < self.max_generations {
            # Set depth on parents before visiting
            parents = [here <-:Parent:<-];
            for p in parents {
                p.depth = here.depth + 1;
            }
            visit parents;
        }
    }
}

with entry {
    # Create family
    alice = Person(name="Alice", birth_year=2000);
    bob = Person(name="Bob", birth_year=1975);
    carol = Person(name="Carol", birth_year=1978);
    dave = Person(name="Dave", birth_year=1950);
    eve = Person(name="Eve", birth_year=1952);

    # Build family tree (parents point to children)
    bob +>:Parent:+> alice;
    carol +>:Parent:+> alice;
    dave +>:Parent:+> bob;
    eve +>:Parent:+> bob;

    # Find ancestors
    root ++> alice;
    print("Family tree:");
    root spawn FindAncestors(max_generations=3);
}
