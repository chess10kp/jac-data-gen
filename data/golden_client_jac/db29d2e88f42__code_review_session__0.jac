node Person { has age: int = 0; }
edge Friend { has since: int = 2020; }
edge Colleague {}

walker Querier {
    can complex with Person entry {
        # Chained traversal (multi-hop) — comprehension starts from `here` implicitly
        friends_of_friends = [->:Friend:-> ->:Friend:->];

        # Mixed edge types
        path = [->:Friend:-> ->:Colleague:->];

        # Combined with filters
        target = [->:Friend:since < 2020:->][?:Person, age > 30];

        report {
            "friends_of_friends": friends_of_friends,
            "path": path,
            "target": target
        };
    }
}
