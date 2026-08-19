node Person {
    has name: str;
}

edge Knows {
    has since: int;
}

def query_examples(src: Person, alice: Person) {
    # Basic queries
    [src -->];           # All forward connections
    [src <--];           # All backward connections
    [src <-->];          # Both directions

    # Type filtering
    [src -->][?:Person];           # Only Person nodes
    [src ->:Knows:->];             # Only via Knows edges
    [src ->:Knows:->][?:Person];   # Knows edges to Person nodes

    # Chained traversal
    [alice ->:Knows:-> ->:Knows:->];  # Friends of friends
}
