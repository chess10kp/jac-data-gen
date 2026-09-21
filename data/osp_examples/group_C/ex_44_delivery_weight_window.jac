"""Pick delivery trucks whose cargo weight falls inside a legal window.

Each Hauls edge records the cargo weight it carries. A truck is
dispatchable only when its load is between 2 and 8 tonnes inclusive,
so the route checker applies both bounds as predicates on one hop.
"""

node Depot {
    has name: str;
}

node Store {
    has name: str;
}

edge Hauls {
    has tonnes: float;
}

walker Dispatcher {
    has dispatches: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can check with Depot entry {
        # Both predicates AND together on the same hop:
        # heavy enough to be worth the trip, light enough to be legal
        dispatchable = [->:Hauls:tonnes >= 2.0, tonnes <= 8.0:->];

        all_runs = [->:Hauls:->];
        for s in dispatchable {
            self.dispatches.append(f"{here.name} -> {s.name}");
        }
        print(f"{here.name}: {len(all_runs)} run(s) total, {len(dispatchable)} within the 2-8 t window");
        visit [-->];
    }

    can finish with Root exit {
        print("-- Dispatch list --");
        for d in self.dispatches {
            print(d);
        }
    }
}

with entry {
    north = Depot(name="North Depot");
    south = Depot(name="South Depot");

    market = Store(name="Market St");
    harbour = Store(name="Harbour Point");
    airport = Store(name="Airport Hub");

    north +>: Hauls(tonnes=1.2) :+> market;     # too light
    north +>: Hauls(tonnes=6.5) :+> harbour;    # in window
    south +>: Hauls(tonnes=3.0) :+> airport;    # in window
    south +>: Hauls(tonnes=11.0) :+> market;    # overweight

    root ++> north ++> south;
    root spawn Dispatcher();
}
