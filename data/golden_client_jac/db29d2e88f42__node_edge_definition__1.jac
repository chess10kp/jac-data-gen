node Person { has age: int = 0; }
edge Friend { has since: int = 2020; }
edge Colleague {}

walker Querier {
    can complex with Person entry {
        # Chained traversal (multi-hop)
        friends_of_friends = [here ->:Friend:-> ->:Friend:->];

        # Mixed edge types
        path = [here ->:Friend:-> ->:Colleague:->];

        # Combined with filters
        target = [->:Friend:since < 2020:->][?:Person, age > 30];
    }
}
