"""Drive a delivery van across toll roads and total up the cost.

Each Road edge charges a toll. The van visits the edges themselves, so
every Road's ability fires as the van crosses it -- the toll is added
to the running total right on the link. After an edge finishes its
abilities the van automatically continues to the far town.
"""

node Town {
    has name: str;
}

edge Road {
    has km: float;
    has toll: float;

    can charge with Van entry {
        visitor.total_toll += self.toll;
        print(f"  crossing {self.km} km road, paying ${self.toll} (total so far: ${visitor.total_toll})");
    }
}

walker Van {
    has total_toll: float = 0.0;

    can start with Root entry {
        print("Loading van at depot");
        visit [-->];
    }

    can drive with Town entry {
        if here.name == "Depot" {
            visit [edge -->];
            return;
        }
        print(f"Arrived in {here.name}, tolls paid: ${self.total_toll}");

        # Itinerary includes the EDGES: each Road's ability fires,
        # then traversal continues to the target automatically
        visit [edge -->];
    }
}

with entry {
    depot = Town(name="Depot");
    midvale = Town(name="Midvale");
    oakford = Town(name="Oakford");
    seaside = Town(name="Seaside");

    root ++> depot;
    depot +>: Road(km=12.0, toll=3.5) :+> midvale;
    midvale +>: Road(km=8.5, toll=2.0) :+> oakford;
    oakford +>: Road(km=20.0, toll=6.75) :+> seaside;

    van = Van();
    root spawn van;
    print(f"Final toll bill for the run: ${van.total_toll}");
}
