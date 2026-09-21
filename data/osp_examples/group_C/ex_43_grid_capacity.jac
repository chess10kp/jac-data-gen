"""List transfers possible over high-capacity transmission lines.

The dispatcher's traversal predicate reads capacity_mw off the Line
edge itself, so weak links never become hops.
"""

node Substation {
    has name: str;
}

edge Line {
    has capacity_mw: int;
}

walker Dispatcher {
    has reports: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can survey with Substation entry {
        # Only transmission lines rated above 400 MW lead anywhere
        strong_links = [->:Line:capacity_mw > 400:->];

        for s in strong_links {
            self.reports.append(f"{here.name} can export to {s.name}");
        }
        print(f"{here.name}: {len(strong_links)} high-capacity link(s)");
        visit [-->];
    }

    can finish with Root exit {
        print("-- Scheduled transfers --");
        for line in self.reports {
            print(line);
        }
    }
}

with entry {
    coalridge = Substation(name="Coalridge");
    fairview = Substation(name="Fairview");
    harbor = Substation(name="Harbor");
    junction = Substation(name="Junction");
    milltown = Substation(name="Milltown");
    orchard = Substation(name="Orchard");

    coalridge +>: Line(capacity_mw=250) :+> fairview;   # below rating, skip
    coalridge +>: Line(capacity_mw=600) :+> harbor;
    harbor +>: Line(capacity_mw=450) :+> junction;
    milltown +>: Line(capacity_mw=500) :+> orchard;

    root ++> [coalridge, milltown];
    root spawn Dispatcher();
}
