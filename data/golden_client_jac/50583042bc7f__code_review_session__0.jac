node Place { has name: str; }
edge Road { has distance: float = 0.0; }

walker Traveler {
    has total_distance: float = 0.0;

    can start with Root entry {
        visit [->:Road:->];
    }

    can move with Place entry {
        # Accumulate the arriving edge's distance HERE, in the node ability,
        # because edge entry abilities do not fire during traversal (yet).
        for e in [edge <-:Road:<-] {
            self.total_distance += e.distance;
        }
        visit [->:Road:->];
    }
}

with entry {
    a = Place(name="A");
    b = Place(name="B");
    root +>:Road(distance=3.0):+> a +>:Road(distance=4.0):+> b;
    result = root spawn Traveler();
    print(f"Total distance: {result.total_distance}");
}
