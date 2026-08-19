edge Road {
    has distance: float;

    can on_traverse with Traveler entry {
        visitor.total_distance += self.distance;
    }
}
