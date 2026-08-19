node Person {
    has name: str;
}

edge Friend {}
edge Family {}

with entry {
    p1 = Person(name="John");
    p2 = Person(name="Susan");
    p3 = Person(name="Mike");
    root ++> p1;                      # Connect root to p1
    p1 +>: Friend :+> p2;             # Connect p1 to p2 with Friend edge
    p2 +>: Family :+> [p1, p3];       # Connect p2 to multiple nodes
}
