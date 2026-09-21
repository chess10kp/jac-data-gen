"""Report cheapest metro connections between stations.

Transit routes are typed edges with line colour and travel minutes.
Because Route declares Station endpoints, the query returns concrete
Station objects and typed Route edge objects directly -- no type
filters needed anywhere.
"""

node Station {
    has name: str;
}

edge Route: Station --> Station {
    has line: str;
    has minutes: int;
}

walker Commuter {
    has reports: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can scan with Station entry {
        # Typed edge objects: element type is Route, fields resolve statically
        routes = [edge ->:Route:->];

        best_minutes: int = -1;
        best_line: str = "";
        for r in routes {
            if best_minutes == -1 or r.minutes < best_minutes {
                best_minutes = r.minutes;
                best_line = r.line;
            }
        }

        # Destinations come back as Station, not any
        stops = [->:Route:->];
        for i in range(len(stops)) {
            self.reports.append(
                f"{here.name} -> {stops[i].name} via {routes[i].line} ({routes[i].minutes} min)"
            );
        }
        if best_line {
            print(f"Fastest from {here.name}: {best_line} line, {best_minutes} min");
        } else {
            # A station fed by several lines gets here once per in-edge:
            # separate visit steps may enqueue the same node twice
            print(f"{here.name} is a terminus");
        }
        visit [-->];
    }

    can finish with Root exit {
        print("-- Connection board --");
        for line in self.reports {
            print(line);
        }
    }
}

with entry {
    kings = Station(name="Kings Cross");
    embankment = Station(name="Embankment");
    bank = Station(name="Bank");

    kings +>: Route(line="Piccadilly", minutes=9) :+> embankment;
    kings +>: Route(line="Northern", minutes=14) :+> bank;
    embankment +>: Route(line="Circle", minutes=6) :+> bank;

    root ++> kings ++> embankment;
    root spawn Commuter();
}
