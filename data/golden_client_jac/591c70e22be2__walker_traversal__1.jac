"""Walker that traverses a graph and collects data."""

node City {
    has name: str,
        population: int = 0;
}

edge Road {
    has distance: float = 0.0;
}

walker Explorer {
    has visited: list[str] = [];

    can visit_city with City entry {
        self.visited.append(here.name);
        print(f"Visiting {here.name} (pop: {here.population})");
        visit [-->];
    }
}

with entry {
    nyc = City(name="New York", population=8_300_000);
    la = City(name="Los Angeles", population=3_900_000);
    chi = City(name="Chicago", population=2_700_000);

    root ++> nyc;
    nyc +>:Road(distance=790.0):+> chi;
    chi +>:Road(distance=2015.0):+> la;

    explorer = root spawn Explorer();
}
