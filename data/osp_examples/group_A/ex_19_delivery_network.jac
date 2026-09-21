"""Package delivery network: capstone combining core OSP features.

Hubs are typed nodes, Route edges carry transit hours plus a
frozen-cargo policy, dispatch runs are parameterized at spawn time,
the router disengages once delivered (or when no legal road exists),
and the depot reads each run's reports back after spawning.
"""

node Hub {
    has city: str = "";
    has is_depot: bool = False;
}

edge Route {
    has hours: float = 1.0;
    has allows_frozen: bool = True;
}

walker Dispatch {
    has destination: str = "";
    has carries_frozen: bool = False;
    has hops: list[str] = [];
    has reports: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can route with Hub entry {
        if here.is_depot {
            print(f"Dispatch rolling toward {self.destination}");
            visit [-->];
            return;
        }
        self.hops.append(here.city);
        if here.city == self.destination {
            report f"Delivered to {here.city} via {' -> '.join(self.hops)}";
            disengage;
        }
        if self.carries_frozen {
            # Frozen cargo may only ride routes that allow it.
            visit [->:Route:allows_frozen == True:->] else {
                report f"Cold chain broken: no frozen-safe route past {here.city}";
                disengage;
            }
        } else {
            # Depth-first: follow this road all the way before trying others.
            visit : 0 : [-->] else {
                report f"Dead end at {here.city}, cannot reach {self.destination}";
                disengage;
            }
        }
    }
}

with entry {
    depot = Hub(city="Depot North", is_depot=True);
    mid1 = Hub(city="Fairview");
    mid2 = Hub(city="Granite Falls");
    end1 = Hub(city="Cedar Bay");
    end2 = Hub(city="Summit Ridge");

    # One chained statement builds the whole network.
    root ++> depot;
    depot +>: Route(hours=4.0) :+> mid1 +>: Route(hours=6.5, allows_frozen=False) :+> end1;
    mid2 = depot +>: Route(hours=3.5) :+> mid2;
    mid2 +>: Route(hours=5.0) :+> end2;

    run1 = root spawn Dispatch(destination="Cedar Bay", carries_frozen=False);
    run2 = root spawn Dispatch(destination="Summit Ridge", carries_frozen=True);

    print("Standard shipment:");
    for r in run1.reports {
        print(f"  {r}");
    }
    print("Frozen shipment:");
    for r in run2.reports {
        print(f"  {r}");
    }
}
