"""Broadcast a restock order from several depots at once.

The dispatch hub keeps a list of depot nodes. Instead of walking from
each depot separately, the whole list is used as the query anchor:
one expression gathers every store reachable in one hop from any depot.
"""

node Depot {
    has name: str;
}

node Store {
    has name: str;
    has stock: int;
}

edge Serves {}

def low_stock(s: Store) -> bool {
    return s.stock < 20;
}

walker Dispatcher {
    can start with Root entry {
        depots = [-->][?:Depot];
        names = [d.name for d in depots];
        print(f"Anchoring from {len(depots)} depot(s): {names}");

        # A list of nodes anchors one combined query -- every depot's
        # neighbourhood composes into a single deduplicated result
        covered = [depots ->:Serves:->];
        print(f"Combined reach: {len(covered)} store visit slot(s)");

        needy = [s for s in covered if low_stock(s)];
        for s in needy {
            print(f"Restock needed at {s.name} (stock={s.stock})");
        }
        if not needy {
            print("All covered stores are fully stocked");
        }
    }
}

with entry {
    east = Depot(name="East Depot");
    west = Depot(name="West Depot");

    bakery = Store(name="Bakery Corner", stock=8);
    deli = Store(name="Deli Lane", stock=42);
    cafe = Store(name="Cafe Row", stock=15);

    east +>: Serves() :+> bakery;
    east +>: Serves() :+> deli;
    west +>: Serves() :+> deli;      # both depots cover Deli Lane
    west +>: Serves() :+> cafe;

    root ++> east;
    root ++> west;
    root spawn Dispatcher();
}
