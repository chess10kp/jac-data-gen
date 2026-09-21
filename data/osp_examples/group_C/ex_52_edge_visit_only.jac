"""Audit current draw on power grid lines two different ways.

Grid lines meter electricity in a `can` ability on the Line edge. An
inspector walks the grid once with plain node visits -- the meters
stay silent because node visits cross edges without waking them -- and
then once more visiting the edges themselves, which trips every meter
before continuing to the next substation.
"""

node Substation {
    has name: str;
}

edge Line {
    has amps: float;

    can meter with Inspector entry {
        visitor.metered += 1;
        print(f"  meter on a {self.amps} A line: recording {self.amps} A");
    }
}

walker Inspector {
    has mode: str;
    has metered: int = 0;

    can start with Root entry {
        print(f"-- Pass: {self.mode} --");
        visit [-->];
    }

    can inspect with Substation entry {
        print(f"At {here.name}");
        if self.mode == "edges" {
            # Visiting edges wakes their abilities, then auto-continues
            visit [edge -->];
        } else {
            # Plain node visit crosses lines silently
            visit [-->];
        }
    }

    can done with Root exit {
        print(f"{self.mode} pass tripped {self.metered} meter(s)");
    }
}

with entry {
    plant = Substation(name="Plant");
    junction = Substation(name="Junction");
    town_a = Substation(name="TownA");
    town_b = Substation(name="TownB");

    root ++> plant;
    plant +>: Line(amps=41.0) :+> junction;
    junction +>: Line(amps=17.5) :+> town_a;
    junction +>: Line(amps=23.5) :+> town_b;

    quiet = Inspector(mode="nodes-only");
    root spawn quiet;

    loud = Inspector(mode="edges");
    root spawn loud;
}
