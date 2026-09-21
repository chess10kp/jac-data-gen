"""Trip planner that shortlists only top-rated attractions.

A city graph mixes Station, Hotel and Attraction nodes. From each
station the planner looks one hop out, keeps just attraction nodes,
and then narrows further to those rated 4 stars or higher.
"""

node Station {
    has name: str;
}

node Hotel {
    has name: str;
}

node Attraction {
    has name: str;
    has rating: float;
}

edge Walk {}

walker Planner {
    has itinerary: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can scan with Station entry {
        # One hop reaches hotels and attractions alike; keep attractions only
        sights = [->:Walk:->][?:Attraction];

        # Attribute filter: top-rated sights only
        best = [->:Walk:->][?rating >= 4.0];

        for a in best {
            self.itinerary.append(f"{a.name} ({a.rating} stars, reachable from {here.name})");
        }

        # The type filter alone sees everything attraction-shaped
        print(f"Near {here.name}: {len(sights)} attraction(s), {len(best)} top-rated");
        visit [-->];
    }

    can finish with Root exit {
        print("-- Itinerary --");
        for stop in self.itinerary {
            print(stop);
        }
    }
}

with entry {
    central = Station(name="Central");
    riverside = Station(name="Riverside");

    grand = Hotel(name="Grand Hotel");
    museum = Attraction(name="City Museum", rating=4.7);
    park = Attraction(name="Riverside Park", rating=3.9);
    tower = Attraction(name="Old Tower", rating=4.5);

    central +>: Walk() :+> grand;
    central +>: Walk() :+> museum;
    riverside +>: Walk() :+> park;
    riverside +>: Walk() :+> tower;

    root ++> central ++> riverside;
    root spawn Planner();
}
