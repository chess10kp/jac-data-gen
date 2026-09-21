"""Road network: edges that carry their own data.

Cities are nodes; roads are edges holding their length in km. A
courier walker travels by visiting the *edges* (not just the cities)
so each Road can add its toll to the courier's running cost.
"""

node City {
    has name: str = "";
}

edge Road {
    has km: float = 0.0;

    can charge_toll with Courier entry {
        visitor.cost += self.km * 0.25;
        print(f"Toll road segment: {self.km} km (+{self.km * 0.25:.2f})");
    }
}

walker Courier {
    has cost: float = 0.0;

    can start with Root entry {
        visit [-->];
    }

    can travel with City entry {
        print(f"Arrived in {here.name}, total cost so far: {self.cost:.2f}");
        visit [edge -->];
    }
}

with entry {
    springfield = City(name="Springfield");
    rivertown = City(name="Rivertown");
    hillcrest = City(name="Hillcrest");

    root ++> springfield;
    springfield +>: Road(km=40.0) :+> rivertown;
    rivertown +>: Road(km=25.5) :+> hillcrest;

    c = root spawn Courier();
    print(f"Final delivery cost: {c.cost:.2f}");
}
