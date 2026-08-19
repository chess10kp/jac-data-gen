node Person {}
edge EdgeType {}
edge Edge { has attr: int = 0; has a: int = 0; has b: int = 0; }
edge Friend {}

walker Traverser {
    can query with Person entry {
        outgoing = [-->];
        incoming = [<--];
        both = [<-->];
        via_type = [->:EdgeType:->];
        filtered = [->:Edge:attr > 0:->];
        people = [-->][?:Person];
        edges = [edge -->];
        friends = [edge ->:Friend:->];

        report {
            "outgoing": outgoing,
            "incoming": incoming,
            "both": both,
            "via_type": via_type,
            "filtered": filtered,
            "people": people,
            "edges": edges,
            "friends": friends
        };
    }
}
