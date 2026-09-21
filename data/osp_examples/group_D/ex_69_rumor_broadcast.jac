"""Rumor broadcast through a social network with a hop limit.

A rumor starts at one member and spreads only along Knows edges. Each
carrier walker marks its person as having heard it, then spawns fresh
carriers on uninformed friends with one fewer remaining hop, so the rumor
cannot travel further than the configured distance from its source.
"""

node Person {
    has name: str;
    has heard: bool = False;
}

edge Knows: Person --> Person {}

walker RumorCarrier {
    has hops_left: int;

    can spread with Person entry {
        if here.heard {
            skip;
        }
        here.heard = True;

        if self.hops_left <= 0 {
            skip;  # hop budget spent: this person hears it but passes nothing on
        }

        for friend in [->:Knows:->] {
            if not friend.heard {
                friend spawn RumorCarrier(hops_left=self.hops_left - 1);
            }
        }
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Person] {
        del stale_node;
    }
    people = [];
    names = ["Ana", "Ben", "Cy", "Dee", "Eli", "Fay", "Gus"];
    for nm in names {
        people.append(Person(name=nm));
    }
    ana = people[0];
    ben = people[1];
    cy = people[2];
    dee = people[3];
    eli = people[4];
    fay = people[5];
    gus = people[6];

    # Undirected friendships: an edge in each direction.
    ana <+: Knows() :+> ben;
    ana <+: Knows() :+> cy;
    ben <+: Knows() :+> dee;
    cy <+: Knows() :+> dee;
    dee <+: Knows() :+> eli;
    eli <+: Knows() :+> fay;
    fay <+: Knows() :+> gus;

    # The rumor breaks out at Ana and may travel at most 2 hops.
    ana spawn RumorCarrier(hops_left=2);

    reached = [];
    for p in people {
        if p.heard {
            reached.append(p.name);
        }
    }
    print(f"Heard the rumor ({len(reached)} of {len(people)} people): "
          + ", ".join(reached));
    missed = [];
    for p in people {
        if not p.heard {
            missed.append(p.name);
        }
    }
    if missed {
        print(f"Never heard it: {', '.join(missed)}");
    }
}
