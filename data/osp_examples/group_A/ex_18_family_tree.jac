"""Family tree: choosing traversal direction explicitly.

From a middle-generation person, `[<--]` walks upward to the parents
while `[<-->]` reaches everyone adjacent in one shot. A genealogy
walker demonstrates both directions from the same starting person.
"""

node Person {
    has name: str = "";
    has generation: int = 0;
}

edge ParentOf {
    has married_into: bool = False;
}

walker Genealogist {
    has focus: str = "Morgan";

    can start with Root entry {
        visit [-->];
    }

    can study with Person entry {
        if here.name == self.focus {
            print(f"Studying {here.name} (generation {here.generation})");

            elders = [<--];
            for elder in elders {
                print(f"  parent: {elder.name}");
            }

            everyone = [<-->];
            names = [p.name for p in everyone];
            print(f"  all directly linked: {names}");

            disengage;
        }
        visit [-->];
    }
}

with entry {
    nana = Person(name="Ruth", generation=1);
    papa = Person(name="Arthur", generation=1);
    morgan = Person(name="Morgan", generation=2);
    kid1 = Person(name="Iris", generation=3);
    kid2 = Person(name="Felix", generation=3);

    root ++> nana;
    nana +>: ParentOf() :+> morgan;
    papa +>: ParentOf() :+> morgan;
    morgan +>: ParentOf() :+> kid1;
    morgan +>: ParentOf() :+> kid2;

    root spawn Genealogist();
}
