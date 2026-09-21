"""Trace every pipeline route from an intake valve, tolerating dead ends.

The visit statement's else clause logs a dead end gracefully instead
of failing silently, and finishes the walk when it truly runs dry.
"""

node Valve {
    has name: str;
    has pressure: float;
}

edge Pipe {
    has capacity: int;
}

walker Tracer {
    has route: list[str] = [];
    has dead_ends: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can `flow with Valve entry {
        self.route.append(here.name);
        print(f"pressure {here.pressure} bar at valve {here.name}");

        # No outgoing pipes? Log it and carry on with whatever is queued
        visit [->:Pipe:->] else {
            print(f"  dead end at {here.name}");
            self.dead_ends += 1;
        }
    }

    can finish with Root exit {
        print("-- Trace summary --");
        print("Route: " + " -> ".join(self.route));
        print(f"Dead ends hit: {self.dead_ends}");
    }
}

with entry {
    intake = Valve(name="Intake", pressure=4.2);
    splitter = Valve(name="Splitter", pressure=3.1);
    filter_a = Valve(name="FilterA", pressure=2.0);
    cap = Valve(name="Cap", pressure=1.1);

    root ++> intake;
    intake +>: Pipe(capacity=100) :+> splitter;
    splitter +>: Pipe(capacity=40) :+> filter_a;
    filter_a +>: Pipe(capacity=10) :+> cap;

    root spawn Tracer();
}
