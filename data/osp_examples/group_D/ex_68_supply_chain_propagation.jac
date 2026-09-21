"""Warehouse supply-chain demand propagation.

The network flows upstream through Supplies edges (factory -> depot ->
store) whose capacity splits how demand is shared. Demand packets are
spawned as walkers at retail stores; each facility adds its received
quantity to its backlog, then forwards the demand upstream, splitting it
across supplier lanes proportionally to lane capacity.
"""

node Facility {
    has name: str;
    has kind: str;      # "factory" | "depot" | "store"
    has backlog: int = 0;
}

edge Supplies: Facility --> Facility {
    has capacity: int;
}

walker DemandPacket {
    has qty: int;

    can `flow with Facility entry {
        here.backlog += self.qty;

        # Demand flows against the Supplies direction: upstream
        # suppliers are the sources of this facility's incoming lanes.
        suppliers = [<-:Supplies:<-];
        lanes = [edge <-:Supplies:<-];
        if len(suppliers) == 0 {
            skip;  # reached a source (factory): demand stops here
        }

        total_capacity = 0;
        for lane in lanes {
            total_capacity += lane.capacity;
        }

        for i in range(len(suppliers)) {
            lane = lanes[i];
            share = int(self.qty * lane.capacity / total_capacity);
            if share > 0 {
                upstream = suppliers[i];
                upstream spawn DemandPacket(qty=share);
            }
        }
    }
}

with entry {

    # Reset leftovers from any previous run of this demo.
    for stale_node in [root -->][?:Facility] {
        del stale_node;
    }
    factory_north = Facility(name="Factory North", kind="factory");
    factory_south = Facility(name="Factory South", kind="factory");
    depot_east = Facility(name="Depot East", kind="depot");
    depot_west = Facility(name="Depot West", kind="depot");
    store_a = Facility(name="Store A", kind="store");
    store_b = Facility(name="Store B", kind="store");

    # Big lane north (3x), small lane south; two lanes into Depot East.
    factory_north +>: Supplies(capacity=300) :+> depot_west;
    factory_south +>: Supplies(capacity=100) :+> depot_west;
    factory_north +>: Supplies(capacity=200) :+> depot_east;
    factory_south +>: Supplies(capacity=200) :+> depot_east;
    depot_west +>: Supplies(capacity=150) :+> store_a;
    depot_east +>: Supplies(capacity=150) :+> store_a;
    depot_east +>: Supplies(capacity=400) :+> store_b;

    # Weekend orders placed at the retail stores.
    store_a spawn DemandPacket(qty=90);
    store_b spawn DemandPacket(qty=120);

    network = [
        factory_north,
        factory_south,
        depot_east,
        depot_west,
        store_a,
        store_b,
    ];
    print("Backlog per facility after propagation:");
    for site in network {
        label = site.name;
        load = site.backlog;
        print(f"  {site.kind:<8} {label:<14} {load:>4} units");
    }
}
