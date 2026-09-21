"""Greedy cheapest-next-hop delivery routing.

A courier starts at a depot and must reach a destination city. At every
city it inspects the outgoing Route edges with their costs, greedily picks
the cheapest leg to an unvisited city, and continues until it arrives or
runs out of options -- a classic greedy strategy that is fast but not
guaranteed optimal.
"""

node City {
    has name: str;
}

edge Route: City --> City {
    has cost: float;
}

walker GreedyCourier {
    has dest: str;
    has total_cost: float = 0.0;
    has route: list[str] = [];
    has visited: dict = {};

    can travel with City entry {
        self.route.append(here.name);
        self.visited[here.name] = True;

        if here.name == self.dest {
            path = " -> ".join(self.route);
            print(f"Delivery route: {path}");
            print(f"Total cost: {round(self.total_cost, 2)}");
            disengage;
        }

        stops = [->:Route:->];
        legs = [edge ->:Route:->];

        # Pick the cheapest unvisited next hop.
        best_i = -1;
        for i in range(len(stops)) {
            if stops[i].name in self.visited {
                continue;
            }
            if best_i == -1 or legs[i].cost < legs[best_i].cost {
                best_i = i;
            }
        }

        if best_i == -1 {
            print(f"Dead end at {here.name} -- destination not reached.");
            disengage;
        }

        self.total_cost += legs[best_i].cost;
        next_stop = stops[best_i];
        visit next_stop;
    }
}

with entry {
    for stale in [root -->][?:City] {
        del stale;
    }

    depot = City(name="Depot");
    hub = City(name="Hub");
    port = City(name="Port");
    mine = City(name="Mine");
    farm = City(name="Farm");

    # Directed legs with tolls. The greedy choice from Depot is Farm,
    # which turns out to be a scenic detour rather than the cheapest path.
    depot +>: Route(cost=4.5) :+> farm;
    depot +>: Route(cost=9.0) :+> hub;
    farm +>: Route(cost=3.0) :+> mine;
    mine +>: Route(cost=2.5) :+> hub;
    hub +>: Route(cost=2.0) :+> port;
    farm +>: Route(cost=8.5) :+> port;

    depot spawn GreedyCourier(dest="Port");

    # For comparison: the true cheapest path Depot->Hub->Port is 11.0,
    # while greedily hopping via Farm and Mine costs more overall.
}
