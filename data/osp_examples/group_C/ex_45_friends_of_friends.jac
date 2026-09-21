"""Suggest collaborators two hops away in a research co-author graph.

A researcher wants "friends of friends": people reachable through
exactly two co-authored links. A single chained query expresses the
two-hop walk, and self plus direct co-authors are excluded.
"""

node Researcher {
    has name: str;
    has field: str;
}

edge CoAuthored {}

walker Scout {
    has reports: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can look with Researcher entry {
        # Two hops in one expression: co-authors of co-authors.
        # Dedup per reference means each person appears once even if
        # several parallel paths reach them.
        fofs = [here ->:CoAuthored:-> ->:CoAuthored:->];

        direct = [->:CoAuthored:->];
        for p in fofs {
            if p.name != here.name and p not in direct {
                self.reports.append(f"{here.field} researcher {here.name} could meet {p.name} ({p.field})");
            }
        }
        visit [-->];
    }

    can finish with Root exit {
        print("-- Collaboration suggestions --");
        for line in self.reports {
            print(line);
        }
    }
}

with entry {
    ana = Researcher(name="Ana", field="robotics");
    ben = Researcher(name="Ben", field="vision");
    cyd = Researcher(name="Cyd", field="planning");
    dee = Researcher(name="Dee", field="control");
    eli = Researcher(name="Eli", field="learning");

    ana +>: CoAuthored() :+> ben;
    ben +>: CoAuthored() :+> cyd;
    ben +>: CoAuthored() :+> dee;
    cyd +>: CoAuthored() :+> eli;

    root ++> ana ++> ben ++> cyd;
    root spawn Scout();
}
