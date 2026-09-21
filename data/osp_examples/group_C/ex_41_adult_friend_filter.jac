"""Recommend new friends for every adult in a small social circle.

Some members of the circle registered their pets as profile nodes too,
so raw neighbour lists are noisy. The recommender filters neighbours
down to actual people before suggesting them, and only keeps adults.
"""

node Person {
    has name: str;
    has age: int;
}

node Pet {
    has name: str;
    has species: str;
}

edge Friend {}

walker Recommender {
    has reports: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can suggest with Person entry {
        # Neighbours via Friend edges, narrowed to Person nodes only --
        # pet profiles ride the same edges and must be excluded
        people = [->:Friend:->][?:Person];

        # Of those, only adults are valid recommendation targets
        adults = [->:Friend:->][?:Person, age >= 18];

        for p in adults {
            if p.name != here.name {
                self.reports.append(f"{here.name} ({here.age}) could befriend {p.name} ({p.age})");
            }
        }

        # The raw hop sees pets too; type and age filters cut it down
        everyone = [->:Friend:->];
        print(f"{here.name}: {len(everyone)} neighbour(s) raw, {len(people)} person(s), {len(adults)} adult(s)");
        visit [-->];
    }

    can wrap with Root exit {
        print("-- Recommendations --");
        for line in self.reports {
            print(line);
        }
    }
}

with entry {
    alice = Person(name="Alice", age=34);
    bob = Person(name="Bob", age=15);
    carol = Person(name="Carol", age=27);
    dave = Person(name="Dave", age=41);
    whiskers = Pet(name="Whiskers", species="cat");

    alice +>: Friend() :+> bob;
    alice +>: Friend() :+> carol;
    alice +>: Friend() :+> whiskers;
    carol +>: Friend() :+> dave;

    root ++> alice;
    root spawn Recommender();
}
