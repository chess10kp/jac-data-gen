node User {
    has age: int = 0;
    has status: str = "";
    has verified: bool = False;
}
edge Friend { has since: int = 2020; }
edge Link { has weight: float = 0.0; }

walker Filter {
    can query with User entry {
        # Filter by node attributes (after traversal)
        adults = [-->][?age >= 18];
        active = [-->][?status == "active"];

        # Filter by edge attributes (during traversal)
        recent_friends = [->:Friend:since > 2020:->];
        strong_connections = [->:Link:weight > 0.8:->];

        # Surface the results so the walk actually produces output
        report {
            "adults": adults,
            "active": active,
            "recent_friends": recent_friends,
            "strong_connections": strong_connections
        };
    }
}
